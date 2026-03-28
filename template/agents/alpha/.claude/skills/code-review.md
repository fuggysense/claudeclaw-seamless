# Code Review

Review code changes and provide feedback.

## When to use
- Triggered by "review this", "code review", "check my code"
- When the user shares a file or diff for review

## Steps

1. Read the file(s) or diff provided
2. Check for:
   - Bugs or logic errors
   - Security issues (injection, exposed secrets, unsafe defaults)
   - Code style consistency
   - Missing error handling at system boundaries
3. Provide feedback organized by severity:
   - Blockers (must fix)
   - Suggestions (should fix)
   - Nits (nice to have)
4. Keep feedback actionable - say what to change, not just what's wrong

## Format

Use bullet points grouped by severity. Include file paths and line numbers where relevant.
