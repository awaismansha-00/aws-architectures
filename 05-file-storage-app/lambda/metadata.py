import json, os
import boto3
from urllib.parse import unquote_plus
table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
def lambda_handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            for item in body.get("Records", []):
                obj = item["s3"]["object"]
                table.put_item(Item={"file_id": unquote_plus(obj["key"]), "status": "Available", "size_bytes": obj["size"]})
        except Exception: failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
