"""Exercise MCP handshake, session binding and paged discovery against a local fixture."""
import importlib.util
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading
import unittest

spec = importlib.util.spec_from_file_location('doctor', Path(__file__).resolve().parent.parent / 'scripts/doctor-runtime.py')
doctor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(doctor)


class DoctorTest(unittest.TestCase):
    def test_handshake_and_discovery_never_invokes_tools(self):
        calls = []

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                calls.append((body, dict(self.headers)))
                method = body['method']
                if method == 'notifications/initialized':
                    self.send_response(202)
                    self.end_headers()
                    return
                if method == 'initialize':
                    result = {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}}
                elif 'cursor' not in body['params']:
                    result = {'tools': [{'name': 'get_debug_tools_status'}], 'nextCursor': 'p2'}
                else:
                    result = {'tools': [{'name': 'invoke_java_method'}]}
                raw = json.dumps({'jsonrpc': '2.0', 'id': body['id'], 'result': result}).encode()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Mcp-Session-Id', 'fixture-session')
                self.end_headers()
                self.wfile.write(raw)

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        worker = threading.Thread(target=server.serve_forever, daemon=True)
        worker.start()
        try:
            result = doctor.check_mcp(f'http://127.0.0.1:{server.server_port}/mcp')
            self.assertEqual(result['toolCount'], 2)
            self.assertFalse(result['truncated'])
            self.assertEqual([call[0]['method'] for call in calls], ['initialize', 'notifications/initialized', 'tools/list', 'tools/list'])
            self.assertTrue(all(call[1].get('Mcp-Session-Id') == 'fixture-session' for call in calls[1:]))
        finally:
            server.shutdown()
            server.server_close()
            worker.join()

    def test_disallows_credentials_embedded_in_url(self):
        with self.assertRaises(ValueError):
            doctor.check_mcp('http://user:secret@localhost/mcp')


if __name__ == '__main__':
    unittest.main()
