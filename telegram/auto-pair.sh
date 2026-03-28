#!/bin/bash
# auto-pair.sh — Ensures trusted users + groups are pre-approved in ALL plugin state dirs.
# Runs on SessionStart via hook. Idempotent — safe to run multiple times.

set -euo pipefail

# Clean stale GumClaw locks
LOCK_DIR="$HOME/.claude/channels/telegram/locks"
if [[ -d "$LOCK_DIR" ]]; then
  for lockfile in "$LOCK_DIR"/*.lock; do
    [[ -f "$lockfile" ]] || continue
    PID=$(jq -r '.pid' "$lockfile" 2>/dev/null)
    if [[ -n "$PID" ]] && ! kill -0 "$PID" 2>/dev/null; then
      rm -f "$lockfile"
    fi
  done
fi

CONFIG="$HOME/.claude/channels/telegram/trusted-users.json"

if [[ ! -f "$CONFIG" ]]; then
  exit 0
fi

# Extract trusted user IDs
TRUSTED_IDS=$(jq -r '.users[]?.id // empty' "$CONFIG" 2>/dev/null)

# Extract group configs
GROUP_COUNT=$(jq -r '.groups | length' "$CONFIG" 2>/dev/null || echo "0")

if [[ -z "$TRUSTED_IDS" ]] && [[ "$GROUP_COUNT" -eq 0 ]]; then
  exit 0
fi

# Find ALL telegram access.json files across plugin dirs
ACCESS_FILES=()
while IFS= read -r -d '' f; do
  ACCESS_FILES+=("$f")
done < <(find "$HOME/.claude/plugins" -path "*/telegram*/.claude/telegram/access.json" -print0 2>/dev/null)

# Also check the default channels dir
if [[ -f "$HOME/.claude/channels/telegram/access.json" ]]; then
  ACCESS_FILES+=("$HOME/.claude/channels/telegram/access.json")
fi

CHANGED=0

for ACCESS_FILE in "${ACCESS_FILES[@]}"; do
  if [[ ! -f "$ACCESS_FILE" ]]; then
    continue
  fi

  CURRENT=$(cat "$ACCESS_FILE")
  UPDATED="$CURRENT"

  # --- DM users ---
  for TID in $TRUSTED_IDS; do
    IN_ALLOW=$(echo "$UPDATED" | jq --arg uid "$TID" '.allowFrom | index($uid) != null')
    if [[ "$IN_ALLOW" != "true" ]]; then
      UPDATED=$(echo "$UPDATED" | jq --arg uid "$TID" '.allowFrom += [$uid] | .allowFrom |= unique')
      CHANGED=1
    fi
  done

  # Clear pending entries for trusted users
  for TID in $TRUSTED_IDS; do
    UPDATED=$(echo "$UPDATED" | jq --arg uid "$TID" '
      .pending |= with_entries(select(.value.senderId != $uid))
    ')
  done

  # --- Groups ---
  if [[ "$GROUP_COUNT" -gt 0 ]]; then
    # Merge group configs from trusted-users.json into access.json
    # Only adds groups that don't already exist — never overwrites existing group config
    GROUPS_JSON=$(jq -c '.groups // []' "$CONFIG")
    UPDATED=$(echo "$UPDATED" | jq --argjson groups "$GROUPS_JSON" '
      reduce ($groups[]) as $g (.;
        if .groups[$g.id] then .
        else .groups[$g.id] = {
          requireMention: ($g.requireMention // true),
          allowFrom: ($g.allowFrom // [])
        }
        end
      )
    ')
    # Check if groups actually changed
    if [[ "$(echo "$CURRENT" | jq -c '.groups')" != "$(echo "$UPDATED" | jq -c '.groups')" ]]; then
      CHANGED=1
    fi
  fi

  # Write back if changed
  if [[ "$UPDATED" != "$CURRENT" ]]; then
    echo "$UPDATED" | jq '.' > "${ACCESS_FILE}.tmp"
    mv "${ACCESS_FILE}.tmp" "$ACCESS_FILE"
    chmod 600 "$ACCESS_FILE"
    CHANGED=1
  fi
done

# Clean up approved signal files — they trigger "Paired!" messages every time.
# Only needed for first-time pairing. Once user is in allowFrom, remove them.
for TID in $TRUSTED_IDS; do
  for ACCESS_FILE in "${ACCESS_FILES[@]}"; do
    APPROVED_DIR="$(dirname "$ACCESS_FILE")/approved"
    if [[ -f "$APPROVED_DIR/$TID" ]]; then
      rm -f "$APPROVED_DIR/$TID"
    fi
  done
done

if [[ "$CHANGED" -eq 1 ]]; then
  echo "auto-pair: updated access for trusted users and groups"
fi
