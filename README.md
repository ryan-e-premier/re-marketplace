# RE Marketplace

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
/plugin marketplace add ryan-e-premier/re-marketplace
```

### Install plugins

```bash
/plugin install diff-review@re-marketplace
/plugin install dev-utilities@re-marketplace
```

Plugins are independent and can be used in any combination.

## Requirements

- Claude Code CLI
- Vim (for diff-review)
- pnpm (for pnpm-outdated command)

## Development

This is a monorepo marketplace. Each plugin is independent and located in the
`plugins/` directory.

### Plugin structure

```
plugins/
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

https://github.com/ryan-e-premier/re-marketplace
