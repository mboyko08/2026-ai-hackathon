# Agent Instructions

## Project Purpose

This project builds a simple Azure-based CDC data quality validation system for a hackathon.

The system compares CDC data from OLTP source databases to replicated data in a PostgreSQL OLAP warehouse target.

The OLTP source data must be generated only by stored procedures.

## Architecture Summary

The system includes:

- PostgreSQL OLTP source database
- SQL Server OLTP source database
- PostgreSQL OLAP warehouse target database
- Stored procedures that generate new sample data in both OLTP source databases
- CDC/change data from both OLTP sources
- CDC replication pipeline from OLTP sources into the PostgreSQL warehouse
- Centralized Azure log area for database logs and pipeline replication logs
- Four simple agents:
  - Front Door Agent
  - Validation Agent
  - Executor Agent
  - Root Cause Agent

## Agent Responsibilities

### Front Door Agent

Receives the user request and starts the validation workflow.

The Front Door Agent should:

- Identify which source system and warehouse table need validation.
- Confirm whether the validation should cover PostgreSQL CDC data, SQL Server CDC data, or both.
- Ask the Validation Agent to create a validation plan.
- Return the final validation summary to the user.
- Keep responses simple and clear.

### Validation Agent

Decides which CDC validation checks should run.

The Validation Agent should:

- Select checks such as CDC row count, missing keys, duplicate keys, CDC checkpoint freshness, operation counts, and null count checks.
- Use table configuration when available.
- Send the validation plan to the Executor Agent.
- Avoid creating overly complex rules unless requested.

### Executor Agent

Runs the approved validation checks.

The Executor Agent should:

- Run only read-only validation queries.
- Compare PostgreSQL OLTP CDC data to the PostgreSQL OLAP warehouse.
- Compare SQL Server OLTP CDC data to the PostgreSQL OLAP warehouse.
- Query warehouse load audit tables.
- Store validation results.
- Return structured results to the Root Cause Agent.
- Never modify source or warehouse data during validation.

### Root Cause Agent

Explains why validation failed and recommends what to fix.

The Root Cause Agent should:

- Review validation results.
- Read centralized database logs and pipeline logs from Azure.
- Determine whether source stored procedures generated records successfully.
- Determine whether CDC capture found the expected changes.
- Determine whether the replication pipeline extracted, transformed, and loaded the expected changes.
- Identify likely causes of replication issues.
- Explain whether the issue appears to come from:
  - stored procedure data generation
  - source database issue
  - CDC capture issue
  - replication pipeline issue
  - transformation issue
  - warehouse load issue
  - stale CDC checkpoint
  - duplicate data
  - missing keys
  - delete handling
  - null handling
- Recommend a clear next action.

## Required MVP Validation Checks

The system should support these checks first:

1. CDC row count comparison
2. Missing primary key check
3. Duplicate primary key check
4. CDC checkpoint or max sequence check
5. Insert/update/delete operation count comparison
6. Null count comparison for important columns

## Log Awareness

Database logs and pipeline logs should be loaded into one centralized Azure log area.

The Root Cause Agent must use these logs when explaining failures.

The Root Cause Agent should check:

- Whether the PostgreSQL stored procedure generated records successfully.
- Whether the SQL Server stored procedure generated records successfully.
- Whether CDC capture recorded the generated inserts, updates, and deletes.
- Whether the replication pipeline started and completed.
- Whether the pipeline failed, skipped rows, or partially loaded data.
- Whether the warehouse load completed successfully.
- Whether errors mention schema changes, type conversion issues, timeout issues, duplicate keys, null constraint failures, or CDC checkpoint issues.

## Data Safety Rules

All validation queries should be read-only.

Agents must not:

- Drop tables
- Delete records
- Update source records
- Update warehouse records
- Modify stored procedures
- Rerun stored procedures without approval
- Rerun replication jobs without approval
- Invent validation results

If data needs to be fixed, agents should recommend the fix instead of applying it automatically.

## Expected Output Style

Agent responses should be concise and structured.

A validation response should include:

- Overall status
- Source system
- Target warehouse table
- CDC checkpoint or batch
- Checks that passed
- Checks that failed
- Relevant log evidence
- Likely root cause
- Recommended next action

## Example User Request

Validate the latest CDC replication from OLTP to the warehouse.

## Example Agent Response

Validation failed.

Source systems:

- PostgreSQL OLTP
- SQL Server OLTP

Target system:

- PostgreSQL OLAP warehouse

Passed checks:

- CDC checkpoint freshness
- Duplicate key check

Failed checks:

- CDC row count comparison
- Missing key check

Relevant log evidence:

The pipeline logs show that the SQL Server CDC extract completed with skipped rows. The missing keys appear to be from the latest generated source batch.

Likely root cause:

The issue is likely in the SQL Server CDC replication pipeline or warehouse load step, not in the stored procedure data generation.

Recommended next action:

Review the failed pipeline run, confirm why rows were skipped, and rerun the affected CDC batch after the pipeline issue is corrected.
