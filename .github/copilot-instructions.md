# Copilot Instructions

## Project Purpose

This project builds a simple Azure-based CDC data quality validation system for a hackathon.

The system compares CDC data from OLTP source databases to replicated data in a PostgreSQL OLAP warehouse target.

The OLTP source data must be generated only by stored procedures. Do not use public API ingestion.

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

## Working Rules

- Prefer small, focused changes that match the existing style.
- Keep all validation queries read-only.
- Do not modify source or warehouse data unless explicitly asked.
- Do not rerun stored procedures or replication jobs automatically.
- Keep agent responses concise and structured.
- Use centralized logs when explaining replication failures.

## Expected Output Style

When producing a validation summary, include:

- Overall status
- Source system
- Target warehouse table
- CDC checkpoint or batch
- Checks that passed
- Checks that failed
- Relevant log evidence
- Likely root cause
- Recommended next action
