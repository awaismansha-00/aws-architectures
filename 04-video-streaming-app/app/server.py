import os
import boto3
from flask import Flask, jsonify, request, Response
app=Flask(__name__); s3=boto3.client("s3",region_name=os.environ["AWS_REGION"]); table=boto3.resource("dynamodb",region_name=os.environ["AWS_REGION"]).Table(os.environ["TABLE_NAME"]); INPUT=os.environ["INPUT_BUCKET"]; OUTPUT=os.environ["OUTPUT_BUCKET"]
HTML='''<!doctype html><title>Video Lab</title><h1>Video Streaming Lab</h1><input id=f type=file accept=video/mp4><button onclick="up()">Upload</button><div id=v></div><script>async function load(){let a=await(await fetch('/api/videos')).json();v.innerHTML=a.map(x=>`<p>${x.video_id}: ${x.status} ${x.progress}% ${x.status==='Ready'?`<video width=480 controls src="/stream/${encodeURIComponent(x.video_id)}/playlist.m3u8"></video>`:''}</p>`).join('')}async function up(){let d=new FormData();d.append('file',f.files[0]);await fetch('/upload',{method:'POST',body:d});load()}load();setInterval(load,3000)</script>'''
@app.get("/")
def home(): return HTML
@app.get("/api/videos")
def videos(): return jsonify(table.scan().get("Items",[]))
@app.post("/upload")
def upload():
    f=request.files.get("file");
    if not f or not f.filename.lower().endswith(".mp4"): return jsonify(error="MP4 required"),400
    s3.upload_fileobj(f,INPUT,f.filename); return jsonify(status="queued")
@app.get("/stream/<video>/<path:name>")
def stream(video,name):
    obj=s3.get_object(Bucket=OUTPUT,Key=f"{video}/{name}"); return Response(obj["Body"].iter_chunks(),mimetype="application/vnd.apple.mpegurl" if name.endswith("m3u8") else "video/mp2t")
app.run(host="0.0.0.0",port=80)
