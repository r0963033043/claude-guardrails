---
description: Review changed code for correctness, security, clarity, and test coverage
argument-hint: [optional path or PR ref]
---

Conduct a code review of the current change set.

## Scope resolution

1. If an argument is provided, treat it as a file path, directory, or PR reference and review that.
2. Otherwise, review the diff in this order of preference:
   - Staged changes (`git diff --cached`)
   - Unstaged working-tree changes (`git diff`)
   - Most recent commit (`git show HEAD`)

## Review criteria

- **Correctness** — logic errors, unhandled edge cases, off-by-ones, race conditions, incorrect API usage.
- **Security** — injection vectors, authz/authn gaps, unsafe deserialization, secret leakage, path traversal.
- **Sensitive data** — block the change if the diff introduces apparent secrets (API keys, tokens, private keys, passwords, connection strings), personal/customer data, internal hostnames or IPs, or files matching `.claude/sensitive-files.txt`. Treat this as an automatic `must-fix` and refuse to recommend `ship` until removed and (for already-committed secrets) rotated.
- **Clarity** — misleading or stale names, dead code, comments that contradict the code.
- **Tests** — whether behavior introduced or changed is covered; flag untested branches.
- **Consistency** — fit with surrounding code's conventions; do not impose unrelated style changes.

## Output format

- One-line verdict: `ship` / `needs fixes` / `needs discussion`.
- Findings grouped by severity: `must-fix`, `should-fix`, `nit`.
- Each finding: `path:line — issue — suggested fix` (fix can be a short sentence or a code block).
- Skip the nit section entirely if the code is clean. Do not manufacture findings to look thorough.
- Do not restate what the change does unless the verdict depends on it.