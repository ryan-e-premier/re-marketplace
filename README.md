# RE Marketplace

A collection of Claude Code plugins for streamlined feature development
workflows, code review, and development utilities.

## Plugins

### 🔄 feature-workflow

Complete feature development lifecycle with git worktrees, planning, task
management, testing, and Docker integration.

**Commands:** 14 commands including `/feature-start`, `/feature-build`,
`/feature-end`, `/test-all-apps`, `/update-packages`

**Features:**

- Git worktree-based feature isolation
- Integrated task management
- Docker environment management
- Comprehensive testing workflows
- ClaudeFlow customization templates

[View documentation](./plugins/feature-workflow/README.md)

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

Helper scripts for package management, transcript formatting, and diffview.

**Commands:** `/diffview`, `/transcript`, `/pnpm-outdated`

**Features:**

- Semantic version analysis for pnpm packages
- Transcript formatting and context tools
- Diff visualization utilities

[View documentation](./plugins/dev-utilities/README.md)

## Installation

### Add the marketplace

```bash
/plugin marketplace add eldridger/re-marketplace
```

### Install plugins

Install all plugins:

```bash
/plugin install feature-workflow@re-marketplace
/plugin install diff-review@re-marketplace
/plugin install dev-utilities@re-marketplace
```

Or install individually based on your needs. Plugins are independent and can be
used in any combination.

## Requirements

- Claude Code CLI
- Git (for feature-workflow)
- Vim (for diff-review)
- tmux (recommended for feature-workflow)
- pnpm (for pnpm-outdated command)

## Development

This is a monorepo marketplace. Each plugin is independent and located in the
`plugins/` directory.

### Plugin structure

```
plugins/
├── feature-workflow/
├── diff-review/
└── dev-utilities/
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

https://github.com/eldridger/re-marketplace
