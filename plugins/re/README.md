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

### `/re:plan-review [path]`

Interactive section-by-section review of Claude Code plan files. Walk through
each `##` section, ask questions, and apply edits — all without leaving the
conversation.

```bash
/re:plan-review                              # pick from recent plans
/re:plan-review ~/.claude/plans/my-plan.md  # open a specific file
```

Plans are searched in both `.claude/plans/` (local) and `~/.claude/plans/`
(global). Without an argument, a numbered list is shown and you pick by
number or filename.

#### Review modes

When running inside tmux, you are prompted to choose a mode. Popup editor
prompts for which terminal editor to use.

| Mode               | Description                                             |
|--------------------|---------------------------------------------------------|
| **Popup — nvim**   | Each section shown in Neovim inside a tmux popup        |
| **Popup — vim**    | Each section shown in Vim inside a tmux popup           |
| **Popup — nano**   | Each section shown in nano (view) + small action menu   |
| **VS Code**        | Full plan opened in VS Code; Claude waits for return    |
| **Conversational** | Sections rendered in chat; navigate via selection menu  |

Outside tmux, VS Code or Conversational mode is offered.

#### Editor popup controls (nvim / vim)

| Key        | Action                              |
|------------|-------------------------------------|
| `Enter`, `n` | Next section                      |
| `p`        | Previous section                    |
| `d`        | Done — skip to wrap-up              |
| `q`        | Ask a question about this section   |
| `e`        | Request a change to this section    |

For nano, the same actions are presented as a numbered menu after closing
the view popup.

#### Conversational mode navigation

After each section a selection menu offers:

1. **Next** — advance
2. **Done** — finish and go to wrap-up
3. **Jump to section…** — enter a section number to jump
4. **Ask / request a change** — type a question or describe an edit

#### VS Code mode

When VS Code is selected, the plan file opens via `code <file>` and Claude
pauses with three options to choose from when you return:

- **Done reviewing** — detect changes and go to wrap-up
- **Review sections now** — run a conversational section review first
- **Re-open in VS Code** — open the file again

#### Wrap-up

After the last section (or when you press `d`/Done), the command:

- Lists every edit made during the session
- Offers to open the plan in nvim, vim, or VS Code for any final edits
  (skipped if you already used an editor)

### `/re:diffview`

Open a side-by-side git diff in a tmux popup using Neovim's DiffviewOpen.

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
