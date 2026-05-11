# Task 08 — Validation Agent

## Objective

Configure the Validation Agent to build a minimal, targeted validation plan from the Orchestrator Agent's request and invoke the CDC Executor skill with that plan.

## Deliverables

- Updated `validation.agent.md` with complete prompt and check selection logic
- Validated against the check selection scenarios below

## Responsibilities

- Receive the validation request from the Orchestrator Agent (source systems, warehouse tables, optional batch constraint).
- Select the appropriate checks from the standard check list.
- Build a structured validation plan for each source system in scope.
- Invoke the CDC Executor skill with the plan.
- Receive structured results from the CDC Executor skill.
- Forward all results to the Root Cause Agent.

## Standard Check List

| Check Name | When to Include |
| --- | --- |
| `row_count` | Always |
| `missing_keys` | Always |
| `duplicate_keys` | Always |
| `checkpoint` | Always |
| `operation_counts` | Always |
| `null_counts` | Always |

Default: include all six checks unless the Orchestrator Agent explicitly scopes to a subset.

## Validation Plan Format (passed to CDC Executor skill)

```
source_system: postgresql | sqlserver
source_table: <table name>
warehouse_table: <warehouse target table name>
checks: [row_count, missing_keys, duplicate_keys, checkpoint, operation_counts, null_counts]
batch_id: <optional>
```

## Acceptance Criteria

- [ ] Validation plan includes all six checks when no subset is specified
- [ ] Plan correctly identifies source table name and warehouse target table name
- [ ] Plan is passed to the CDC Executor skill (not executed directly by the Validation Agent)
- [ ] Structured results from the CDC Executor skill are forwarded to the Root Cause Agent without modification
- [ ] Agent does not invent or estimate check results

## Test Cases

| # | Scenario | Expected Behavior |
| --- | --- | --- |
| T1 | Request to validate both sources | Validation Agent produces two plans (one per source); both passed to CDC Executor skill |
| T2 | Request scoped to PostgreSQL only | Only a PostgreSQL plan produced; SQL Server not included |
| T3 | Request includes `batch_id = 42` | Plan includes `batch_id: 42` for both sources |
| T4 | CDC Executor skill returns a failed `row_count` check | Validation Agent forwards the failed result to Root Cause Agent unchanged |
| T5 | Explicit request for only `missing_keys` check | Plan includes only `missing_keys`; other checks omitted |
