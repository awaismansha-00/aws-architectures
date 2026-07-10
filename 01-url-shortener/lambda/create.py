import json, os, secrets, string
import boto3
from botocore.exceptions import ClientError

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
alphabet = string.ascii_letters + string.digits

def response(status, body):
    return {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": json.dumps(body)}

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        long_url = body.get("url", "").strip()
        custom_id = body.get("custom_id")
        if not long_url.startswith(("http://", "https://")):
            return response(400, {"error": "url must start with http:// or https://"})
        if custom_id and (len(custom_id) > 64 or not custom_id.replace("-", "").replace("_", "").isalnum()):
            return response(400, {"error": "custom_id contains invalid characters"})
        attempts = 1 if custom_id else 5
        for _ in range(attempts):
            short_id = custom_id or "".join(secrets.choice(alphabet) for _ in range(6))
            try:
                table.put_item(Item={"short_id": short_id, "long_url": long_url}, ConditionExpression="attribute_not_exists(short_id)")
                return response(201, {"short_id": short_id, "original_url": long_url})
            except ClientError as exc:
                if exc.response["Error"]["Code"] != "ConditionalCheckFailedException": raise
        return response(409 if custom_id else 503, {"error": "short ID is unavailable"})
    except (json.JSONDecodeError, TypeError):
        return response(400, {"error": "invalid JSON body"})
    except Exception:
        return response(500, {"error": "internal error"})

