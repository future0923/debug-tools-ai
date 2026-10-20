#!/usr/bin/env python3
"""Check runtime versions and an explicitly supplied MCP endpoint; never scan ports."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.parse
import urllib.request

MAX_BYTES = 1024 * 1024


class NoRedirect(urllib.request.HTTPRedirectHandler):
    """Keep optional bearer credentials and session identity on the selected endpoint."""
    def redirect_request(self, *_args, **_kwargs):
        raise ValueError('MCP endpoint redirects are not followed')


def rpc(url, body, headers, request_id):
    request = urllib.request.Request(url, json.dumps(body).encode(), headers={
        'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream', **headers,
    })
    with urllib.request.build_opener(NoRedirect).open(request, timeout=5) as response:
        session = response.headers.get('Mcp-Session-Id')
        if request_id is None:
            return None, session
        if 'text/event-stream' not in response.headers.get('Content-Type', ''):
            raw = response.read(MAX_BYTES + 1)
            if len(raw) > MAX_BYTES:
                raise ValueError('MCP response exceeds 1 MiB')
            message = json.loads(raw)
        else:
            size, deadline, data = 0, time.monotonic() + 5, []
            while True:
                if time.monotonic() > deadline:
                    raise TimeoutError('MCP event response deadline exceeded')
                line = response.readline(MAX_BYTES + 1)
                size += len(line)
                if size > MAX_BYTES:
                    raise ValueError('MCP event response exceeds 1 MiB')
                if not line:
                    raise ValueError('MCP stream ended before the requested response')
                if line.strip() == b'' and data:
                    candidate = json.loads('\n'.join(data))
                    data = []
                    if candidate.get('id') == request_id:
                        message = candidate
                        break
                elif line.startswith(b'data:'):
                    data.append(line[5:].decode().strip())
        if message.get('id') != request_id:
            raise ValueError('MCP response ID mismatch')
        if 'error' in message:
            raise ValueError('MCP JSON-RPC error code ' + str(message['error'].get('code')))
        if not isinstance(message.get('result'), dict):
            raise ValueError('MCP response has no result object')
        return message['result'], session


def check_mcp(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in ('http', 'https') or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError('Use an explicit HTTP(S) MCP URL without embedded credentials')
    headers = {}
    token = os.environ.get('DEBUG_TOOLS_MCP_TOKEN')
    if token:
        headers['Authorization'] = 'Bearer ' + token
    initialized, session = rpc(url, {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {
        'protocolVersion': '2024-11-05', 'capabilities': {},
        'clientInfo': {'name': 'debug-tools-ai-doctor', 'version': '0.1.0'},
    }}, headers, 1)
    if session:
        headers['Mcp-Session-Id'] = session
    version = initialized.get('protocolVersion')
    if not isinstance(version, str) or not version:
        raise ValueError('MCP initialize did not negotiate a protocol version')
    headers['MCP-Protocol-Version'] = version
    rpc(url, {'jsonrpc': '2.0', 'method': 'notifications/initialized'}, headers, None)
    names, cursor = [], None
    for page in range(10):
        params = {} if cursor is None else {'cursor': cursor}
        result, _ = rpc(url, {'jsonrpc': '2.0', 'id': page + 2, 'method': 'tools/list', 'params': params}, headers, page + 2)
        tools = result.get('tools')
        if not isinstance(tools, list):
            raise ValueError('MCP tools/list has no tools array')
        names.extend(item['name'] for item in tools if isinstance(item, dict) and isinstance(item.get('name'), str))
        cursor = result.get('nextCursor')
        if not cursor:
            break
    relevant = [name for name in names if 'debug' in name.lower() or name.endswith('invoke_java_method')]
    return {'protocolVersion': version, 'toolCount': len(names), 'debugTools': relevant, 'truncated': bool(cursor)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mcp-url', help='Explicit Streamable HTTP MCP endpoint; no invocation is executed')
    args = parser.parse_args()
    package = json.loads((Path(__file__).resolve().parent.parent / 'package.json').read_text())
    print('OK   Package version: ' + package['version'])
    print('OK   Python version: ' + sys.version.split()[0])
    try:
        node = subprocess.run(['node', '--version'], check=True, capture_output=True, text=True, timeout=5).stdout.strip()
        if int(node.lstrip('v').split('.')[0]) < 18:
            raise ValueError('Node.js 18 or newer is required for adapter checks')
        print('OK   Node.js version: ' + node)
        if args.mcp_url:
            result = check_mcp(args.mcp_url)
            print('OK   MCP discovery: ' + json.dumps(result))
            if not result['debugTools']:
                print('FAIL MCP connected but no DebugTools tools were discovered')
                return 1
        else:
            print('SKIP MCP connectivity: supply --mcp-url to check an explicit endpoint')
    except Exception as error:
        # Exception messages can contain credential-bearing URLs; output only a stable category.
        print('FAIL Runtime/connectivity check: ' + type(error).__name__)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
