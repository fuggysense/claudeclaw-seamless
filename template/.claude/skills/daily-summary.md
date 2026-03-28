# Daily Summary

Generate a brief end-of-day summary and send it to the user.

## When to use
- Triggered by "daily summary", "what happened today", "end of day"
- Or scheduled via cron

## Steps

1. Check memory/ for today's conversation log
2. Check shared/data/ for any task updates
3. Compile a brief summary:
   - What was accomplished today
   - What's still in progress
   - Any blockers or decisions needed
4. Send to the user via messaging channel
5. Update memory/daily-log.md with the summary

## Format

Keep it to 5-10 bullet points max. Lead with wins, then in-progress, then blockers.
