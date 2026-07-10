import json, os
from urllib.parse import unquote_plus
from urllib.request import Request, urlopen
import boto3
s3=boto3.client("s3"); bucket=os.environ["S3_BUCKET"]
def lambda_handler(event,context):
    for record in event["Records"]:
        key=unquote_plus(record["s3"]["object"]["key"]); head=s3.head_object(Bucket=bucket,Key=key)
        payload=json.dumps({"objectKey":key,"fileSize":head.get("ContentLength",0),"mediaType":head.get("ContentType","application/octet-stream")}).encode()
        request=Request(f"http://{os.environ['ALB_DNS']}/api/webhook",data=payload,headers={"Content-Type":"application/json"},method="POST")
        with urlopen(request,timeout=10) as response:
            if response.status >= 400: raise RuntimeError(f"webhook returned {response.status}")
    return {"statusCode":200}
