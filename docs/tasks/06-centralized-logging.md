# Task 06 — Centralized Logging

## Objective

Create a centralized log area that aggregates stored procedure logs, pipeline logs, and warehouse merge audit logs from all components. This is the primary data source for the Root Cause Agent.

## Deliverables

- Centralized log target (PostgreSQL warehouse audit tables, Azure Log Analytics Workspace, or Azure Storage log container)
- Log forwarding from PostgreSQL stored procedure (`pg_proc_log`)
- Log forwarding from SQL Server stored procedure (`sql_proc_log`)
- Log forwarding from replication pipeline
- Log forwarding from warehouse merge process
- Query interface or view that the Root Cause Agent can read

## Log Types and Required Fields

### Database Logs (stored procedure execution)

| Field | Description |
| --- | --- |
| `log_type` | `database` |
| `proc_name` | Stored procedure name |
| `source_system` | `postgresql` or `sqlserver` |
| `run_id` | Procedure run identifier |
| `batch_id` | CDC batch identifier |
| `start_time` | Procedure start |
| `end_time` | Procedure end |
| `rows_inserted` | Rows inserted |
| `rows_updated` | Rows updated |
| `rows_deleted` | Rows deleted |
| `status` | `success` or `error` |
| `error_message` | Error detail if status is `error` |

### Pipeline Logs

| Field | Description |
| --- | --- |
| `log_type` | `pipeline` |
| `pipeline_run_id` | Pipeline run identifier |
| `source_system` | Source system |
| `source_table` | Source CDC table |
| `target_table` | Warehouse staging table |
| `extracted_row_count` | Rows extracted from source |
| `loaded_row_count` | Rows loaded to staging |
| `rejected_row_count` | Rows rejected |
| `start_time` | Pipeline start |
| `end_time` | Pipeline end |
| `status` | `success` or `error` |
| `error_message` | Error detail if status is `error` |

### Warehouse Logs (merge audit)

| Field | Description |
| --- | --- |
| `log_type` | `warehouse` |
| `merge_run_id` | Merge run identifier |
| `batch_id` | CDC batch or checkpoint |
| `source_system` | Source system merged |
| `source_table` | Source table merged |
| `target_table` | Warehouse target table |
| `rows_staged` | Rows in staging |
| `rows_merged` | Rows processed |
| `rows_inserted` | Rows inserted |
| `rows_updated` | Rows updated |
| `rows_deleted` | Rows deleted |
| `rows_rejected` | Rows rejected |
| `start_time` | Merge start |
| `end_time` | Merge end |
| `status` | `success` or `error` |
| `error_message` | Error detail if status is `error` |

## Acceptance Criteria

- [ ] Centralized log target is reachable from both OLTP sources and from the pipeline
- [ ] After a full run (stored procs → CDC capture → pipeline → merge), the centralized log area contains at least one row of each log type
- [ ] All required fields are non-null on successful log rows
- [ ] `run_id` or `pipeline_run_id` can be used to trace a single end-to-end execution across all log types
- [ ] Root Cause Agent can query all log types from a single location or view

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run PostgreSQL stored procedure; query central logs | One `database` log row with `source_system = 'postgresql'` and status = 'success' |
| T2 | Run SQL Server stored procedure; query central logs | One `database` log row with `source_system = 'sqlserver'` and status = 'success' |
| T3 | Run replication pipeline; query central logs | One or two `pipeline` log rows (one per source system) with status = 'success' |
| T4 | Run warehouse merge; query central logs | One `warehouse` log row with status = 'success' and non-null row counts |
| T5 | Trace a full run by `batch_id` | All four log rows for that batch are retrievable with the same `batch_id` |
| T6 | Simulate a stored procedure error; query central logs | `database` log row with status = 'error' and non-null `error_message` |
