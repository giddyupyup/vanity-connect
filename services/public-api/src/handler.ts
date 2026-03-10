import { DynamoDBClient, QueryCommand } from "@aws-sdk/client-dynamodb";

const dynamodb = new DynamoDBClient({});

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,OPTIONS",
  "access-control-allow-headers": "content-type"
};

interface VanityCall {
  callerNumber: string;
  calledAt: string;
  vanityTop5: string[];
}

function parseVanityCall(item: Record<string, any>): VanityCall {
  return {
    callerNumber: item.caller_number?.S ?? "",
    calledAt: item.called_at?.S ?? "",
    vanityTop5: (item.vanity_top5?.L ?? []).map((entry: any) => entry.S).filter(Boolean)
  };
}

export const main = async () => {
  try {
    const tableName = process.env.TABLE_NAME;
    if (!tableName) {
      return {
        statusCode: 500,
        headers: {
          ...CORS_HEADERS,
          "content-type": "application/json"
        },
        body: JSON.stringify({ error: "TABLE_NAME is required" })
      };
    }

    const response = await dynamodb.send(
      new QueryCommand({
        TableName: tableName,
        KeyConditionExpression: "pk = :pk",
        ExpressionAttributeValues: {
          ":pk": { S: "CALLS" }
        },
        ScanIndexForward: false,
        Limit: 5
      })
    );

    const lastFive = (response.Items ?? []).map((item) => parseVanityCall(item));

    return {
      statusCode: 200,
      headers: {
        ...CORS_HEADERS,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        callers: lastFive
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        ...CORS_HEADERS,
        "content-type": "application/json"
      },
      body: JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      })
    };
  }
};
