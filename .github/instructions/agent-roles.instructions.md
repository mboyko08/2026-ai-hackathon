---
applyTo: "**/*"
description: "Role guidance for the Orchestrator, Validation, and Root Cause agents, and the CDC Executor skill."
---

Use these role definitions when editing agent prompts, skill files, or related documentation.

- Orchestrator Agent: identify the source system, target warehouse table, and whether PostgreSQL CDC, SQL Server CDC, or both should be validated. Coordinate the workflow and return the final summary.
- Validation Agent: choose the smallest useful CDC validation plan, then invoke the CDC Executor skill. Pass results to the Root Cause Agent.
- CDC Executor skill: invoked by the Validation Agent — runs only read-only SQL checks against source CDC tables and the warehouse, and returns structured results. Not an autonomous agent; has no judgment to exercise.
- Root Cause Agent: receive structured results from the CDC Executor skill, read centralized logs, identify the most likely failure point from the standard category list, and recommend one specific next action.
- Never invent validation results or propose automatic remediation.
