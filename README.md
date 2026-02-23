# Claude Marketplace

A collection of Claude Code plugins for code review and development utilities.
All commands are available as `/re:<command>` once the marketplace is added.

## Installation

```bash
/plugin marketplace add ryan-e-premier/claude-marketplace
```

Then install the plugin:

```bash
/plugin install re@re-marketplace
```

## Plugins

### `re` — Development Utilities

All slash commands in one plugin, installed as `/re:<command>`.

#### `/re:fix-pr-interactive [PR_NUMBER]`

Interactively review and address GitHub PR feedback one comment at a time.

- Full code context and diff hunk for each comment
- Groups duplicate feedback; session persistence for long reviews
- Commit-per-fix workflow with immediate push

#### `/re:plan-review [path]`

Interactive section-by-section review of Claude Code plan files.

- Popup mode (tmux + neovim) with keybinds: Enter=next, p=prev, q=ask,
  e=change, d=done
- Conversational mode for non-tmux environments

#### `/re:diffview [base]`

Open a side-by-side diff in a new tmux window using Neovim's DiffviewOpen.

#### `/re:pnpm-outdated`

Color-coded summary of outdated pnpm packages with semantic version analysis.

#### `/re:transcript`

Open the current Claude Code conversation transcript in nvim via a tmux popup.

#### `/re:timecard`

Automate filling out your Workday timecard with browser automation.

[View documentation](./plugins/re/README.md)

---

### `diff-review` — File Change Review Hook

Hook-based vimdiff review before file changes are applied. No slash command.

[View documentation](./plugins/diff-review/README.md)

---

### `add-ss` *(WIP)* — Screenshot Helper

Capture Chrome screenshots and save them ready to drop into the PR.

**Command:** `/add-ss:stn:add-ss [tab description]`

[View documentation](./plugins/add-ss/README.md)

## Requirements

- Claude Code CLI
- nvim + tmux (for `diffview`, `transcript`, `plan-review`)
- pnpm (for `pnpm-outdated`)
- Chrome + Claude in Chrome extension (for `timecard`, `add-ss`)
- `gh` CLI + `jq` (for `fix-pr-interactive`, `add-ss`)

## Plugin Structure

```text
plugins/
├── re/            ← all /re:X commands
├── diff-review/   ← hooks only
└── add-ss/        ← WIP screenshots helper
```

## License

MIT — See [LICENSE](./LICENSE) for details.

## Author

Ryan Eldridge — https://github.com/ryan-e-premier/claude-marketplace
