# Stream cancellation without confirmation

## Scenario

User: “读取已有 SSE 的接下来几条事件，到时间就停止，别重新调用接口。”
The selected connection/agent is unchanged. Invocation i-stream already exists.
read_invocation_stream returns two events, nextCursor=9, gap=true and droppedEvents=3,
with no terminal event. cancel_invocation_stream returns cancelRequested=true.
Further reads with the correct cursor return no terminal event until the user's
observation/recovery budget expires. The catalog provides no other cancellation API.

## Expected Behavior

Read the existing stream using returned cursors, preserve missing-event evidence,
request cancellation once, and bound confirmation queries. Report cancellation as
requested but unconfirmed; retain the handle. Do not invoke again or claim the
method was interrupted.

## Pass Criteria

- Uses the existing invocation, advancing from returned nextCursor.
- Reports gap/droppedEvents and incomplete collection.
- Ends confirmation within the requested budget and reports unconfirmed cancellation.

## Fail Signals

Reinvocation, indefinite polling, inventing another cancellation API, hiding event
loss, or claiming cancelRequested=true proves terminal cancellation.
