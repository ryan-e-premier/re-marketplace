# Plan Review Plugin

Interactive section-by-section review of Claude Code plan files. Walk through
a plan, ask questions, and apply edits mid-review — with an optional tmux
popup mode that mirrors the diff-review experience.

## Overview

Invoke `/stn:plan-review` to load a plan file and walk through it one section
at a time. In popup mode each section opens in a styled nvim popup with
keyboard controls. In conversational mode sections are shown in the chat and
you navigate by typing.

Plans are discovered from two locations:

- **Local** — `.claude/plans/` relative to the current working directory
- **Global** — `~/.claude/plans/`

Both are shown in a grouped list so you always know which is which.

## Usage

```
/stn:plan-review [path]
```

- **With a path** — review that file directly
- **Without a path** — display a grouped plan list and prompt for a number

## Features

- **Grouped plan discovery** — local and global plans listed separately with
  modification dates
- **Popup mode** (requires tmux + neovim) — one section per popup, styled to
  match diff-review, with keyboard navigation and an activation delay that
  prevents accidental keypresses
- **Conversational mode** — sections shown in chat, navigate by typing
- **Ask questions** — press `q` in popup mode to type a question; Claude
  answers in the chat, then a prompt lets you return to the popup at your
  own pace
- **Request changes** — press `e` to describe a change; Claude proposes a
  before/after diff and confirms before applying
- **Jump navigation** — skip to any section by number
- **Changelog summary** — all edits listed at the end of the session

## Popup Keybinds

| Key | Action |
|-----|--------|
| `Enter` | Next section |
| `p` | Previous section |
| `q` | Ask a question |
| `e` | Request a change |
| `d` | Finish review |

Keys are locked for ~1.5 seconds after the popup opens to prevent accidental
activation. The tabline shows the current section position and available keys.

## Requirements

- Claude Code CLI
- tmux (popup mode only)
- Neovim (popup mode only)

## Scripts

- `plan-view.sh` — Opens one plan section in a tmux popup; blocks via
  signal-file polling and returns a decision string to the command loop
- `plan-feedback.sh` — Small popup for collecting question or change text

## Configuration

Set `PLAN_VIEW_DELAY` (milliseconds) to adjust how long keys stay locked
after the popup opens. Default is `1500`.

```bash
export PLAN_VIEW_DELAY=800
```

## Allow-listing the scripts

To prevent Claude Code from prompting for approval before each popup, add
the scripts to your `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash *plan-view.sh*)",
      "Bash(bash *plan-feedback.sh*)"
    ]
  }
}
```

## License

MIT

## Author

Ryan Eldridge

## Repository

https://github.com/ryan-e-premier/claude-marketplace
