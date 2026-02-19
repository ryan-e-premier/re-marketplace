# Claude Marketplace

A collection of Claude Code plugins for code review and development utilities.

## Plugins

### 🔍 diff-review

Interactive vimdiff code review before file changes are applied. Review
Claude's proposed changes side-by-side with syntax highlighting before they
touch your codebase.

**Features:**

- Pre-write hook intercepts file changes
- Side-by-side vimdiff comparison
- Accept/reject interface
- Explanation and feedback prompts

[View documentation](./plugins/diff-review/README.md)

### 🛠️ dev-utilities

Helper scripts for package management, transcript formatting, diffview, and
Workday timecard automation.

**Commands:** `/diffview`, `/transcript`, `/pnpm-outdated`, `/stn:timecard`

**Features:**

- Semantic version analysis for pnpm packages
- Transcript formatting and context tools
- Diff visualization utilities
- Workday timecard browser automation

[View documentation](./plugins/dev-utilities/README.md)

### 📋 plan-review

Interactive section-by-section review of Claude Code plan files. Walk through
a plan, ask questions, and apply edits mid-review — with an optional tmux
popup mode that mirrors the diff-review experience.

**Command:** `/stn:plan-review [path]`

**Features:**

- Discovers plans from both local `.claude/plans/` and global
  `~/.claude/plans/`, displayed in labelled groups
- **Popup mode** (tmux + neovim) — one section per popup with keybinds:
  Enter=next, p=prev, q=ask, e=change, d=done
- **Conversational mode** — sections shown in chat, navigate by typing
- Ask questions mid-review; answer shown in chat before popup reopens
- Propose and apply edits inline with before/after confirmation
- Jump navigation and changelog summary at wrap-up

[View documentation](./plugins/plan-review/README.md)

## Installation

### Add the marketplace

```bash
/plugin marketplace add ryan-e-premier/claude-marketplace
```

### Install plugins

```bash
/plugin install diff-review@claude-marketplace
/plugin install dev-utilities@claude-marketplace
/plugin install plan-review@claude-marketplace
```

Plugins are independent and can be used in any combination.

## Requirements

- Claude Code CLI
- Neovim + tmux (for diff-review and plan-review popup mode)
- pnpm (for pnpm-outdated command)
- Chrome browser with Claude in Chrome extension (for timecard automation)

## Development

This is a monorepo marketplace. Each plugin is independent and located in the
`plugins/` directory.

### Plugin structure

```
plugins/
├── diff-review/
├── dev-utilities/
└── plan-review/
```

Each plugin contains:

- `.claude-plugin/plugin.json` - Plugin manifest
- `commands/` - Command definitions (markdown files)
- `scripts/` - Shell scripts for command execution
- `README.md` - Plugin documentation

## License

MIT - See [LICENSE](./LICENSE) for details.

## Author

Ryan Eldridge

## Contributing

Issues and pull requests welcome!

https://github.com/ryan-e-premier/claude-marketplace
