import hmac, os
def lambda_handler(event, context):
    supplied = (event.get("queryStringParameters") or {}).get("token", "")
    effect = "Allow" if hmac.compare_digest(supplied, os.environ["CONNECTION_TOKEN"]) else "Deny"
    return {"principalId": "chat-client", "policyDocument": {"Version": "2012-10-17", "Statement": [{"Action": "execute-api:Invoke", "Effect": effect, "Resource": event["methodArn"]}]}}
