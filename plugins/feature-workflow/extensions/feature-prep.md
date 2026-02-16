# Feature Prep Extensions

## Skip Docker Steps

**Do NOT** mention `/feature-docker start` or Docker environment setup when opening the worktree. Skip any Docker-related suggestions entirely.

## Open Worktree: Ask User Preference

### Check Tmux Availability

Before asking about tmux options, check if we're running inside a tmux session:

```bash
echo $TMUX
```

- If `$TMUX` is set (non-empty), we're inside tmux - show all options
- If `$TMUX` is empty, we're NOT inside tmux - only show VS Code option and notify user:
  > "Tmux options are not available because you're not running inside a tmux session. Only VS Code is available, or you can manually navigate to the worktree."

When not in tmux, also provide the manual navigation instructions:
```bash
cd <worktree-path>
claude
```

### Ask User Preferences

Before opening the worktree, use `AskUserQuestion` to ask the user TWO questions:

**Question 1:** "How would you like to open the worktree?"

**Options:**
1. **VS Code** - Opens a new VS Code window at the worktree path
2. **Tmux horizontal pane** - Opens a horizontal split pane (side-by-side) with Claude Code running in the worktree
3. **Tmux vertical pane** - Opens a vertical split pane (top/bottom) with Claude Code running in the worktree
4. **Tmux window** - Opens a new tmux window with Claude Code running in the worktree

**Question 2:** "Enable YOLO mode?" (only show if tmux option selected, not VS Code)

**Options:**
1. **Yes** - Run Claude with `--dangerously-skip-permissions` (no confirmation prompts)
2. **No** - Run Claude normally (with permission prompts)

### VS Code Option
```bash
code "<worktree-path>"
```
Note: VS Code doesn't support YOLO mode flag - Claude runs with normal permissions.

### Tmux Horizontal Pane Option
```bash
# Normal mode
tmux split-window -h -c "<worktree-path>" "claude"

# YOLO mode
tmux split-window -h -c "<worktree-path>" "claude --dangerously-skip-permissions"
```

### Tmux Vertical Pane Option
```bash
# Normal mode
tmux split-window -v -c "<worktree-path>" "claude"

# YOLO mode
tmux split-window -v -c "<worktree-path>" "claude --dangerously-skip-permissions"
```

### Tmux Window Option
```bash
# Normal mode
tmux new-window -c "<worktree-path>" -n "<feature-name>" "claude"

# YOLO mode
tmux new-window -c "<worktree-path>" -n "<feature-name>" "claude --dangerously-skip-permissions"
```

**After opening:** Inform user to run `/feature-build` in the new environment to start implementation.
