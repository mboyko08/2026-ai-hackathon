# Agent Instructions

## Project Purpose

This project builds a simple Azure-based data quality validation system for a hackathon.

The system compares data from OLTP source databases to a PostgreSQL OLAP warehouse target. It validates whether replicated data matches the source and uses agents to explain mismatches and recommend fixes.

## Architecture Summary

The system includes:

- PostgreSQL OLTP source database
- SQL Server OLTP source database
- PostgreSQL OLAP warehouse target database
- Stored procedures that generate new sample data in both OLTP source databases
- Data pipeline that replicates OLTP data into the OLAP warehouse
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
- Ask the Validation Agent to create a validation plan.
- Return the final validation summary to the user.
- Keep responses simple and clear.

### Validation Agent

Decides which validation checks should run.

The Validation Agent should:

- Select checks such as row count, missing keys, duplicate keys, freshness, and null count checks.
- Use table configuration when available.
- Send the validation plan to the Executor Agent.
- Avoid creating overly complex rules unless requested.

### Executor Agent

Runs the approved validation checks.

The Executor Agent should:

- Run only read-only validation queries.
- Compare PostgreSQL OLTP data to the PostgreSQL OLAP warehouse.
- Compare SQL Server OLTP data to the PostgreSQL OLAP warehouse.
- Store validation results.
- Return structured results to the Root Cause Agent.
- Never modify source or warehouse data during validation.

### Root Cause Agent

Explains why validation failed and recommends what to fix.

The Root Cause Agent should:

- Review validation results.
- Read centralized database and pipeline logs from Azure.
- Identify likely causes of replication issues.
- Explain whether the issue appears to come from:
  - source data generation
  - source database issue
  - replication pipeline issue
  - transformation issue
  - warehouse load issue
  - stale data
  - duplicate data
  - missing keys
  - null handling
- Recommend a clear next action.

## Required MVP Validation Checks

The system should support these checks first:

1. Row count comparison
2. Missing primary key check
3. Duplicate primary key check
4. Freshness or max timestamp check
5. Null count comparison for important columns

## Log Awareness

Database logs and pipeline logs should be loaded into one centralized Azure log area.

The Root Cause Agent must use these logs when explaining failures.

The Root Cause Agent should check:

- Whether the source stored procedure generated records successfully.
- Whether the replication pipeline started and completed.
- Whether the pipeline failed, skipped rows, or partially loaded data.
- Whether the warehouse load completed successfully.
- Whether errors mention schema changes, type conversion issues, timeout issues, duplicate keys, or null constraint failures.

## Data Safety Rules

All validation queries should be read-only.

Agents must not:

- Drop tables
- Delete records
- Update source records
- Update warehouse records
- Modify stored procedures
- Rerun production jobs without approval
- Invent validation results

If data needs to be fixed, agents should recommend the fix instead of applying it automatically.

## Expected Output Style

Agent responses should be concise and structured.

A validation response should include:

- Overall status
- Source system
- Target warehouse table
- Checks that passed
- Checks that failed
- Likely root cause
- Recommended next action

## Example User Request

Validate the latest replicated warehouse data.

## Example Agent Response

Validation failed.

Source system: PostgreSQL OLTP  
Target system: PostgreSQL OLAP warehouse  
Table: permits

Passed checks:

- Freshness check
- Duplicate key check

Failed checks:

- Row count comparison
- Missing key check

Likely root cause:

The pipeline logs show that the replication job completed with skipped rows. The missing keys appear to be from the latest generated source batch, so the issue is likely in the replication pipeline or warehouse load step.

Recommended next action:

Review the failed pipeline run, confirm why rows were skipped, and rerun the affected batch after the pipeline issue is corrected.
