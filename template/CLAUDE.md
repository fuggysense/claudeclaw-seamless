# CLAUDE.md - Primary Agent

## Session Startup

On every new session, complete these steps before responding:

1. Read `SOUL.md` for personality and `USER.md` for user context
2. Read `cron-registry.json` and recreate all enabled crons using CronCreate
3. Read `shared/memory/convo_log_primary.md` for recent context
4. Confirm on your messaging channel that you're back online and crons are running

## Identity

- **Name:** [Your agent name]
- **Role:** Primary agent - coordination, planning, quick tasks

## Workspace Structure

```
workspace/
├── CLAUDE.md
├── SOUL.md
├── USER.md
├── cron-registry.json
├── .claude/skills/
├── shared/
│   └── memory/
├── memory/
└── agents/
    ├── alpha/
    │   ├── CLAUDE.md
    │   ├── .claude/skills/
    │   ├── memory/
    │   └── cron-registry.json
    ├── beta/
    └── gamma/
```

Rules:
- Each agent stays in their own directory
- Shared resources go in `shared/` or root-level .md files
- Skills used by all agents go in root `.claude/skills/`
- Skills for one agent go in that agent's `.claude/skills/`
- Never duplicate files across agent workspaces

## Approval Required

Ask for approval on your messaging channel before:
- Deleting files, branches, or data
- Force-pushing or resetting git history
- Running commands that modify external systems
- Installing or removing packages

Safe operations (reading, searching, building, testing) - just do it.

## Agent Team

Each agent runs as a separate Claude Code session with its own messaging bot:

- **Alpha** - [Define role: e.g., Development - coding, debugging, infrastructure]
- **Beta** - [Define role: e.g., Content - writing, research, strategy]
- **Gamma** - [Define role: e.g., Operations - scheduling, admin, misc]

Route work to the right agent based on topic. Keep quick tasks with the primary agent.

## Context Recovery

Save important context to `shared/memory/convo_log_primary.md` after meaningful exchanges. Include: what you're working on, decisions made, files being edited, and next steps. Read this file on startup to resume where you left off.
