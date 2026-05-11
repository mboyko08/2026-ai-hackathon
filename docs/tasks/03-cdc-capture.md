# Task 03 — CDC Capture

## Objective

Enable or simulate CDC (Change Data Capture) on both OLTP sources so that inserts, updates, and deletes from the stored procedures are recorded in change tables with a standard shape.

## Deliverables

- CDC enabled on the PostgreSQL source table (via logical replication, `pgoutput`, or a simulated change table)
- CDC enabled on the SQL Server source table (via SQL Server CDC or a simulated change table)
- Change records conforming to the standard CDC field shape for both sources

## Standard CDC Field Shape

| Field | Type | Purpose |
| --- | --- | --- |
| `source_system` | varchar | `postgresql` or `sqlserver` |
| `source_table` | varchar | Source table name |
| `primary_key_value` | varchar | Business or technical primary key (cast to string) |
| `operation_type` | varchar | `insert`, `update`, or `delete` |
| `change_sequence` | bigint | CDC ordering value (LSN or sequence number) |
| `change_timestamp` | timestamptz | When the change occurred in the source |
| `extracted_at` | timestamptz | When the pipeline extracted the change (set during extraction) |
| `loaded_at` | timestamptz | When the warehouse loaded the change (set during load) |

## Implementation Notes

- For PostgreSQL: use native logical replication or a trigger-based change table if logical replication is not available in the hackathon environment.
- For SQL Server: use native CDC (`sys.fn_cdc_get_all_changes_*`) or a trigger-based change table as fallback.
- `extracted_at` and `loaded_at` are set by the pipeline, not the source.
- `change_sequence` must be monotonically increasing within each source system.

## Acceptance Criteria

- [ ] After running the PostgreSQL stored procedure, change records appear in the PostgreSQL CDC / change table
- [ ] After running the SQL Server stored procedure, change records appear in the SQL Server CDC / change table
- [ ] Each change record includes all eight standard CDC fields with no nulls on required fields
- [ ] `operation_type` correctly reflects insert, update, and delete operations
- [ ] `change_sequence` values are strictly ordered within each source
- [ ] Change records for soft-deletes are recorded as `update` (field change) or `delete` depending on the chosen CDC strategy — strategy is documented

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run PostgreSQL stored procedure; query PostgreSQL change table | 14 change records (10 inserts + 3 updates + 1 soft-delete) with correct `operation_type` |
| T2 | Run SQL Server stored procedure; query SQL Server change table | 14 change records with correct `operation_type` |
| T3 | Inspect `change_sequence` on PostgreSQL change records | Values are non-null and monotonically increasing |
| T4 | Inspect `change_sequence` on SQL Server change records | Values are non-null and monotonically increasing |
| T5 | Run each stored procedure twice | Second run produces change records with higher `change_sequence` values than the first run |
| T6 | Confirm `source_system` field | PostgreSQL records have `source_system = 'postgresql'`; SQL Server records have `source_system = 'sqlserver'` |
