# Task 05 — Warehouse and Merge Process

## Objective

Create the PostgreSQL OLAP warehouse target table and implement a deterministic, idempotent merge process that applies CDC changes from the staging table into the target table and writes a merge audit row per batch.

## Deliverables

- Warehouse target table with CDC tracking columns
- Merge procedure or script that deduplicates staging records and applies inserts, updates, and deletes
- Warehouse merge audit table `wh_merge_audit`
- Merge audit rows forwarded to the centralized log area

## Merge Design

1. Validate staging records — confirm required columns are non-null.
2. Deduplicate staging rows by `(source_system, source_table, primary_key_value)` — keep the row with the highest `change_sequence`.
3. Apply deletes first: remove target rows where `operation_type = 'delete'`.
4. Apply updates: update target rows where `operation_type = 'update'`.
5. Apply inserts: insert target rows where `operation_type = 'insert'` and the key does not already exist.
6. Set `loaded_at` on all affected rows.
7. Write one row to `wh_merge_audit` with final counts.

## Warehouse Target Table Columns

Include all standard CDC fields plus any source-specific payload columns. At minimum:

- `source_system`
- `source_table`
- `primary_key_value`
- `operation_type` (last applied operation)
- `change_sequence`
- `change_timestamp`
- `extracted_at`
- `loaded_at`

## Merge Audit Fields (`wh_merge_audit`)

| Field | Description |
| --- | --- |
| `merge_run_id` | Unique identifier for this merge run |
| `batch_id` | CDC batch or checkpoint identifier |
| `source_system` | Source system merged |
| `source_table` | Source table merged |
| `target_table` | Warehouse target table |
| `rows_staged` | Rows in staging before merge |
| `rows_merged` | Rows processed in merge |
| `rows_inserted` | Rows inserted into target |
| `rows_updated` | Rows updated in target |
| `rows_deleted` | Rows deleted from target |
| `rows_rejected` | Rows that failed validation |
| `merge_start_time` | Merge start |
| `merge_end_time` | Merge end |
| `status` | `success` or `error` |
| `error_message` | Error detail if status is `error` |

## Acceptance Criteria

- [ ] Warehouse target table exists with all required columns
- [ ] After merge: insert count + update count + delete count matches the staging row count (minus rejected)
- [ ] Running the merge twice on the same staging data produces the same target state (idempotent)
- [ ] Deletes remove the correct rows from the target table
- [ ] `loaded_at` is set on all merged rows
- [ ] `wh_merge_audit` contains one row per merge run with all count fields non-null
- [ ] Merge audit row forwarded to centralized log area

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run merge after one pipeline load | Target table contains merged rows; `wh_merge_audit` has one row with correct counts |
| T2 | Run merge twice on same staging data | Target table state is identical after both runs (idempotent) |
| T3 | Stage a delete record; run merge | Corresponding row removed from target; `rows_deleted = 1` in audit |
| T4 | Stage a duplicate key (two updates for same key) | Only the record with the higher `change_sequence` survives in target |
| T5 | Stage a record with a null `primary_key_value` | Record rejected; `rows_rejected` incremented; target table unchanged |
| T6 | Query `loaded_at` on merged rows | All merged rows have non-null `loaded_at` |
| T7 | Query centralized log area after merge | Merge audit row present with matching `merge_run_id` |
