import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('contracts', Path(__file__).resolve().parent.parent / 'scripts/check-tool-contracts.py')
contracts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contracts)


class ContractTest(unittest.TestCase):
    def test_detects_removed_tool_changed_limits_and_new_required_arguments(self):
        base = {'tools': [{'name': 'read', 'inputSchema': {'properties': {'limit': {'maximum': 100}}, 'required': []}}]}
        contracts.compare(base, copy.deepcopy(base))
        for changed in [{'tools': []}, copy.deepcopy(base), copy.deepcopy(base)]:
            if changed['tools']:
                schema = changed['tools'][0]['inputSchema']
                if not hasattr(self, 'changed_limit'):
                    schema['properties']['limit']['maximum'] = 10
                    self.changed_limit = True
                else:
                    schema['required'] = ['limit']
            with self.assertRaisesRegex(ValueError, 'drift: read'):
                contracts.compare(base, changed)

    def test_detects_workflow_or_identity_drift(self):
        base = {'tools': [{'name': 'read', 'inputSchema': {}, 'workflow': {'id': 'METHOD_INVOCATION'}, 'fullyQualifiedName': 'legacy.read'}]}
        for field, value in [('workflow', {'id': 'HTTP'}), ('fullyQualifiedName', 'new.read')]:
            changed = copy.deepcopy(base)
            changed['tools'][0][field] = value
            with self.assertRaises(ValueError):
                contracts.compare(base, changed)

    def test_output_rejects_string_boolean_missing_handle_and_wrong_status_type(self):
        schema = {'type': 'object', 'required': ['success', 'data'], 'properties': {
            'success': {'const': True}, 'data': {'type': 'object', 'required': ['operationId'],
            'properties': {'operationId': {'type': 'string'}}}}}
        contracts.validate_response(schema, {'success': True, 'data': {'operationId': 'op'}})
        for invalid in [{'success': 'true', 'data': {'operationId': 'op'}},
                        {'success': True, 'data': {}}, {'success': True, 'data': {'operationId': 7}}]:
            with self.assertRaises(ValueError):
                contracts.validate_response(schema, invalid)
        with self.assertRaises(ValueError):
            contracts.validate_response({'unknownKeyword': True}, {})


if __name__ == '__main__':
    unittest.main()
