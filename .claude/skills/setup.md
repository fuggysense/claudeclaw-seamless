---
name: setup
description: Guided setup for ClaudeClaw Seamless — scaffolds workspace + configures Telegram bot with auto-pairing. Run this when someone first clones the repo.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /setup — ClaudeClaw Seamless Installer

Interactive guided setup. Walk the user through each step conversationally.

## Phase 1: Workspace Setup

1. Ask: "Where do you want your agent workspace?" (default: `~/agent-workspace/`)
2. Confirm the path, create the directory
3. Copy template files from `template/` to the target:
   - `CLAUDE.md`, `SOUL.md`, `USER.md`, `cron-registry.json`
   - `.claude/skills/daily-summary.md`
   - `agents/` (alpha, beta, gamma with their CLAUDE.md, skills, memory)
   - `shared/memory/`, `memory/`
4. Ask the user to fill in `USER.md` — walk through each field:
   - Name, timezone, OS
   - What they do (2-3 sentences)
   - How they want to work
   - Preferences
5. Ask if they want to customize `SOUL.md` or keep defaults
6. Ask if they want all 3 agents (alpha/beta/gamma) or fewer — remove unused ones

## Phase 2: Telegram Setup

1. Ask: "Do you want to set up Telegram?" — if no, skip to Phase 3
2. Check prerequisites:
   - `bun --version` (install if missing: `curl -fsSL https://bun.sh/install | bash`)
   - `jq --version` (tell them to install if missing)
   - Check if telegram plugin is installed (look for `~/.claude/plugins/*/telegram`)
   - If not installed: `claude plugin install telegram`
3. Bot token:
   - Check if `~/.claude/channels/telegram/.env` exists with a token
   - If yes: "Found existing bot token. Use this one?" Show first 10 chars.
   - If no: Walk through BotFather setup:
     - "Open Telegram and DM @BotFather"
     - "Send /newbot"
     - "Pick a name and username (must end in 'bot')"
     - "Paste the token here"
   - Save to `~/.claude/channels/telegram/.env`
4. Telegram user ID:
   - "DM @userinfobot on Telegram to get your numeric user ID"
   - "Paste your user ID here"
   - Save to `~/.claude/channels/telegram/trusted-users.json`
5. Install auto-pair:
   - Copy `telegram/auto-pair.sh` to `~/.claude/channels/telegram/auto-pair.sh`
   - `chmod +x` it
   - Copy `telegram/SETUP-GUIDE.md` to `~/.claude/channels/telegram/SETUP-GUIDE.md`
6. Add SessionStart hook to `~/.claude/settings.json`:
   - Read existing settings (or create default)
   - Check if auto-pair hook already exists (skip if so)
   - Add to SessionStart array:
     ```json
     {"hooks":[{"type":"command","command":"bash \"$HOME/.claude/channels/telegram/auto-pair.sh\"","timeout":10}]}
     ```
   - Write back
7. Run auto-pair now: `bash ~/.claude/channels/telegram/auto-pair.sh`
8. Test: explain how to launch and test

## Phase 3: Summary

Show a summary of everything that was set up:

```
Setup complete!

Workspace: ~/agent-workspace/
  - Primary agent (CLAUDE.md, SOUL.md, USER.md)
  - Agents: alpha, beta, gamma
  - Cron registry, memory, shared resources

Telegram: @your_bot_username
  - Auto-pair configured for user ID XXXXXXX
  - SessionStart hook installed

To launch:
  cd ~/agent-workspace
  claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official

First time: DM your bot on Telegram — auto-pair handles the rest.
```

## Error handling

- If any step fails, explain what went wrong and offer to retry or skip
- Never leave settings.json in a broken state — always read before write
- If the user says "skip" at any point, move to the next phase
