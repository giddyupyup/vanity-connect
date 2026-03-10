import { randomUUID } from "node:crypto";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { generateVanityNumbers } from "./vanity.js";

interface ConnectEvent {
  Details?: {
    ContactData?: {
      ContactId?: string;
      CustomerEndpoint?: {
        Address?: string;
      };
    };
    Parameters?: Record<string, string>;
  };
}

const dynamodb = new DynamoDBClient({});

function getCallerNumber(event: ConnectEvent): string {
  return (
    event.Details?.ContactData?.CustomerEndpoint?.Address ??
    event.Details?.Parameters?.callerNumber ??
    ""
  );
}

export const main = async (event: ConnectEvent) => {
  console.info("connect-contact invoked", {
    contactId: event.Details?.ContactData?.ContactId ?? null
  });

  const tableName = process.env.TABLE_NAME;
  if (!tableName) {
    throw new Error("TABLE_NAME is required");
  }

  const callerNumber = getCallerNumber(event);
  const vanityTop5 = generateVanityNumbers(callerNumber, 5);
  const vanityTop3 = vanityTop5.slice(0, 3);
  const topOne = vanityTop3[0] ?? "No option";
  const topTwo = vanityTop3[1] ?? "No option";
  const topThree = vanityTop3[2] ?? "No option";
  const now = new Date().toISOString();

  await dynamodb.send(
    new PutItemCommand({
      TableName: tableName,
      Item: {
        pk: { S: "CALLS" },
        sk: {
          S: `${now}#${event.Details?.ContactData?.ContactId ?? randomUUID()}`
        },
        caller_number: { S: callerNumber },
        called_at: { S: now },
        vanity_top5: { L: vanityTop5.map((value) => ({ S: value })) }
      }
    })
  );

  console.info("connect-contact generated vanity options", {
    callerNumber,
    topOne,
    topTwo,
    topThree
  });

  return {
    callerNumber,
    vanityTop3,
    vanityTop5,
    topOne,
    topTwo,
    topThree,
    spokenText: [topOne, topTwo, topThree].join(", ")
  };
};
