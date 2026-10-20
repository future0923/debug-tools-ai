# Independent result recovery behavior check

- Date: 2026-10-14
- Mode: fresh isolated AI agent; read-only reasoning scenario, no live JVM execution
- Input: timed-out charge invocation, ambiguous second connection, unconfirmed Flux cancellation, agent-only logs
- Resources: method invocation Skill, runtime diagnostic reference, troubleshooting reference
- Outcome: passed target binding, no reinvocation, unknown-state preservation, terminal-event checks and log-source distinction

The evaluator selected `get_invocation_result` with project `/work/billing`,
connection `billing-a`, invocation `i-42` and a bounded wait. It rejected changing
to `billing-copy`. It required the separate Flux invocation's own identity and
cursor, and distinguished CANCELLED, COMPLETE and ERROR outcomes.

Follow-up improvements from the independent review:

- Clarified that connection recovery must not retry a possibly executed method.
- Added an overall 30-second default polling budget with unknown-state reporting.
- Added log-source limitations to the primary Skill, not only its reference.

This validates agent choices in the scenario; it is not evidence of live runtime
integration or a full behavior regression suite.
