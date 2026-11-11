#!/usr/bin/env python3
"""
Custom local HTTP server for Godot 4 HTML5/WASM web exports.
Sends Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy headers required for WebAssembly.
"""

import http.server
import os
import socketserver
import sys

DEFAULT_PORT = 8080
DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "builds", "web"))

class GodotHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Enable Cross-Origin Isolation for Godot 4 WASM / SharedArrayBuffer
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

def run_server(port=DEFAULT_PORT):
    handler = GodotHTTPRequestHandler
    # Allow port reuse
    socketserver.TCPServer.allow_reuse_address = True
    
    for p in range(port, port + 10):
        try:
            with socketserver.TCPServer(("", p), handler) as httpd:
                print(f"LITTLEBRICKS_SERVER_READY:http://localhost:{p}")
                sys.stdout.flush()
                httpd.serve_forever()
                break
        except OSError as e:
            if "Address already in use" in str(e):
                continue
            else:
                raise e

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    run_server(port)
