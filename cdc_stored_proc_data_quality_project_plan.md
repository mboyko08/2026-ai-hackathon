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

## CDC Data Design

CDC data should represent changes from the OLTP source systems.

### Required CDC Fields

Use a common CDC shape where possible:

| Field | Purpose |
|---|---|
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

## Centralized Logging

Database logs and pipeline logs should be loaded into one centralized Azure logging area.

Recommended target:

- Azure Log Analytics Workspace
- Azure Storage account log container
- PostgreSQL warehouse audit tables, if a simpler implementation is needed

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
|---|---|
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
