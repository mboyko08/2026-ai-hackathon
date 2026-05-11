# CDC Data Quality Validator Project Plan

## Project Goal

Build a simple Azure-based data quality validator that compares CDC data from OLTP source databases against replicated data in a PostgreSQL OLAP warehouse.

The OLTP source data is generated only by stored procedures. There is no public API ingestion in this version.

## Architecture Summary

The system includes:

- Azure Database for PostgreSQL as one OLTP source
- Azure SQL Database or SQL Server as another OLTP source
- Stored procedures in each OLTP database that generate new transactional source data
- CDC/change tables that capture inserts, updates, and deletes from each OLTP source
- A CDC replication pipeline that loads changes into a PostgreSQL OLAP warehouse
- A centralized Azure logging area for database logs and pipeline logs
- Four agents:
  - Front Door Agent
  - Validation Agent
  - Executor Agent
  - Root Cause Agent

## Scope for Two-Day Hackathon

### In Scope

- Create PostgreSQL OLTP source database
- Create SQL Server OLTP source database
- Create PostgreSQL OLAP warehouse database
- Create stored procedures that generate new sample source records
- Enable or simulate CDC data capture
- Replicate CDC changes into the PostgreSQL warehouse
- Run validation checks against source CDC data and warehouse data
- Store validation results
- Centralize database and pipeline logs
- Use the Root Cause Agent to review logs and explain failures

### Out of Scope

- Public API ingestion
- Full production-grade CDC framework
- Complex security model
- Automatic production remediation
- Large-scale historical backfills
- Autonomous fixes without human approval

## Data Generation Design

Each OLTP source should generate data through stored procedures.

The PostgreSQL and SQL Server generators should be fully independent. Each one owns its own sample data model, execution schedule, logging, and change sequence.

Shared rules:

- Do not call one source generator from the other.
- Do not depend on shared runtime state across databases.
- Keep the generated business keys stable enough for CDC and merge testing.
- Emit a run identifier and batch identifier for every execution.
- Write generator results to the source database log table and forward them to the central log area.

### PostgreSQL OLTP Stored Procedure

Purpose:

- Insert new source records
- Update existing source records
- Optionally soft-delete or delete records
- Write a stored procedure execution record to a database log table

Example procedure behavior:

- Generate 10 new customer, permit, claim, or transaction records
- Update 3 existing records
- Mark 1 record as deleted
- Record start time, end time, rows inserted, rows updated, rows deleted, and status

Design notes:

- Use PostgreSQL-native schema objects and sequences.
- Keep the generator focused on PostgreSQL-specific row shapes and business rules.
- Write a source-specific run record that includes the CDC batch identifier.
- Forward the stored procedure log entry to the central log area after each run.

### SQL Server OLTP Stored Procedure

Purpose:

- Insert new source records
- Update existing source records
- Optionally soft-delete or delete records
- Write a stored procedure execution record to a database log table

Example procedure behavior:

- Generate 10 new source records
- Update 3 existing records
- Mark 1 record as deleted
- Record start time, end time, rows inserted, rows updated, rows deleted, and status

Design notes:

- Use SQL Server-specific tables, identity columns, and transaction patterns.
- Keep the generator independent from the PostgreSQL generator.
- Write a source-specific run record that includes the CDC batch identifier.
- Forward the stored procedure log entry to the central log area after each run.

## CDC Data Design

CDC data should represent changes from the OLTP source systems.

### Required CDC Fields

Use a common CDC shape where possible:

| Field | Purpose |
| --- | --- |
| source_system | Identifies PostgreSQL or SQL Server source |
| source_table | Source table name |
| primary_key_value | Business or technical primary key |
| operation_type | Insert, update, or delete |
| change_sequence | CDC ordering value |
| change_timestamp | When the change occurred |
| extracted_at | When the pipeline extracted the change |
| loaded_at | When the warehouse loaded the change |

## Replication Pipeline

The replication pipeline should:

1. Read CDC data from PostgreSQL OLTP.
2. Read CDC data from SQL Server OLTP.
3. Standardize CDC fields into a common structure.
4. Load changes into PostgreSQL warehouse staging tables.
5. Merge changes into warehouse target tables.
6. Write pipeline execution details to the centralized log area.

## Warehouse Merge Process

The warehouse merge process should be deterministic, idempotent, and auditable.

Merge design:

- Land raw CDC rows in staging first.
- Deduplicate staging rows by source system, source table, primary key, and change sequence.
- Apply inserts, updates, and deletes in a single controlled merge step.
- Preserve the latest source change for each business key.
- Treat deletes explicitly rather than inferring them from missing records.
- Record row counts for inserted, updated, deleted, and rejected rows.
- Write a warehouse merge audit row for each batch.

