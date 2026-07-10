import os
import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

def lambda_handler(event, context):
    short_id = (event.get("pathParameters") or {}).get("id")
    if not short_id:
        return {"statusCode": 400, "body": "Missing ID"}
    item = table.get_item(Key={"short_id": short_id}, ConsistentRead=True).get("Item")
    if not item:
        return {"statusCode": 404, "body": "Not Found"}
    return {"statusCode": 302, "headers": {"Location": item["long_url"], "Cache-Control": "no-store"}, "body": ""}

