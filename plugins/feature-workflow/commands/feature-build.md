---
description: Build feature by implementing tasks one at a time
argument-hint: (none - auto-detects from worktree)
---

Build feature in current worktree

## Detection Logic

1. **Detect current location**
   - This command should be run in a worktree (not main)
   - Look for `work/features/*/tasks.md` in current directory
   - There should only be ONE feature folder in any worktree

2. **Validate setup**
   - Ensure we're in a git worktree (not main)
   - Ensure feature folder exists with all files:
     - `reqs.md`
     - `plan.md` 
     - `tasks.md`

## Workflow

### Initial Setup
1. **Load feature context (token-efficient)**
   - First, read ONLY `tasks.md`
   - Check if it contains a `## Summary` section (added after tasks are in progress)
   - **If summary exists:** Use the summary for context - do NOT read `reqs.md` or `plan.md`
   - **If no summary:** Read `reqs.md` and `plan.md` for full context (first run)
   - **If plan changes during build:** Update the summary in `tasks.md` to reflect significant changes (new approach, dropped tasks, architectural shifts, etc.)

2. **Check Docker environment (optional)**
   - If Docker is configured, remind user:
   - "To test this feature in isolation, run `/feature-docker start`"
   - Show URL if Docker is running

3. **Find next task**
   - Look for first unchecked task: `- [ ] TSK#:`
   - If all tasks complete: congratulate and suggest `/feature-end`
   - If no tasks exist: show error

### For Each Task

1. **Announce task**
   - Show task ID and description
   - Show task details (What, Files, Acceptance)
   - Confirm before starting

2. **Implement task**
   - Follow the implementation plan
   - Create/modify files as specified
   - Test as you go
   - Never commit without permission

3. **Mark task complete**
   - Update `tasks.md`: `- [ ] TSK#:` → `- [x] TSK#:`
   - Save the file

4. **PAUSE for review**
   - Show what was completed
   - Show files that were modified/created
   - Check if this task is the last one before a commit point (see Commit Point Detection below)
   - Wait for user feedback:
     - "continue" → move to next task
     - "commit" → run `/feature-commit` to commit changes, then continue
     - "redo" → revert changes and try again
     - "stop" → stop here, resume later
     - Specific feedback → adjust and continue

5. **Repeat**
   - Continue until all tasks are complete or user says stop

### Task Implementation Guidelines

- **One task at a time:** Never work ahead or combine tasks
- **Test incrementally:** Verify each task works before moving on
- **Stay focused:** Don't refactor or "improve" things outside the current task
- **Ask questions:** If task is unclear, ask before implementing
- **Commit at commit points:** When reaching a commit point, offer to commit. Use `/feature-commit` when user agrees.

## Task Status Display

After each task, show:
```
✓ TSK1: Setup database schema
✓ TSK2: Create API endpoints
→ TSK3: Build frontend components [CURRENT]
  TSK4: Add validation
  TSK5: Write tests
  TSK6: Update documentation
```

## Completion Message

When all tasks are done:
```
🎉 All tasks complete!

Summary:
- X tasks completed
- Y files created
- Z files modified

Your feature is ready for review. Next steps:
1. Review all changes
2. Test the feature end-to-end
3. When satisfied, run `/feature-end` to merge back to main
```

## Error Messages

If not in a worktree:
```
Error: This command must be run in a feature worktree.

You are currently in: [main/other]
To build a feature:
1. Go to main branch
2. Run /feature-prep <feature-name>
3. Switch to new VS Code window
4. Run /feature-build
```

If no tasks found:
```
Error: No tasks.md found in work/features/ directory.

This worktree may not be properly set up.
Did you run /feature-prep first?
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-build.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Commit Point Detection

After completing a task, check if the next line(s) in `tasks.md` contain a commit point marker:

```
📍 **Commit Point:** "Suggested commit message"
```

If the just-completed task is immediately followed by a commit point (before the next task), this is a **commit point reached** moment. Show the commit point info in the pause output.

## MANDATORY: Pause After Every Task

**After completing ANY task, output this format and STOP:**

### Standard pause (no commit point):
```
═══════════════════════════════════════════════════════
✓ TSK[X] COMPLETE: [task description]
═══════════════════════════════════════════════════════

What was done:
- [bullet points]

Files changed:
- [list]

Next: TSK[X+1]: [description]

→ Reply "continue" to proceed, or give feedback.
═══════════════════════════════════════════════════════
```

### Pause at commit point:
```
═══════════════════════════════════════════════════════
✓ TSK[X] COMPLETE: [task description]
═══════════════════════════════════════════════════════

What was done:
- [bullet points]

Files changed:
- [list]

📍 COMMIT POINT REACHED
   Suggested: "[message from tasks.md]"

   This is a good time to commit your code changes.
   (Feature files like tasks.md are committed at /feature-end)

Next: TSK[X+1]: [description]

→ Reply "continue", "commit", or give feedback.
═══════════════════════════════════════════════════════
```

**Then STOP and WAIT. Do not proceed until user responds.**

If user replies "commit", invoke `/feature-commit` to handle the commit, then continue to the next task.

⚠️ **CIRCUIT BREAKER:** If you find yourself implementing more than one task without user feedback, STOP IMMEDIATELY. This is an error.

## Important Reminders

- **Only commit when user says "commit"** - suggest it at commit points, but wait for permission
- **STOP after EVERY task** - wait for user response before proceeding
- Stay focused on one task at a time
- Use `/feature-commit` when user wants to commit
- When all tasks complete, run `/feature-end` to merge
