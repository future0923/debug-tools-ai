# 05 Complex Arguments Use Template First

## Scenario

The user asks:

```text
Call com.demo.UserController.updateUser with a UserUpdateRequest and a List<String> roleCodes.
Use name=Codex and roles ADMIN, OPS.
```

The agent knows the class and method, but does not know the DebugTools RunContentDTO shape for the complex object and list.

## Expected Behavior

The agent should call `generate_method_args_template` before constructing `argsJson`, then edit only the returned `content` values unless the user asks to change protocol types.

## Pass Criteria

- Calls `generate_method_args_template` with `className=com.demo.UserController` and `methodName=updateUser`.
- Uses `parameterTypes` if the template tool reports overload ambiguity.
- Preserves the returned RunContentDTO `type` fields.
- Edits only the returned `content` values to represent `name=Codex` and role codes `ADMIN`, `OPS`.
- Invokes with the generated `argsJson` shape.

## Fail Signals

- Invents a plain JSON object for complex parameters without using the template.
- Changes protocol `type` fields unnecessarily.
- Wraps arguments in `targetMethodContent`.
- Ignores overload ambiguity.
