FROM python:3-alpine
EXPOSE 11001
CMD ["python", "-c", "from http.server import HTTPServer, BaseHTTPRequestHandler; import json\nclass H(BaseHTTPRequestHandler):\n def do_GET(self):\n  self.send_response(200)\n  self.send_header('Content-Type','application/json')\n  self.end_headers()\n  self.wfile.write(json.dumps({'status':'ok'}).encode())\nHTTPServer(('',11001),H).serve_forever()"]