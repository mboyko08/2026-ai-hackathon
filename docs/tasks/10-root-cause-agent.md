# Task 10 — Root Cause Agent

## Objective

Configure the Root Cause Agent to receive structured validation results from the Validation Agent, read centralized logs, identify the most likely failure point, and recommend one specific next action.

## Deliverables

- Updated `root-cause.agent.md` with complete prompt and failure category logic
- Validated against the diagnosis scenarios below

## Responsibilities

- Receive structured CDC Executor skill results from the Validation Agent.
- Query the centralized log area for: stored procedure logs, pipeline logs, and warehouse merge audit logs relevant to the failed batch.
- Map the failure pattern to one of the standard failure categories.
- Return a root cause summary with cited log evidence and one recommended action.

## Failure Category Reference

| Category | Key Signals |
| --- | --- |
| Stored procedure data generation | Procedure log missing, zero rows inserted, error status in `pg_proc_log` or `sql_proc_log` |
| CDC capture | No change records in source CDC table after procedure ran |
| CDC extract | Pipeline extracted fewer rows than exist in source CDC table |
| CDC transformation | Rejected row count > 0 in pipeline log; type errors |
| Warehouse load | Rows staged but merge count lower than expected |
| Merge logic | Unexpected row count after merge; merge audit shows error |
| Duplicate handling | `duplicate_keys` check failed; `rows_merged` > distinct key count |
| Delete handling | Delete operations in source CDC not reflected in warehouse |
| Stale pipeline checkpoint | Source max `change_sequence` > last processed checkpoint in warehouse audit |
| Null handling | `null_counts` check failed; nulls in required warehouse columns |

## Output Format

Return a root cause summary with:

- `failed_checks`: list of check names that returned status = 'failed' or 'warning'
- `likely_failure_point`: one category name from the table above
- `log_evidence`: specific log rows or field values that support the conclusion (must be from actual log data)
- `recommended_action`: one specific, actionable next step for a human to take

## Acceptance Criteria

- [ ] Agent maps every failed check result to a failure category from the standard list
- [ ] `log_evidence` cites only log data that was actually returned — no invented evidence
- [ ] `recommended_action` is specific and actionable (not generic like "check your pipeline")
- [ ] Agent does not recommend automatic remediation
- [ ] When all checks pass, agent returns a clean summary with no failure category

## Test Cases

| # | Scenario | Expected Diagnosis |
| --- | --- | --- |
| T1 | `row_count` failed; pipeline log shows 0 extracted rows; procedure log shows 0 inserts | `likely_failure_point = 'Stored procedure data generation'`; evidence cites procedure log |
| T2 | `row_count` failed; procedure log shows 14 rows; pipeline log shows 0 extracted | `likely_failure_point = 'CDC capture'`; evidence cites pipeline log |
| T3 | `row_count` failed; pipeline log shows 14 extracted, 10 loaded | `likely_failure_point = 'CDC extract'` or `'CDC transformation'`; evidence cites pipeline rejected count |
| T4 | `checkpoint` failed; source max `change_sequence` > last warehouse checkpoint | `likely_failure_point = 'Stale pipeline checkpoint'`; evidence cites both values |
| T5 | `duplicate_keys` failed; merge audit shows rows_merged > distinct keys | `likely_failure_point = 'Duplicate handling'`; evidence cites merge audit |
| T6 | All checks pass | Root cause summary shows no failures; no failure category emitted |
