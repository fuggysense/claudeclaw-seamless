# ClaudeClaw Seamless

Persistent Claude Code agents with zero-friction Telegram connectivity. Workspace blueprint + auto-pairing in one package.

Built on [ClaudeClaw](https://github.com/robonuggets/claudeclaw) by Jay from RoboLabs.

## What you get

**Workspace** — Multi-agent setup with session persistence
- Primary agent + up to 3 sub-agents (alpha/beta/gamma)
- SOUL.md (personality), USER.md (context), CLAUDE.md (instructions)
- Cron registry that survives session restarts
- Shared memory across agents

**Telegram** — Message your agent from your phone
- Auto-pairing eliminates manual pairing codes
- SessionStart hook ensures connectivity on every session
- Works across plugin updates and path changes

## Setup

### Option A: Guided (recommended)

```bash
git clone <this-repo>
cd claudeclaw-seamless
claude
```

Then type `/setup` and follow the prompts.

### Option B: Script

```bash
git clone <this-repo>
cd claudeclaw-seamless
bash install.sh
```

Interactive — walks through workspace scaffolding and Telegram configuration.

## After setup

```bash
cd ~/agent-workspace   # or wherever you set it up
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

DM your bot on Telegram. It works immediately.

## How auto-pair works

The official Telegram plugin stores access control in a relative path inside the plugin directory. This path varies between plugin versions and installation methods. The documented path (`~/.claude/channels/telegram/`) is not where the server actually reads from.

`auto-pair.sh` runs on every Claude Code session start and finds ALL Telegram access files across all plugin directories. It pre-approves your user ID in every one, so pairing just works regardless of which path is active.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Pro or Max subscription)
- [Bun](https://bun.sh) runtime (installer handles this)
- [jq](https://jqlang.github.io/jq/) (`brew install jq` on Mac)
- A Telegram bot token (from @BotFather)
- Your Telegram user ID (from @userinfobot)

## Files

```
claudeclaw-seamless/
├── CLAUDE.md                        # Repo instructions
├── README.md                        # This file
├── install.sh                       # Bash installer
├── .claude/skills/
│   └── setup.md                     # Guided /setup skill
├── template/                        # Workspace blueprint
│   ├── CLAUDE.md                    # Agent instructions
│   ├── SOUL.md                      # Personality rules
│   ├── USER.md                      # User context
│   ├── cron-registry.json           # Scheduled tasks
│   ├── .claude/skills/
│   │   └── daily-summary.md         # Example skill
│   ├── agents/{alpha,beta,gamma}/   # Sub-agent workspaces
│   ├── shared/memory/               # Cross-agent memory
│   └── memory/                      # Primary agent memory
└── telegram/                        # Auto-pair system
    ├── auto-pair.sh                 # Syncs access across plugin dirs
    ├── trusted-users.template.json  # User ID config template
    └── SETUP-GUIDE.md              # Troubleshooting reference
```

## Known limitations

- **First message delay**: The first Telegram message after idle may not arrive. Send a second message — it's a channels protocol issue, not fixable at this layer.
- **No offline queue**: Messages sent while Claude Code is closed are lost.
- **No message history**: The bot only sees messages that arrive while the session is running.

## Credits

- [ClaudeClaw](https://github.com/robonuggets/claudeclaw) by Jay from RoboLabs — workspace blueprint and architecture patterns
- Telegram auto-pair by Jerel — seamless connectivity fix

## License

MIT
