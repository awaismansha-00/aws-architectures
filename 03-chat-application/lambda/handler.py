import json, os, time
import boto3
from botocore.exceptions import ClientError
table = boto3.resource("dynamodb").Table(os.environ["ACTIVE_TABLE"])
sqs = boto3.client("sqs")
def client(ctx): return boto3.client("apigatewaymanagementapi", endpoint_url=f"https://{ctx['domainName']}/{ctx['stage']}")
def broadcast(api, username, message):
    data = json.dumps({"username": username, "message": message}).encode()
    scan = table.scan(ProjectionExpression="connectionId")
    while True:
        for item in scan.get("Items", []):
            try: api.post_to_connection(ConnectionId=item["connectionId"], Data=data)
            except ClientError as exc:
                if exc.response["ResponseMetadata"]["HTTPStatusCode"] == 410: table.delete_item(Key={"connectionId": item["connectionId"]})
                else: raise
        if "LastEvaluatedKey" not in scan: break
        scan = table.scan(ProjectionExpression="connectionId", ExclusiveStartKey=scan["LastEvaluatedKey"])
def lambda_handler(event, context):
    ctx, route = event["requestContext"], event["requestContext"]["routeKey"]
    cid, api = ctx["connectionId"], client(ctx)
    if route == "$connect": table.put_item(Item={"connectionId": cid, "username": "Anonymous"}); return {"statusCode": 200}
    if route == "$disconnect": table.delete_item(Key={"connectionId": cid}); return {"statusCode": 200}
    try: body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError: return {"statusCode": 400, "body": "Invalid JSON"}
    if route == "setName":
        name = str(body.get("name", "")).strip()[:50]
        if not name: return {"statusCode": 400, "body": "Name required"}
        table.update_item(Key={"connectionId": cid}, UpdateExpression="SET username=:u", ExpressionAttributeValues={":u": name}); broadcast(api, "System", f"{name} joined")
    elif route == "sendMessage":
        msg = str(body.get("message", "")).strip()[:1000]
        if not msg: return {"statusCode": 400, "body": "Message required"}
        user = table.get_item(Key={"connectionId": cid}).get("Item", {}).get("username", "Anonymous")
        broadcast(api, user, msg); sqs.send_message(QueueUrl=os.environ["SQS_QUEUE_URL"], MessageBody=json.dumps({"messageId": ctx["requestId"], "timestamp": int(time.time()), "username": user, "content": msg}))
    return {"statusCode": 200}
