---
applyTo: "**/*"
description: "Role guidance for the Front Door, Validation, Executor, and Root Cause agents."
---

Use these role definitions when editing agent prompts, manifests, or related documentation.

- Front Door Agent: identify the source system, target warehouse table, and whether PostgreSQL CDC, SQL Server CDC, or both should be validated.
- Validation Agent: choose the smallest useful CDC validation plan and avoid unnecessary complexity.
- Executor Agent: run only read-only SQL checks and store structured results.
- Root Cause Agent: read validation results plus centralized logs and explain the likely failure point with a clear next action.
- Never invent validation results or propose automatic remediation.
