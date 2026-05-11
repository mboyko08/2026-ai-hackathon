# Task 07 — Orchestrator Agent

## Objective

Configure the Orchestrator Agent as the user-facing entry point that parses validation requests, identifies the source system and warehouse table scope, coordinates the Validation Agent, and returns a concise final summary.

## Deliverables

- Updated `orchestrator.agent.md` with complete prompt and workflow
- Validated against the example request scenarios below

## Responsibilities

- Parse the user's validation request to identify: source system(s), warehouse table(s), and optional batch or checkpoint scope.
- Default to validating both PostgreSQL and SQL Server sources when scope is ambiguous.
- Forward a structured request to the Validation Agent.
- Receive the final root cause summary from the Root Cause Agent.
- Return a formatted validation summary to the user.

## Output Format

The Orchestrator Agent must return a summary that includes:

- Overall status (passed / failed / warning)
- Source systems validated
- Warehouse table(s) compared
- CDC batch or checkpoint covered
- Checks that passed
- Checks that failed or warned
- Likely root cause
- Recommended next action

## Acceptance Criteria

- [ ] Given the request "Validate the latest CDC replication from OLTP to the warehouse", the agent identifies both PostgreSQL and SQL Server as sources
- [ ] Agent does not ask for clarification when the request is unambiguous
- [ ] Agent asks one targeted clarifying question when source or table is genuinely ambiguous
- [ ] Agent does not produce validation results directly — it delegates to the Validation Agent
- [ ] Final summary includes all required output fields
- [ ] Agent does not recommend automatic remediation

## Test Cases

| # | Scenario | Expected Behavior |
| --- | --- | --- |
| T1 | "Validate the latest CDC replication" | Orchestrator identifies both sources, forwards request to Validation Agent, returns summary |
| T2 | "Validate PostgreSQL CDC only" | Orchestrator scopes to PostgreSQL only; SQL Server not included |
| T3 | "Check if batch 42 loaded correctly" | Orchestrator includes `batch_id = 42` in the request to the Validation Agent |
| T4 | Validation Agent returns a failed check | Summary clearly marks that check as failed with the root cause explanation |
| T5 | All checks pass | Summary shows overall status = passed; no root cause section needed |
| T6 | Ambiguous request with no source or table | Agent asks one clarifying question before proceeding |
