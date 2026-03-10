locals {
  services_root = abspath(var.services_root)
  selected_service_names = distinct([
    for name in var.service_names :
    trimspace(name)
    if length(trimspace(name)) > 0
  ])
  selected_service_config_files = [
    for service_name in local.selected_service_names :
    "${service_name}/configuration.yml"
  ]

  service_configs = {
    for rel in local.selected_service_config_files :
    dirname(rel) => yamldecode(file("${local.services_root}/${rel}"))
  }

  resolved_service_configs = {
    for key, cfg in local.service_configs :
    key => merge(
      cfg,
      {
        service = merge(
          cfg.service,
          {
            environment = merge(
              {
                for env_key, env_value in try(cfg.service.environment, {}) :
                env_key => replace(
                  replace(env_value, "$${DYNAMODB_TABLE_NAME}", coalesce(var.dynamodb_table_name, "")),
                  "$${DYNAMODB_TABLE_ARN}",
                  coalesce(var.dynamodb_table_arn, "")
                )
              },
              var.dynamodb_table_name != null ? { TABLE_NAME = var.dynamodb_table_name } : {}
            )
            role = merge(
              try(cfg.service.role, {}),
              {
                statements = [
                  for statement in try(cfg.service.role.statements, []) :
                  merge(
                    statement,
                    {
                      resources = [
                        for resource in try(statement.resources, []) :
                        replace(
                          replace(resource, "$${DYNAMODB_TABLE_NAME}", coalesce(var.dynamodb_table_name, "")),
                          "$${DYNAMODB_TABLE_ARN}",
                          coalesce(var.dynamodb_table_arn, "")
                        )
                      ]
                    }
                  )
                ]
              }
            )
          }
        )
        trigger = try(cfg.trigger.type, null) == "aws-connect" ? merge(
          cfg.trigger,
          {
            instance_id  = var.connect_instance_id
            instance_arn = var.connect_instance_arn
          }
          ) : (
          try(cfg.trigger.type, null) == "api-gw" ? merge(
            cfg.trigger,
            {
              api_id            = var.shared_api_gateway_id
              api_execution_arn = var.shared_api_gateway_execution_arn
              api_endpoint      = var.shared_api_gateway_endpoint
            }
          ) : cfg.trigger
        )
      }
    )
  }

  connect_service_selected = contains(keys(local.resolved_service_configs), var.connect_service_key)
  connect_service_is_connect_trigger = local.connect_service_selected && try(
    local.resolved_service_configs[var.connect_service_key].trigger.type,
    null
  ) == "aws-connect"
  create_connect_contact_flow = local.connect_service_is_connect_trigger && var.connect_instance_id != null
  rendered_contact_flow = local.create_connect_contact_flow ? (
    var.contact_flow_content != null ? var.contact_flow_content : templatefile("${path.module}/templates/contact-flow.json.tftpl", {
      lambda_arn = module.service[var.connect_service_key].lambda_function_arn
    })
  ) : null
}

module "service" {
  for_each = local.resolved_service_configs

  source       = "../../modules/lambda-service"
  config       = each.value
  service_root = "${local.services_root}/${each.key}"
}

resource "aws_connect_contact_flow" "service_flow" {
  count = local.create_connect_contact_flow ? 1 : 0

  instance_id = var.connect_instance_id
  name        = var.contact_flow_name
  type        = var.contact_flow_type
  description = "Reads caller number, invokes vanity Lambda, and plays results"
  content     = local.rendered_contact_flow
}
