# Claude Marketplace

A collection of Claude Code plugins for code review and development utilities.
All commands are available as `/stn:<command>` once the marketplace is added.

## Installation

```bash
/plugin marketplace add ryan-e-premier/claude-marketplace
```

That's it — all plugins load automatically. No individual installs needed.

## Plugins

### 🔍 diff-review

Interactive vimdiff code review before file changes are applied.

**Command:** hook-based (no slash command)

- Pre-write hook intercepts file changes
- Side-by-side vimdiff comparison with accept/reject

[View documentation](./plugins/diff-review/README.md)

### 📊 diffview

Open a side-by-side diff in a new tmux window using Neovim's DiffviewOpen.

**Command:** `/stn:diffview [base]`

[View documentation](./plugins/diffview/README.md)

### 📦 pnpm-outdated

Color-coded summary of outdated pnpm packages with semantic version analysis.

**Command:** `/stn:pnpm-outdated`

- Categorizes updates as DEPRECATED, SAFE (minor/patch), or MAJOR

[View documentation](./plugins/pnpm-outdated/README.md)

### 📜 transcript

Open the current Claude Code conversation transcript in nvim via a tmux popup.

**Command:** `/stn:transcript`

[View documentation](./plugins/transcript/README.md)

### 🕐 timecard

Automate filling out your Workday timecard with browser automation.

**Command:** `/stn:timecard`

- Gathers hours upfront, shows preview, then automates Chrome to fill Workday

[View documentation](./plugins/timecard/README.md)

### 📋 plan-review

Interactive section-by-section review of Claude Code plan files.

**Command:** `/stn:plan-review [path]`

- Popup mode (tmux + neovim) with keybinds: Enter=next, p=prev, q=ask,
  e=change, d=done
- Conversational mode for non-tmux environments
- Propose and apply edits inline with confirmation

[View documentation](./plugins/plan-review/README.md)

### 🔧 fix-pr-interactive

Interactively review and address GitHub PR feedback one comment at a time.

**Command:** `/stn:fix-pr-interactive [PR_NUMBER]`

- Full code context and diff hunk for each comment
- Groups duplicate feedback; session persistence for long reviews
- Commit-per-fix workflow with immediate push

[View documentation](./plugins/fix-pr-interactive/README.md)

### 📸 add-ss *(WIP)*

Capture Chrome screenshots and save them ready to drop into the PR.

**Command:** `/stn:add-ss [tab description]`

- Captures tabs via html2canvas, saves to `/tmp/add-ss-pr-{number}/`
- Opens the PR in Chrome and Finder for drag-and-drop upload

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
├── diff-review/
├── diffview/
├── pnpm-outdated/
├── transcript/
├── timecard/
├── plan-review/
├── fix-pr-interactive/
└── add-ss/
```

Each plugin contains a `.claude-plugin/plugin.json` manifest, a
`commands/stn/` directory with command definitions, and optionally a
`scripts/` directory and `README.md`.

## License

MIT — See [LICENSE](./LICENSE) for details.

## Author

Ryan Eldridge — https://github.com/ryan-e-premier/claude-marketplace
