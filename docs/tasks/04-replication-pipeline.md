# Task 04 — Replication Pipeline

## Objective

Build a pipeline that reads CDC change records from both OLTP sources, standardizes them into the common CDC shape, loads them into PostgreSQL warehouse staging tables, and writes pipeline execution details to the centralized log area.

## Deliverables

- Pipeline script or job that extracts CDC changes from PostgreSQL and SQL Server
- Standardization step that maps source-specific fields to the common CDC shape
- Load step that inserts standardized records into a warehouse staging table
- Pipeline log entry written to the centralized log area per run

## Pipeline Steps

1. Read new CDC records from the PostgreSQL OLTP change table (since last checkpoint).
2. Read new CDC records from the SQL Server OLTP change table (since last checkpoint).
3. Standardize all records to the common CDC field shape.
4. Set `extracted_at` timestamp on each record.
5. Insert records into the warehouse staging table.
6. Write a pipeline log row to the centralized log area.

## Checkpoint Tracking

- Track the last processed `change_sequence` per source system and source table.
- On each run, extract only records with `change_sequence` greater than the last checkpoint.
- Update the checkpoint after a successful load.

## Pipeline Log Fields

| Field | Description |
| --- | --- |
| `pipeline_run_id` | Unique identifier for this pipeline run |
| `source_system` | `postgresql` or `sqlserver` |
| `source_table` | Source CDC table name |
| `target_table` | Warehouse staging table name |
| `extracted_row_count` | Rows read from the source CDC table |
| `loaded_row_count` | Rows successfully written to staging |
| `rejected_row_count` | Rows rejected during standardization or load |
| `start_time` | Pipeline run start |
| `end_time` | Pipeline run end |
| `status` | `success` or `error` |
| `error_message` | Error detail if status is `error` |

## Acceptance Criteria

- [ ] Pipeline runs without error after both stored procedures have been executed
- [ ] All CDC records from both sources appear in the warehouse staging table with `extracted_at` populated
- [ ] `loaded_at` is null at this stage (set during warehouse merge)
- [ ] Pipeline log row written to centralized log area with all required fields populated
- [ ] Checkpoint advances after each successful run — re-running the pipeline does not re-load already-processed records
- [ ] Rejected rows (if any) are counted and logged; pipeline does not silently drop records

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run pipeline after both stored procedures | Staging table contains 28 rows (14 from each source) |
| T2 | Run pipeline again without new stored procedure runs | 0 new rows loaded; checkpoint unchanged |
| T3 | Run stored procedures again; run pipeline | Only new change records since last checkpoint are loaded |
| T4 | Query centralized log area after pipeline run | One log row per source system with correct row counts and status = 'success' |
| T5 | Introduce a malformed CDC record; run pipeline | Rejected row count > 0 in pipeline log; malformed record not in staging table |
| T6 | Query staging table for `extracted_at` | All rows have non-null `extracted_at`; all rows have null `loaded_at` |
