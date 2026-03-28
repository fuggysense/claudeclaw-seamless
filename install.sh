#!/bin/bash
# ClaudeClaw Seamless — combined workspace + Telegram installer
# Run: bash install.sh
#
# For a guided experience, open this repo in Claude Code and type /setup instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHANNELS_DIR="$HOME/.claude/channels/telegram"
SETTINGS="$HOME/.claude/settings.json"

echo "=== ClaudeClaw Seamless Setup ==="
echo ""
echo "This sets up:"
echo "  1. Agent workspace (CLAUDE.md, SOUL.md, agents, crons, memory)"
echo "  2. Telegram bot with auto-pairing"
echo ""

# --- Prerequisites ---

if ! command -v claude &>/dev/null; then
  echo "ERROR: Claude Code not found. Install: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi
echo "[ok] Claude Code"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found. Install: brew install jq (Mac) or apt install jq (Linux)"
  exit 1
fi
echo "[ok] jq"

if ! command -v bun &>/dev/null; then
  echo "Bun not found. Installing..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
fi
echo "[ok] Bun"

# ============================================================
# PHASE 1: WORKSPACE
# ============================================================

echo ""
echo "--- Phase 1: Workspace ---"
echo ""
read -p "Where do you want your agent workspace? [$HOME/agent-workspace] " WORKSPACE
WORKSPACE="${WORKSPACE:-$HOME/agent-workspace}"

if [[ -d "$WORKSPACE" ]]; then
  echo "Directory exists: $WORKSPACE"
  read -p "Overwrite template files? [y/N] " OVERWRITE
  if [[ "${OVERWRITE,,}" != "y" ]]; then
    echo "Skipping workspace setup. Existing files preserved."
    SKIP_WORKSPACE=true
  fi
fi

if [[ "${SKIP_WORKSPACE:-}" != "true" ]]; then
  echo "Scaffolding workspace at $WORKSPACE..."
  mkdir -p "$WORKSPACE"
  cp -r "$SCRIPT_DIR/template/"* "$WORKSPACE/"
  cp -r "$SCRIPT_DIR/template/".claude "$WORKSPACE/" 2>/dev/null || true
  echo "[ok] Workspace created"

  # Quick USER.md customization
  echo ""
  read -p "Your name: " USER_NAME
  read -p "Your timezone (e.g., Asia/Singapore): " USER_TZ
  read -p "Your OS (e.g., macOS, Windows, Linux): " USER_OS
  read -p "What do you do? (2-3 sentences): " USER_ROLE

  if [[ -n "$USER_NAME" ]]; then
    sed -i'' -e "s/\[Your name\]/$USER_NAME/" "$WORKSPACE/USER.md"
    sed -i'' -e "s/\[e.g., America\/New_York.*\]/$USER_TZ/" "$WORKSPACE/USER.md"
    sed -i'' -e "s/\[e.g., Windows 11.*\]/$USER_OS/" "$WORKSPACE/USER.md"
    sed -i'' -e "s/\[Brief description.*\]/$USER_ROLE/" "$WORKSPACE/USER.md"
    echo "[ok] USER.md configured"
  fi

  echo ""
  read -p "How many agents? [3] (alpha/beta/gamma — enter 0-3): " AGENT_COUNT
  AGENT_COUNT="${AGENT_COUNT:-3}"
  if [[ "$AGENT_COUNT" -lt 3 ]]; then rm -rf "$WORKSPACE/agents/gamma"; fi
  if [[ "$AGENT_COUNT" -lt 2 ]]; then rm -rf "$WORKSPACE/agents/beta"; fi
  if [[ "$AGENT_COUNT" -lt 1 ]]; then rm -rf "$WORKSPACE/agents/alpha" "$WORKSPACE/agents"; fi
  echo "[ok] Agent team: $AGENT_COUNT agents"
fi

# ============================================================
# PHASE 2: TELEGRAM
# ============================================================

echo ""
echo "--- Phase 2: Telegram ---"
echo ""
read -p "Set up Telegram bot? [Y/n] " SETUP_TG
if [[ "${SETUP_TG,,}" == "n" ]]; then
  echo "Skipping Telegram setup."
