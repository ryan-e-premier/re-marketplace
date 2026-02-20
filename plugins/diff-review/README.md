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

- Neovim (`nvim`)
- tmux
- jq
- Claude Code CLI

## Configuration

The plugin uses a `PreToolUse` hook configured in `hooks/hooks.json`:

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

- `diff-review.sh` - Main review script that opens vimdiff
- `explain.sh` - Handles explanation requests
- `feedback-prompt.sh` - Prompts for rejection feedback

## Tips

- Both diff windows are read-only — review only, no manual editing
- Use `e` to get an AI explanation before deciding
- Reject changes early and often - Claude learns from feedback
- Set `DIFF_REVIEW_DELAY` env var (ms) to adjust the key-lock delay

## License

MIT

## Author

eldridger

## Repository

https://github.com/eldridger/claude-diff-review
