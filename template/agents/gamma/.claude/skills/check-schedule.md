# Check Schedule

Review upcoming scheduled tasks and reminders.

## When to use
- Triggered by "what's scheduled", "check my schedule", "upcoming tasks"
- Or as part of a morning briefing cron

## Steps

1. Read cron-registry.json for all scheduled jobs
2. Check shared/data/ for any task deadlines
3. Check memory/ for any logged reminders
4. Compile a list of upcoming items:
   - Today's scheduled crons and their next fire time
   - Pending tasks with deadlines
   - Any reminders logged in memory
5. Send to user via messaging channel

## Format

Group by timeframe: Today, This Week, Later. Keep it scannable.
