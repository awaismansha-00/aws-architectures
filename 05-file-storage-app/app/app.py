import os, requests
from flask import Flask, jsonify, request, render_template_string
app = Flask(__name__); API_URL=os.environ["API_URL"]; HEADERS={"x-api-key":os.environ["API_KEY"]}
HTML='''<!doctype html><title>Terraform Drive</title><h1>Private File Storage</h1><input id="f" type="file"><button onclick="upload()">Upload</button><ul id="files"></ul><script>
async function call(path,opts={}){let r=await fetch('/api/'+path,opts);return r.json()} async function load(){let a=await call('files');files.innerHTML=a.map(x=>`<li>${x.file_id} (${x.size_bytes} bytes) <button onclick="download('${encodeURIComponent(x.file_id)}')">Download</button> <button onclick="del('${encodeURIComponent(x.file_id)}')">Delete</button></li>`).join('')} async function upload(){let x=f.files[0];if(!x)return;let u=await call('upload-url?filename='+encodeURIComponent(x.name));await fetch(u.upload_url,{method:'PUT',body:x});setTimeout(load,1500)} async function download(n){let u=await call('download-url?filename='+n);location=u.download_url} async function del(n){await call('delete-file?filename='+n,{method:'DELETE'});load()} load();</script>'''
@app.get("/")
def home(): return render_template_string(HTML)
@app.route("/api/<path:path>", methods=["GET","DELETE"])
def proxy(path):
    r=requests.request(request.method, f"{API_URL}/{path}", params=request.args, headers=HEADERS, timeout=15)
    return (r.content, r.status_code, {"Content-Type":r.headers.get("Content-Type","application/json")})
app.run(host="0.0.0.0",port=80)
