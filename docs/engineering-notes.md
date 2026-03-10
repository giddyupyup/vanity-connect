# Engineering Notes

This document answers the required write-up points for the assignment.

## 1) Why this implementation, struggles, and problems overcome

### Why this implementation

- Split responsibilities by layer:
  - TypeScript for business logic (`services/*`)
  - Terraform for cloud resources (`infra/*`)
- Used per-service `configuration.yml` so trigger type (`aws-connect` vs `api-gw`) is declarative and easy to extend.
- Kept one shared DynamoDB access pattern (`pk=CALLS`) to make "latest 5 callers" a single reverse query.
- Chose DynamoDB keys as:
  - `pk=CALLS` so all call records are in one partition for a single `Query` access pattern.
  - `sk=<timestamp>#<contactId>` so records are naturally time-ordered and can be read newest-first with `ScanIndexForward=false`.
- Added bonus web UI with runtime configuration (`runtime-config.json`) so API endpoints can change per environment without rebuilding frontend code.

### Struggles and problems overcome

- Amazon Connect flow JSON validation was stricter than expected.
  - Problem: `InvalidContactFlowException` on create/update.
  - Fix: iterated toward a schema that Connect accepts in this environment and retained UI-edit fallback when needed.
- API Gateway to Lambda looked configured but Lambda was never invoked.
  - Problem: wrong ARN format used for permission scope.
  - Fix: used `shared_api_gateway_execution_arn` (`arn:aws:execute-api:...`) for `aws_lambda_permission`.
- Lambda runtime failed with ESM/CJS mismatch.
  - Problem: `Cannot use import statement outside a module`.
  - Fix: switched service TypeScript builds to CommonJS output so zip artifacts execute with current packaging layout.
- Connect flow always took error branch without Lambda logs.
  - Problem: response validation mismatch in flow vs Lambda return payload.
  - Fix: aligned flow invocation settings (synchronous invocation + JSON-compatible response validation) and verified end-to-end behavior.

## 2) Shortcuts taken that are not production-ready

- Vanity number ranking uses a small embedded dictionary and simple heuristics.
- Tests are mostly unit-level; no full integration or load tests.
- Contact flow design still depends on Connect UI verification in real environments.
- No CI/CD pipeline or policy-as-code guardrails yet.
- Credentials were temporarily passed via tfvars during development; production should use IAM roles/profiles/secrets management only.

## 3) What I would do with more time

- Add integration tests that exercise Connect -> Lambda -> DynamoDB and API Gateway -> Lambda -> DynamoDB.
- Add automated deployment pipeline (build, test, terraform plan/apply gates, and smoke tests).
- Add synthetic checks and dashboards for call flow success rate, Lambda errors, and API latency.
- Improve web app UX with explicit error states, retries, and observability hooks.
- Create environment promotion strategy (dev/stage/prod) with isolated state backends and approvals.

## 4) Considerations for high traffic and security hardening

- Security and abuse protection:
  - AWS WAF + throttling/rate-limits for public endpoints
  - stricter IAM least privilege and explicit deny boundaries
  - secrets/key rotation and no static credentials in repo-managed files
- Reliability and scaling:
  - Lambda reserved concurrency and timeout tuning
  - DynamoDB access pattern review, GSIs if needed, and adaptive capacity monitoring
  - DLQs, retries, alarms, and runbooks for operational incidents
- Data protection and compliance:
  - phone-number PII handling policy (retention/redaction/access controls)
  - encryption and audit trails
- Operational maturity:
  - distributed tracing, correlation IDs, and structured logs
  - SLOs/SLIs and alerting thresholds tied to business impact

## 5) Architecture diagram

See [architecture.md](/Users/giddyupyup/Documents/vanity-connect/docs/architecture.md).
