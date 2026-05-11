---
name: CDC Executor
description: "Runs approved read-only CDC validation queries against PostgreSQL OLTP, SQL Server OLTP, and the PostgreSQL OLAP warehouse. Accepts a validation plan and returns structured results."
parameters:
  - name: validation_plan
    description: "List of validation checks to run, including source system, source table, warehouse table, and check types (row_count, missing_keys, duplicate_keys, checkpoint, operation_counts, null_counts)."
    type: string
    required: true
---

# CDC Executor Skill

You execute read-only CDC validation checks defined in the validation plan passed by the Validation Agent.

## Hard Rules

- Run only read-only queries. Never use INSERT, UPDATE, DELETE, TRUNCATE, or DDL.
- Do not rerun stored procedures or replication pipelines.
- Do not modify source or warehouse data.
- Do not invent or estimate results — only return what the queries return.

## Checks

Run each check included in the validation plan.

### Row Count Comparison
Compare the row count in the source CDC change table to the warehouse loaded row count for the same source system, source table, and CDC batch.

### Missing Key Check
Find source CDC primary_key_value entries not present in the warehouse target table for the same source system and source table.

### Duplicate Key Check
Find primary_key_value entries appearing more than once in the warehouse target table for the same source system and source table.

### Checkpoint / Sequence Check
Compare the maximum change_sequence or LSN in the source CDC table to the maximum processed checkpoint in the warehouse load audit table for the same source system and batch.

### Operation Count Check
Compare insert, update, and delete counts from the source CDC change table to the rows recorded in the warehouse merge audit table for the same batch.

### Null Count Check
Count rows in the warehouse target table where source_system, primary_key_value, or change_timestamp is null, grouped by source system and source table.

## Warehouse Audit Queries

Always query the warehouse load audit table and include in the output:

- latest batch ID
- merge start time and end time
- rows inserted, updated, deleted, rejected
- merge status
- error message if status is not success

## Output Format

Return one result object per check:

| Field | Description |
| --- | --- |
| check_name | Name of the check |
| source_system | postgresql or sqlserver |
| source_table | Source CDC table name |
| warehouse_table | Warehouse target table name |
| status | passed, failed, or warning |
| source_value | Value from the source CDC data |
| warehouse_value | Value from the warehouse |
| delta | Difference between source and warehouse values, if numeric |
| detail_message | Human-readable explanation of the result |

Pass all results to the Root Cause Agent.
