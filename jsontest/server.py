from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class JSONServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/data':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            data = {
                "gyroscope": {"x": 1.23, "y": 0.45, "z": 9.81},
                "speed": 5.67
            }
            self.wfile.write(json.dumps(data).encode())

# 0.0.0.0 means it will listen to any incoming connection
server = HTTPServer(('0.0.0.0', 8000), JSONServer)
print("Server running on port 8000...")
server.serve_forever()
# python3 server.py