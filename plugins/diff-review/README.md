# Diff Review Plugin

Interactive vimdiff code review before file changes are applied. Review
Claude's proposed changes side-by-side with syntax highlighting before they
touch your codebase.

## Overview

This plugin adds a pre-write hook that intercepts Claude Code's file changes
and opens them in vimdiff for review. You can accept or reject changes, get
explanations, and provide feedback before any files are modified.

## Features

- **Pre-write interception** - Catches all file modifications before they're
  written
- **Side-by-side diff** - Vimdiff popup with syntax highlighting
- **Accept/Reject** - Simple interface to approve or reject changes
- **Explanations** - Ask Claude why changes were made
- **Feedback** - Provide feedback on rejected changes
- **Safety** - No changes applied until you approve

## How It Works

1. Claude proposes a file change
2. Plugin intercepts the write operation
3. Opens vimdiff comparing original vs proposed
4. You review the changes side-by-side
5. Accept to apply, or reject to provide feedback
6. If rejected, Claude receives your feedback and can adjust

## Usage

Once installed, the plugin automatically intercepts all file changes. No
commands needed - just use Claude Code normally.

### Review Interface

When a file change is proposed, a tmux popup opens with a side-by-side
vimdiff view. The tabline shows available actions:

```
CLAUDE REVIEW │ src/components/Button.tsx
Enter ✓Approve  r ↻Redo  e ?Explain  q ✗Cancel
```

Keys are locked for a brief moment after the popup opens to prevent
accidental approvals.

### Accept Changes

Press `Enter` to accept and apply the changes immediately.

### Reject Changes

Press `r` to reject. A second popup prompts for feedback explaining why the
changes aren't acceptable. Claude receives your feedback and can propose
alternative changes.

### Get Explanation

Press `e` to see an AI-generated explanation of why these changes were made.
After reading, you can still accept or reject.

### Cancel

Press `q` to cancel the change. The write is blocked and Claude is notified.

## Requirements

- `nvim` or `vim` — neovim preferred; vim used as fallback with full
  compatibility (softer diff colors, statusline pane labels instead of
  winbar)
- tmux
- jq
- Claude Code CLI

## Configuration

### Config file

Persistent options are set in `~/.config/claude-diff-review/config`.
Create it if it doesn't exist:

```bash
mkdir -p ~/.config/claude-diff-review
touch ~/.config/claude-diff-review/config
```

The file uses simple `key=value` syntax, one option per line. Lines
starting with `#` are treated as comments.

```ini
# ~/.config/claude-diff-review/config

editor=vim     # which editor to use for the diff popup
delay=1000     # key-lock delay in milliseconds
```

### Options

#### `editor`

Controls which editor opens the diff popup. If not set, the plugin
auto-detects: nvim is used if installed, vim is used as a fallback.

| Value  | Behavior                                                    |
|--------|-------------------------------------------------------------|
| `nvim` | Use Neovim — winbar pane labels, treesitter highlighting    |
| `vim`  | Use Vim — statusline pane labels, standard syntax highlight |

Example:

```ini
editor=vim
```

#### `delay`

The number of milliseconds after the popup opens before keybindings
activate. During this window, only the `Enter` key is guarded — it
shows a "Keys locked" message rather than immediately approving. This
prevents accidental approvals when the popup steals focus mid-typing.

Default: `1500` (1.5 seconds). Set lower if the delay feels too long,
or higher if you find yourself accidentally pressing keys.

```ini
delay=800
```

### Hook configuration

The plugin registers itself via `hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/diff-review.sh",
            "timeout": 600
          }
        ]
      }
    ]
  }
}
```

## Scripts

- `diff-review.sh` — Main review script; opens the diff popup and
  handles approve/reject/explain/cancel signals
- `explain.sh` — Generates and displays an AI explanation of the diff
- `feedback-prompt.sh` — Prompts for rejection feedback in a small popup

## Tips

- Both diff windows are read-only — review only, no manual editing
- Use `e` to get an AI explanation before deciding
- Reject changes early and often — Claude learns from your feedback

## License

MIT

## Author

eldridger