Recommended merge order:

1. Validate staging data shape and required columns.
2. Deduplicate by source key and change sequence.
3. Apply deletes.
4. Apply updates.
5. Apply inserts.
6. Record final loaded counts in the warehouse audit tables.

Warehouse merge logging:

- Merge start time
- Merge end time
- Source system
- Source table
- Target table
- CDC batch or checkpoint
- Insert count
- Update count
- Delete count
- Rejected count
- Merge status
- Error message, if any

## Centralized Logging

All logs should be loaded into one centralized Azure logging area.

Recommended target:

- Azure Log Analytics Workspace
- Azure Storage account log container
- PostgreSQL warehouse audit tables, if a simpler implementation is needed
- Warehouse merge audit tables
- Warehouse data load logs
- Warehouse validation result logs

### Database Logs

Database logs should include:

- Stored procedure name
- Source system
- Start time
- End time
- Rows inserted
- Rows updated
- Rows deleted
- Status
- Error message, if any

### Pipeline Logs

Pipeline logs should include:

- Pipeline run ID
- Source system
- Source table
- Target table
- Extracted row count
- Loaded row count
- Rejected row count
- Start time
- End time
- Status
- Error message, if any

### Warehouse Logs

Warehouse logs should include:

- Warehouse load run ID
- Merge batch ID
- Source system
- Source table
- Target table
- Rows staged
- Rows merged
- Rows rejected
- Rows inserted
- Rows updated
- Rows deleted
- Start time
- End time
- Status
- Error message, if any

Warehouse logs must also be forwarded to the central log area.

## Agent Design

## 1. Front Door Agent

Receives the user request and starts the validation workflow.

Example request:

> Validate the latest CDC replication from OLTP to the PostgreSQL warehouse.

Responsibilities:

- Identify the validation scope
- Send the request to the Validation Agent
- Return the final summary to the user

## 2. Validation Agent

Creates the validation plan.

Responsibilities:

- Select validation checks
- Determine which source CDC tables and warehouse tables to compare
- Send the plan to the Executor Agent

Recommended checks:

- CDC source row count compared to warehouse loaded row count
- Missing key check
- Duplicate key check
- Max CDC sequence/checkpoint comparison
- Insert/update/delete operation count comparison
- Null count comparison for important fields

## 3. Executor Agent

Runs approved read-only checks.

Responsibilities:

- Query PostgreSQL OLTP CDC data
- Query SQL Server CDC data
- Query PostgreSQL warehouse data
- Query warehouse audit tables
- Store validation results
- Return structured results to the Root Cause Agent

Rules:

- Use read-only validation queries
- Do not modify source or warehouse records
- Do not rerun stored procedures or pipelines automatically

## 4. Root Cause Agent

Explains validation failures and recommends fixes.

Responsibilities:

- Review validation results
- Read centralized database logs
- Read centralized pipeline logs
- Identify likely failure point
- Recommend a clear next step

The Root Cause Agent should determine whether the likely issue came from:

- Stored procedure data generation
- CDC capture
- CDC extract
- CDC transformation
- Warehouse load
- Merge logic
- Duplicate handling
- Delete handling
- Stale pipeline checkpoint
- Type conversion issue
- Null handling issue

## MVP Validation Checks

| Check | Purpose |
| --- | --- |
| CDC row count comparison | Confirms the warehouse loaded the same number of CDC changes from each source |
| Missing key check | Finds source CDC keys that are missing from the warehouse |
| Duplicate key check | Finds duplicate target records |
| CDC sequence/checkpoint check | Confirms the warehouse processed the latest source CDC changes |
| Operation count check | Confirms insert/update/delete counts match expected pipeline results |
| Null count check | Detects unexpected null changes in important target columns |

## Demo Scenario

1. Run PostgreSQL stored procedure to generate new OLTP records.
2. Run SQL Server stored procedure to generate new OLTP records.
3. Capture or simulate CDC changes in both OLTP systems.
4. Run the CDC replication pipeline into the PostgreSQL warehouse.
5. Intentionally introduce one mismatch, such as skipping a CDC batch or creating duplicate target keys.
6. Ask the Front Door Agent to validate the latest CDC replication.
7. Validation Agent selects checks.
8. Executor Agent runs checks.
9. Root Cause Agent reads centralized logs and explains what failed.
10. Generate a validation report with the recommended fix.

## Success Criteria

The demo is successful if the system can:

- Generate source data using stored procedures only
- Capture or simulate CDC changes
- Replicate CDC data to the PostgreSQL warehouse
- Run validation checks
- Detect at least one controlled mismatch
- Use centralized logs to explain the likely root cause
- Produce a clear recommended fix
