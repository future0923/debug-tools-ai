#!/usr/bin/env python3
"""Validate the packaged input contract and compare it with the IDEA export when supplied."""
import argparse
import json
from pathlib import Path


def read_contract(path):
    value = json.loads(path.read_text())
    assert value['contractVersion'] == 1, 'Unsupported contract version'
    tools = value['tools']
    assert tools and len({tool['name'] for tool in tools}) == len(tools), 'Empty/duplicate tools'
    for tool in tools:
        assert isinstance(tool.get('outputSchema'), dict), tool['name'] + ': missing output contract'
        assert isinstance(tool.get('workflow'), dict), tool['name'] + ': missing workflow'
        assert isinstance(tool.get('fullyQualifiedName'), str), tool['name'] + ': missing stable identity'
        schema = tool['inputSchema']
        assert schema['type'] == 'object'
        assert set(schema['required']) <= set(schema['properties']), tool['name'] + ': unknown required property'
        assert 'projectPath' in schema['properties'], tool['name'] + ': missing project scope'
    return value


def compare(packaged, exported):
    expected = {item['name']: (item['inputSchema'], item.get('outputSchema'), item.get('workflow'), item.get('fullyQualifiedName')) for item in packaged['tools']}
    actual = {item['name']: (item['inputSchema'], item.get('outputSchema'), item.get('workflow'), item.get('fullyQualifiedName')) for item in exported['tools']}
    changed = sorted(name for name in expected.keys() | actual.keys() if expected.get(name) != actual.get(name))
    if changed:
        raise ValueError('MCP input/output contract drift: ' + ', '.join(changed))


def validate_response(schema, value, path='$'):
    """Validate the deliberately small output-schema vocabulary, without external packages."""
    allowed = {'type', 'properties', 'required', 'const', 'oneOf', 'anyOf', 'description', 'items'}
    unknown = set(schema) - allowed
    if unknown:
        raise ValueError(f'{path}: unsupported schema keywords {sorted(unknown)}')
    for union in ('oneOf', 'anyOf'):
        if union in schema:
            matched = 0
            for candidate in schema[union]:
                try:
                    validate_response(candidate, value, path)
                    matched += 1
                except ValueError:
                    pass
            if (union == 'oneOf' and matched != 1) or (union == 'anyOf' and matched == 0):
                raise ValueError(f'{path}: response does not match {union}')
    if 'const' in schema and (type(value) is not type(schema['const']) or value != schema['const']):
        raise ValueError(f'{path}: unexpected constant')
    checks = {'object': lambda v: isinstance(v, dict), 'array': lambda v: isinstance(v, list),
              'string': lambda v: isinstance(v, str), 'boolean': lambda v: isinstance(v, bool),
              'integer': lambda v: type(v) is int, 'number': lambda v: type(v) in (int, float),
              'null': lambda v: v is None}
    kind = schema.get('type')
    if kind and (kind not in checks or not checks[kind](value)):
        raise ValueError(f'{path}: expected {kind}')
    if isinstance(value, dict):
        for name in schema.get('required', []):
            if name not in value:
                raise ValueError(f'{path}: missing {name}')
        for name, child in schema.get('properties', {}).items():
            if name in value:
                validate_response(child, value[name], f'{path}.{name}')
    if isinstance(value, list) and 'items' in schema:
        for index, item in enumerate(value):
            validate_response(schema['items'], item, f'{path}[{index}]')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--plugin-export', type=Path, help='build/generated/debug-tools-mcp-contracts.json from IDEA tests')
    parser.add_argument('--response', type=Path, help='Captured JSON tool response to validate')
    parser.add_argument('--tool', help='Exact tool name for --response')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    packaged = read_contract(root / 'docs/mcp-input-contracts.json')
    if args.response:
        if not args.tool:
            parser.error('--response requires --tool')
        matches = [tool for tool in packaged['tools'] if tool['name'] == args.tool]
        if len(matches) != 1:
            raise ValueError('Unknown tool: ' + args.tool)
        validate_response(matches[0]['outputSchema'], json.loads(args.response.read_text()))
        print('Captured response matches output contract: ' + args.tool)
    if args.plugin_export:
        compare(packaged, read_contract(args.plugin_export))
        print('MCP input/output contracts match the plugin export')
    else:
        print('Packaged MCP input/output contracts valid; cross-repository drift check requires --plugin-export')


if __name__ == '__main__':
    main()
