FROM python:3-alpine
EXPOSE 11000
CMD ["python", "-c", "from http.server import HTTPServer, BaseHTTPRequestHandler; import json; class H(BaseHTTPRequestHandler): def do_GET(self): self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers(); self.wfile.write(json.dumps({'status':'ok'}).encode()) HTTPServer(('',11000),H).serve_forever()"]