# Task 09 — CDC Executor Skill

## Objective

Configure the CDC Executor skill to run the six standard read-only validation queries against source CDC tables and the warehouse, and return structured results.

## Deliverables

- Updated `cdc-executor.skill.md` with complete query definitions for all six checks
- SQL query templates for PostgreSQL and SQL Server sources
- Structured output format validated against the test cases below

## Responsibilities

- Accept a validation plan from the Validation Agent.
- For each check in the plan, run the appropriate read-only query.
- Query the warehouse merge audit table for batch context.
- Return one structured result object per check.
- Never modify source or warehouse data.

## Query Definitions

### row_count
```sql
-- Source CDC
SELECT COUNT(*) AS source_count FROM <source_cdc_table>
WHERE source_system = '<source_system>' AND batch_id = '<batch_id>';

-- Warehouse
SELECT COUNT(*) AS warehouse_count FROM <warehouse_table>
WHERE source_system = '<source_system>' AND batch_id = '<batch_id>';
```

### missing_keys
```sql
SELECT s.primary_key_value FROM <source_cdc_table> s
LEFT JOIN <warehouse_table> w
  ON s.primary_key_value = w.primary_key_value
  AND s.source_system = w.source_system
WHERE w.primary_key_value IS NULL
  AND s.source_system = '<source_system>';
```

### duplicate_keys
```sql
SELECT primary_key_value, COUNT(*) AS cnt FROM <warehouse_table>
WHERE source_system = '<source_system>'
GROUP BY primary_key_value
HAVING COUNT(*) > 1;
```

### checkpoint
```sql
-- Source max change_sequence
SELECT MAX(change_sequence) AS source_max FROM <source_cdc_table>
WHERE source_system = '<source_system>';

-- Warehouse last processed checkpoint
SELECT MAX(batch_id) AS last_checkpoint FROM wh_merge_audit
WHERE source_system = '<source_system>';
```

### operation_counts
```sql
-- Source
SELECT operation_type, COUNT(*) AS cnt FROM <source_cdc_table>
WHERE source_system = '<source_system>' AND batch_id = '<batch_id>'
GROUP BY operation_type;

-- Warehouse audit
SELECT rows_inserted, rows_updated, rows_deleted FROM wh_merge_audit
WHERE source_system = '<source_system>' AND batch_id = '<batch_id>';
```

### null_counts
```sql
SELECT
  SUM(CASE WHEN source_system IS NULL THEN 1 ELSE 0 END) AS null_source_system,
  SUM(CASE WHEN primary_key_value IS NULL THEN 1 ELSE 0 END) AS null_primary_key,
  SUM(CASE WHEN change_timestamp IS NULL THEN 1 ELSE 0 END) AS null_change_timestamp
FROM <warehouse_table>
WHERE source_system = '<source_system>';
```

## Output Format (per check)

| Field | Description |
| --- | --- |
| `check_name` | Name of the check |
| `source_system` | `postgresql` or `sqlserver` |
| `source_table` | Source CDC table |
| `warehouse_table` | Warehouse target table |
| `status` | `passed`, `failed`, or `warning` |
| `source_value` | Value from the source |
| `warehouse_value` | Value from the warehouse |
| `delta` | Numeric difference (if applicable) |
| `detail_message` | Human-readable explanation |

## Acceptance Criteria

- [ ] Skill executes all six checks when all are included in the plan
- [ ] Each check returns a result object with all required output fields
- [ ] `status = 'passed'` when source and warehouse values match
- [ ] `status = 'failed'` when a mismatch is detected (e.g. row count delta > 0, missing keys found, duplicates found)
- [ ] Skill does not execute INSERT, UPDATE, DELETE, TRUNCATE, or DDL
- [ ] Skill does not rerun stored procedures or pipeline jobs
- [ ] Skill returns results only from actual query output — no invented values

## Test Cases

| # | Test | Expected Result |
| --- | --- | --- |
| T1 | Run all six checks after a clean full pipeline run | All six checks return status = 'passed' |
| T2 | Skip one CDC batch; run `row_count` check | `row_count` returns status = 'failed' with delta > 0 |
| T3 | Insert a duplicate key into the warehouse; run `duplicate_keys` check | `duplicate_keys` returns status = 'failed' with the duplicate key listed |
| T4 | Load records but do not advance checkpoint; run `checkpoint` check | `checkpoint` returns status = 'failed' |
| T5 | Null out `primary_key_value` on one warehouse row; run `null_counts` check | `null_counts` returns status = 'failed' with `null_primary_key = 1` |
| T6 | Run skill with a write query in the plan | Query rejected; no data modified |
