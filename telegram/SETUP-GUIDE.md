# Telegram Bot — Setup & Troubleshooting Guide

## Daily Use (Existing Bot)

1. Open terminal
2. `claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official`
3. DM the bot on Telegram — it works. No pairing needed.

The `auto-pair.sh` hook runs on session start and pre-approves trusted users in all plugin state dirs.

## New Bot From Scratch

### Prerequisites
- Claude Code installed
- jq installed (`brew install jq` on Mac)
- Bun runtime (installer handles this)

### Quick Setup
```bash
git clone <this-repo>
cd telegram-seamless
bash install.sh
```

The installer walks you through everything interactively.

### Manual Steps (if needed)

1. **Create bot on BotFather**
   - Open Telegram, DM @BotFather
   - Send `/newbot`
   - Pick a name and username (must end in `bot`)
   - Copy the token (format: `1234567890:ABCdef...`)

2. **Save token**
   ```bash
   mkdir -p ~/.claude/channels/telegram
   echo "TELEGRAM_BOT_TOKEN=<paste-token-here>" > ~/.claude/channels/telegram/.env
   ```

3. **Add your Telegram user ID to trusted users**
   - DM @userinfobot on Telegram to get your numeric user ID
   - Edit `~/.claude/channels/telegram/trusted-users.json`:
   ```json
   {
     "users": [
       { "id": "<your-user-id>", "name": "Your Name", "note": "Primary operator" }
     ]
   }
   ```

4. **Launch**
   ```bash
   claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
   ```

5. **First contact** — DM the bot on Telegram (any message). Auto-pair handles the rest.

## Troubleshooting

### "chat X is not allowlisted"
The plugin can't find your user ID in the correct access.json.

**Quick fix:** `bash ~/.claude/channels/telegram/auto-pair.sh`

**Debug steps:**
1. Find the running bot process:
   ```bash
   ps eww $(pgrep -f "bun.*telegram") | tr ' ' '\n' | grep TELEGRAM
   ```
2. Look for `TELEGRAM_STATE_DIR` — the REAL state dir (usually relative)
3. Look for `CLAUDE_PLUGIN_ROOT` — base dir the relative path resolves from
4. Check access.json at `<CLAUDE_PLUGIN_ROOT>/<TELEGRAM_STATE_DIR>/access.json`

### Why This Exists
The official Telegram plugin sets `TELEGRAM_STATE_DIR=.claude/telegram` as a RELATIVE env var. This resolves inside whichever plugin directory the server runs from — NOT `~/.claude/channels/telegram/` where the docs say. So pairing approvals written to the "documented" path are invisible to the running server.

`auto-pair.sh` solves this by finding and syncing ALL access.json files across all plugin directories.

### Bot not responding at all
- Check bot is running: `pgrep -f "bun.*telegram"`
- Check token is valid: `curl https://api.telegram.org/bot<TOKEN>/getMe`
- Restart: close Claude Code, relaunch with `--channels` flag

### Messages not arriving
- Terminal input takes priority over Telegram messages
- Send a Telegram message without typing in terminal first
- If still broken: same access.json controls both inbound and outbound

## Architecture

```
You (Telegram) → Bot API → grammY polling → gate() → access.json → deliver to Claude
Claude → reply tool → assertAllowedChat() → access.json → Bot API → You (Telegram)
```

## Files

| File | Purpose |
|------|---------|
| `~/.claude/channels/telegram/.env` | Bot token |
| `~/.claude/channels/telegram/trusted-users.json` | User IDs to auto-approve |
| `~/.claude/channels/telegram/auto-pair.sh` | Syncs access across all plugin dirs |
| `~/.claude/settings.json` | SessionStart hook (runs auto-pair) |
| `<plugin-dir>/.claude/telegram/access.json` | The ACTUAL access state the server reads |
