import json, os
import boto3
table = boto3.resource("dynamodb").Table(os.environ["HISTORY_TABLE"])
def lambda_handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            payload = json.loads(record["body"])
            table.put_item(Item={"messageId": payload["messageId"], "timestamp": payload["timestamp"], "username": payload["username"], "message": payload["content"]})
        except Exception:
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
