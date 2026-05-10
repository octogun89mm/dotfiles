---
description: Review code changes for correctness, regressions, and maintainability.
argument-hint: "[scope]"
---

Review the code changes in this repository.

If arguments were provided, use them as the review scope or files to inspect.
Do not modify files.

Process:
1. Inspect the relevant diff (`git diff`, or the provided scope).
2. Read the touched files.
3. Check correctness, regressions, UX/layout issues, performance, and readability.
4. Be specific and cite file paths and line numbers.

Output format:
## Files Reviewed
- `path/to/file` (lines X-Y)

## Critical
- ...

## Warnings
- ...

## Suggestions
- ...

## Summary
1-3 sentences.
