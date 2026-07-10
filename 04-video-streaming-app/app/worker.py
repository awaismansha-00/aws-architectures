import json, os, shutil, subprocess, tempfile
from urllib.parse import unquote_plus
import boto3
REGION=os.environ["AWS_REGION"]; INPUT=os.environ["INPUT_BUCKET"]; OUTPUT=os.environ["OUTPUT_BUCKET"]; QUEUE=os.environ["QUEUE_URL"]
s3=boto3.client("s3",region_name=REGION); sqs=boto3.client("sqs",region_name=REGION); table=boto3.resource("dynamodb",region_name=REGION).Table(os.environ["TABLE_NAME"])
while True:
    response=sqs.receive_message(QueueUrl=QUEUE,WaitTimeSeconds=20,MaxNumberOfMessages=1,VisibilityTimeout=900)
    for message in response.get("Messages",[]):
        work=tempfile.mkdtemp()
        try:
            body=json.loads(message["Body"])
            if body.get("Event")=="s3:TestEvent": sqs.delete_message(QueueUrl=QUEUE,ReceiptHandle=message["ReceiptHandle"]); continue
            key=unquote_plus(body["Records"][0]["s3"]["object"]["key"]); video_id=os.path.splitext(os.path.basename(key))[0].replace(" ","_")
            source=f"{work}/input"; output=f"{work}/hls"; os.mkdir(output); s3.download_file(INPUT,key,source)
            table.put_item(Item={"video_id":video_id,"status":"Processing","progress":10})
            subprocess.run(["/usr/local/bin/ffmpeg","-y","-i",source,"-profile:v","baseline","-level","3.0","-hls_time","10","-f","hls",f"{output}/playlist.m3u8"],check=True)
            for name in os.listdir(output): s3.upload_file(f"{output}/{name}",OUTPUT,f"{video_id}/{name}")
            table.put_item(Item={"video_id":video_id,"status":"Ready","progress":100}); sqs.delete_message(QueueUrl=QUEUE,ReceiptHandle=message["ReceiptHandle"])
        except Exception as exc: print(f"processing failed: {exc}",flush=True)
        finally: shutil.rmtree(work,ignore_errors=True)
