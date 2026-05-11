# Task 01 — PostgreSQL OLTP Setup

## Objective

Create the PostgreSQL OLTP source database with a sample data table, a stored procedure that generates transactional records, and a procedure execution log table.

## Deliverables

- PostgreSQL database (local Docker or Azure Database for PostgreSQL)
- Source data table (e.g. `customers`, `permits`, or `transactions`)
- Stored procedure `generate_oltp_records` that inserts, updates, and soft-deletes rows
- Procedure execution log table `pg_proc_log`
- Log entries forwarded to the centralized log area after each run

## Implementation Notes

- Use PostgreSQL-native sequences for primary keys.
- Emit a `run_id` (UUID) and `batch_id` for every stored procedure execution.
- The procedure must write one row to `pg_proc_log` per run including: start time, end time, rows inserted, rows updated, rows deleted, and status.
- Do not depend on SQL Server or any shared runtime state.
- Forward the `pg_proc_log` entry to the centralized log area (warehouse audit table or Azure Log Analytics) after each run.

## Example Procedure Behavior

- Insert 10 new records
- Update 3 existing records
- Mark 1 record as soft-deleted (`is_deleted = true`)

## Acceptance Criteria

- [ ] PostgreSQL database is reachable and the source table exists with required columns
- [ ] Stored procedure executes without error
- [ ] After one run: exactly 10 new rows inserted, 3 rows updated, 1 row soft-deleted in the source table
- [ ] `pg_proc_log` contains one row per run with non-null start time, end time, rows inserted, rows updated, rows deleted, and status = 'success'
- [ ] `batch_id` and `run_id` are non-null on every log row
- [ ] Log entry appears in the centralized log area within the same run

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run stored procedure once | 10 inserts, 3 updates, 1 soft-delete in source table |
| T2 | Run stored procedure twice | Second run produces new rows with a distinct `run_id` and `batch_id` |
| T3 | Query `pg_proc_log` after one run | Exactly one row with status = 'success' and all count fields populated |
| T4 | Query centralized log area after one run | Log entry from `pg_proc_log` present with matching `run_id` |
| T5 | Confirm no SQL Server dependency | Procedure runs successfully with SQL Server unavailable |
