#!/usr/bin/env python3
"""AJD Test Utility: Fake HTTP Service

Simulates a service listening on a port for AJD health checks.
Usage:
    python3 test_fake_service.py --port 8080
    python3 test_fake_service.py --port 8080 --health-path /health --response '{"status":"ok"}'
"""
import argparse
import json
import signal
import sys
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler


class HealthHandler(BaseHTTPRequestHandler):
    """HTTP handler for health check endpoints."""

    def __init__(self, *args, health_path="/health", response_data=None, **kwargs):
        self.health_path = health_path
        self.response_data = response_data or {"status": "ok", "service": "ajd-test"}
        super().__init__(*args, **kwargs)

    def do_GET(self):
        if self.path == self.health_path or self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(self.response_data).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "not found"}')

    def log_message(self, format, *args):
        # Suppress default log messages
        pass


def make_handler(health_path, response_data):
    """Create a handler class with the given config."""
    class ConfiguredHandler(HealthHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, health_path=health_path, response_data=response_data, **kwargs)
    return ConfiguredHandler


def main():
    parser = argparse.ArgumentParser(description="Fake HTTP service for AJD testing")
    parser.add_argument("--port", type=int, required=True, help="Port to listen on")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind (default: 127.0.0.1)")
    parser.add_argument("--health-path", default="/health", help="Health check path (default: /health)")
    parser.add_argument("--response", default='{"status":"ok"}', help="JSON response for health check")
    parser.add_argument("--timeout", type=int, default=0, help="Auto-shutdown after N seconds (0 = run forever)")
    args = parser.parse_args()

    try:
        response_data = json.loads(args.response)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in --response: {e}")
        sys.exit(1)

    handler_class = make_handler(args.health_path, response_data)

    server = HTTPServer((args.host, args.port), handler_class)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()

    print(f"=== AJD Fake Service ===")
    print(f"Listening on http://{args.host}:{args.port}")
    print(f"Health endpoint: http://{args.host}:{args.port}{args.health_path}")
    print(f"Response: {json.dumps(response_data)}")
    if args.timeout > 0:
        print(f"Auto-shutdown in {args.timeout}s")
    print("Press Ctrl+C to stop")
    print()

    try:
        if args.timeout > 0:
            time.sleep(args.timeout)
            print(f"\n⏰ Timeout reached ({args.timeout}s), shutting down...")
        else:
            # Wait forever
            while True:
                time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Interrupted, shutting down...")
    finally:
        server.shutdown()
        server.server_close()
        print("✅ Server stopped")


if __name__ == "__main__":
    main()