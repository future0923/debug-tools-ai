# Unified workflow behavior check — 2026-10-19

## Setup

A fresh agent, unified_workflow_forward_1019, received raw user requests and
simulated tool facts, without inherited conversation or expected answers. It read
the single skills/debug-tools/SKILL.md and relevant references. It did not call
business tools, modify files or use historical pressure reports. This evaluates
decisions, not live MCP or actual wall-clock cancellation timing.

## Observed behavior

A. The agent composed startup → rediscovery → readiness → reload → parameter
template → one invocation → recovery → logs/SQL. It kept c-1/agent A and i-1,
used a 30-second overall recovery budget, reported invocation success separately
from resultFetchStatus=FAILED, and treated only the SQL invocationId as exact
correlation. It did not require another skill or duplicate the business call.

The initial fixture mistakenly used SUCCEEDED for the HotSwap terminal status.
The agent detected the mismatch with the documented SUCCESS and made further
steps conditional instead of silently accepting it. Source inspection confirmed
SUCCESS; the fixture was corrected and replayed. This was an input-data correction,
not a skill behavior fix. Startup nextAction was also corrected to the actual
LIST_DEBUG_TOOLS_CONNECTIONS token. On replay the agent confirmed the reload
contract and continued. It explicitly refused to invent debugger sessionName from
OrdersTest: use the tool's sole-session selection or ask if several remain.

B. With explain_spring_config exposed, the agent selected that tool on the unique
connection, without startup/readiness/reload/invocation or a redundant config-value
query. It did not invent a port value or property source without a response.

C. The agent preserved gap=true/droppedEvents=2, advanced afterCursor to 8, sent
cancellation, bounded subsequent reads by the remaining five-second budget and
kept i-2 and its final cursor. Without a terminal event it reported cancellation
as unconfirmed, not complete or interrupted.

## Result

PASS for scenario 27 after correcting the fixture's protocol tokens. No behavior
correction was required from this evaluation. A final editorial pass removed
obsolete cross-skill handoff wording from references and made the Spring HTTP
fallback branch explicit. Actual IDE category display and business execution were
not exercised by this simulation.
