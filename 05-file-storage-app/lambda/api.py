import json, os
from decimal import Decimal
from urllib.parse import unquote_plus
import boto3
s3 = boto3.client("s3"); table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"]); bucket = os.environ["BUCKET"]
def encode(value): return int(value) if isinstance(value, Decimal) and value % 1 == 0 else str(value)
def reply(status, body): return {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": json.dumps(body, default=encode)}
def lambda_handler(event, context):
    path, query = event.get("resource", ""), event.get("queryStringParameters") or {}
    name = unquote_plus(query.get("filename", "")).lstrip("/")
    if path in ("/upload-url", "/download-url", "/delete-file") and not name: return reply(400, {"error": "filename required"})
    if path == "/upload-url": return reply(200, {"key": name, "upload_url": s3.generate_presigned_url("put_object", Params={"Bucket": bucket, "Key": name}, ExpiresIn=900)})
    if path == "/download-url": return reply(200, {"download_url": s3.generate_presigned_url("get_object", Params={"Bucket": bucket, "Key": name}, ExpiresIn=900)})
    if path == "/delete-file": s3.delete_object(Bucket=bucket, Key=name); table.delete_item(Key={"file_id": name}); return reply(200, {"status": "deleted"})
    if path == "/files":
        items, scan = [], table.scan()
        while True:
            items += scan.get("Items", [])
            if "LastEvaluatedKey" not in scan: break
            scan = table.scan(ExclusiveStartKey=scan["LastEvaluatedKey"])
        return reply(200, items)
    return reply(404, {"error": "not found"})