else
  # Plugin check
  if [[ -d "$HOME/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/telegram" ]] || \
     find "$HOME/.claude/plugins/cache" -path "*/telegram*" -name "server.ts" -print -quit 2>/dev/null | grep -q .; then
    echo "[ok] Telegram plugin installed"
  else
    echo "Installing Telegram plugin..."
    claude plugin install telegram
    echo "[ok] Telegram plugin installed"
  fi

  # Bot token
  mkdir -p "$CHANNELS_DIR"
  if [[ -f "$CHANNELS_DIR/.env" ]] && grep -q "TELEGRAM_BOT_TOKEN=" "$CHANNELS_DIR/.env"; then
    EXISTING_TOKEN=$(grep "TELEGRAM_BOT_TOKEN=" "$CHANNELS_DIR/.env" | cut -d= -f2)
    echo "[ok] Bot token found (${EXISTING_TOKEN:0:10}...)"
    read -p "Use existing token? [Y/n] " USE_EXISTING
    if [[ "${USE_EXISTING,,}" == "n" ]]; then
      echo ""
      echo "Get a token from @BotFather on Telegram:"
      echo "  1. DM @BotFather → /newbot → pick name/username"
      echo "  2. Copy the token"
      echo ""
      read -p "Paste bot token: " BOT_TOKEN
      echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > "$CHANNELS_DIR/.env"
      chmod 600 "$CHANNELS_DIR/.env"
    fi
  else
    echo ""
    echo "You need a Telegram bot token from @BotFather:"
    echo "  1. Open Telegram, DM @BotFather"
    echo "  2. Send /newbot, pick a name and username (must end in 'bot')"
    echo "  3. Copy the token (format: 1234567890:ABCdef...)"
    echo ""
    read -p "Paste bot token: " BOT_TOKEN
    if [[ -z "$BOT_TOKEN" ]]; then
      echo "WARNING: No token. Telegram won't work until you add one."
      echo "  echo 'TELEGRAM_BOT_TOKEN=your_token' > $CHANNELS_DIR/.env"
    else
      echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > "$CHANNELS_DIR/.env"
      chmod 600 "$CHANNELS_DIR/.env"
      echo "[ok] Token saved"
    fi
  fi

  # Trusted users
  if [[ -f "$CHANNELS_DIR/trusted-users.json" ]]; then
    EXISTING_USERS=$(jq -r '.users[].id' "$CHANNELS_DIR/trusted-users.json" 2>/dev/null | tr '\n' ', ')
    echo "[ok] Trusted users: $EXISTING_USERS"
    read -p "Add another user? [y/N] " ADD_USER
    if [[ "${ADD_USER,,}" == "y" ]]; then
      echo "DM @userinfobot on Telegram to get your numeric user ID."
      read -p "Telegram user ID: " TG_USER_ID
      read -p "Name: " TG_USER_NAME
      jq --arg id "$TG_USER_ID" --arg name "$TG_USER_NAME" \
        '.users += [{"id": $id, "name": $name, "note": "Added by installer"}]' \
        "$CHANNELS_DIR/trusted-users.json" > "$CHANNELS_DIR/trusted-users.json.tmp"
      mv "$CHANNELS_DIR/trusted-users.json.tmp" "$CHANNELS_DIR/trusted-users.json"
      echo "[ok] Added $TG_USER_NAME"
    fi
  else
    echo ""
    echo "DM @userinfobot on Telegram to get your numeric user ID."
    read -p "Your Telegram user ID: " TG_USER_ID
    if [[ -z "$TG_USER_ID" ]]; then
      echo "WARNING: No user ID. You'll need to pair manually."
      echo '{"users": []}' | jq '.' > "$CHANNELS_DIR/trusted-users.json"
    else
      read -p "Your name: " TG_USER_NAME
      TG_USER_NAME="${TG_USER_NAME:-User}"
      jq -n --arg id "$TG_USER_ID" --arg name "$TG_USER_NAME" \
        '{"users": [{"id": $id, "name": $name, "note": "Primary operator"}]}' \
        > "$CHANNELS_DIR/trusted-users.json"
      echo "[ok] Trusted user: $TG_USER_NAME ($TG_USER_ID)"
    fi
  fi

  # Auto-pair script
  cp "$SCRIPT_DIR/telegram/auto-pair.sh" "$CHANNELS_DIR/auto-pair.sh"
  chmod +x "$CHANNELS_DIR/auto-pair.sh"
  cp "$SCRIPT_DIR/telegram/SETUP-GUIDE.md" "$CHANNELS_DIR/SETUP-GUIDE.md"
  echo "[ok] Auto-pair installed"

  # SessionStart hook
  if [[ -f "$SETTINGS" ]]; then
    if jq -e '.hooks.SessionStart[]? | select(.hooks[]?.command | test("auto-pair"))' "$SETTINGS" &>/dev/null; then
      echo "[ok] SessionStart hook exists"
    else
      HOOK='{"hooks":[{"type":"command","command":"bash \"$HOME/.claude/channels/telegram/auto-pair.sh\"","timeout":10}]}'
      if jq -e '.hooks.SessionStart' "$SETTINGS" &>/dev/null; then
        jq --argjson hook "$HOOK" '.hooks.SessionStart += [$hook]' "$SETTINGS" > "${SETTINGS}.tmp"
      else
        jq --argjson hook "$HOOK" '.hooks.SessionStart = [$hook]' "$SETTINGS" > "${SETTINGS}.tmp"
      fi
      mv "${SETTINGS}.tmp" "$SETTINGS"
      echo "[ok] SessionStart hook added"
    fi
  else
    jq -n --argjson hook '{"hooks":[{"type":"command","command":"bash \"$HOME/.claude/channels/telegram/auto-pair.sh\"","timeout":10}]}' \
      '{"hooks":{"SessionStart":[$hook]}}' > "$SETTINGS"
    echo "[ok] settings.json created"
  fi

  # Run now
  echo ""
  bash "$CHANNELS_DIR/auto-pair.sh" 2>&1 || true
fi

# ============================================================
# SUMMARY
# ============================================================

echo ""
echo "=== Setup Complete ==="
echo ""
if [[ "${SKIP_WORKSPACE:-}" != "true" ]]; then
  echo "Workspace: $WORKSPACE"
  echo "  CLAUDE.md, SOUL.md, USER.md, cron-registry.json"
  [[ "$AGENT_COUNT" -gt 0 ]] && echo "  Agents: $(ls "$WORKSPACE/agents/" 2>/dev/null | tr '\n' ', ')"
  echo ""
fi
if [[ "${SETUP_TG,,}" != "n" ]]; then
  echo "Telegram: auto-pair configured"
  echo ""
fi
echo "Launch:"
if [[ "${SKIP_WORKSPACE:-}" != "true" ]]; then
  echo "  cd $WORKSPACE"
fi
echo "  claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official"
echo ""
echo "First time: DM your bot on Telegram — auto-pair handles the rest."
echo ""
echo "Troubleshooting: cat $CHANNELS_DIR/SETUP-GUIDE.md"
