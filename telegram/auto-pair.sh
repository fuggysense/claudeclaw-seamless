#!/bin/bash
# auto-pair.sh — Ensures trusted Telegram users are pre-approved in ALL plugin state dirs.
# Runs on SessionStart via hook. Idempotent — safe to run multiple times.

set -euo pipefail

CONFIG="$HOME/.claude/channels/telegram/trusted-users.json"

if [[ ! -f "$CONFIG" ]]; then
  exit 0
fi

# Extract trusted user IDs
TRUSTED_IDS=$(jq -r '.users[].id' "$CONFIG" 2>/dev/null)
if [[ -z "$TRUSTED_IDS" ]]; then
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

  for TID in $TRUSTED_IDS; do
    IN_ALLOW=$(echo "$UPDATED" | jq --arg uid "$TID" '.allowFrom | index($uid) != null')
    if [[ "$IN_ALLOW" == "true" ]]; then
      continue
    fi
    UPDATED=$(echo "$UPDATED" | jq --arg uid "$TID" '.allowFrom += [$uid] | .allowFrom |= unique')
    CHANGED=1
  done

  # Clear pending entries for trusted users
  for TID in $TRUSTED_IDS; do
    UPDATED=$(echo "$UPDATED" | jq --arg uid "$TID" '
      .pending |= with_entries(select(.value.senderId != $uid))
    ')
  done

  if [[ "$UPDATED" != "$CURRENT" ]]; then
    echo "$UPDATED" | jq '.' > "${ACCESS_FILE}.tmp"
    mv "${ACCESS_FILE}.tmp" "$ACCESS_FILE"
    chmod 600 "$ACCESS_FILE"
    CHANGED=1
  fi
done

# Create approved signal files
for TID in $TRUSTED_IDS; do
  for ACCESS_FILE in "${ACCESS_FILES[@]}"; do
    APPROVED_DIR="$(dirname "$ACCESS_FILE")/approved"
    mkdir -p "$APPROVED_DIR"
    if [[ ! -f "$APPROVED_DIR/$TID" ]]; then
      echo -n "$TID" > "$APPROVED_DIR/$TID"
      CHANGED=1
    fi
  done
done

if [[ "$CHANGED" -eq 1 ]]; then
  echo "auto-pair: updated access for trusted users"
fi
