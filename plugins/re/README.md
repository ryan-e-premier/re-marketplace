# re

A collection of development utilities for Claude Code.

## Commands

All commands are available as `/re:<command>` after installing.

### `/re:fix-pr-interactive [PR_NUMBER]`

Interactively review and address GitHub PR feedback one comment at a time.
Maintains session state so you can resume if context is lost mid-session.

```bash
/re:fix-pr-interactive        # lists open PRs to pick from
/re:fix-pr-interactive 366    # jump straight to PR #366
```

### `/re:plan-review`

Interactive section-by-section review of Claude Code plan files. Opens each
section in a tmux pane for focused review and approval.

### `/re:diffview`

Open a side-by-side git diff in a tmux window using Neovim's DiffviewOpen.

```bash
/re:diffview             # diff against origin/main
/re:diffview origin/dev  # diff against a custom base
```

### `/re:pnpm-outdated`

Color-coded summary of outdated pnpm packages with semver analysis. Highlights
major, minor, and patch updates across the monorepo.

### `/re:transcript`

Open the current Claude Code conversation transcript in nvim for review.
Requires `tmux` and `nvim`.

### `/re:timecard`

Automate filling out your Workday timecard using browser automation.

### `/re:add-ss` *(WIP)*

Capture Chrome screenshots and save them ready to drop into the PR.

## Installation

Install via the re-marketplace:

```bash
/plugin install re@re-marketplace
```
