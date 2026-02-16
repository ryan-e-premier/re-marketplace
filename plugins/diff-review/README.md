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

When a file change is proposed:

```
Reviewing changes to: src/components/Button.tsx

[A]ccept changes
[R]eject changes
[E]xplain why these changes were made
[Q]uit and skip this file

Choice:
```

### Accept Changes

Press `A` to accept and apply the changes immediately.

### Reject Changes

Press `R` to reject. You'll be prompted to provide feedback explaining why the
changes aren't acceptable. Claude will receive your feedback and can propose
alternative changes.

### Get Explanation

Press `E` to see Claude's explanation of why these changes were made. After
reading, you can still accept or reject.

### Skip File

Press `Q` to skip reviewing this file without accepting or rejecting.

## Requirements

- Vim or Neovim
- Claude Code CLI

## Configuration

The plugin uses a pre-write hook configured in `hooks/hooks.json`:

```json
{
  "hooks": [
    {
      "type": "pre-write",
      "script": "${CLAUDE_PLUGIN_ROOT}/scripts/diff-review.sh"
    }
  ]
}
```

## Scripts

- `diff-review.sh` - Main review script that opens vimdiff
- `explain.sh` - Handles explanation requests
- `feedback-prompt.sh` - Prompts for rejection feedback

## Tips

- Use `:diffget` in vim to selectively accept portions of changes
- Use `:diffput` to move changes between windows
- Learn vimdiff commands for fine-grained control
- Reject changes early and often - Claude learns from feedback
- Use explanations to understand Claude's reasoning

## Disabling

To temporarily disable reviews:

```bash
/plugin disable diff-review
```

To re-enable:

```bash
/plugin enable diff-review
```

## License

MIT

## Author

eldridger

## Repository

https://github.com/eldridger/claude-diff-review
