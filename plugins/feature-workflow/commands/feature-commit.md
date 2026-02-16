---
description: Commit feature progress with context-aware message
argument-hint: (none - auto-generates from tasks)
---

Commit current feature progress with a context-aware commit message.

## Detection Logic

1. **Verify we're in a feature worktree**
   - Look for `work/features/*/tasks.md`
   - If not found, show error

2. **Check for uncommitted changes**
   - Run `git status`
   - **Exclude `work/features/` directory** - these files (tasks.md, plan.md, reqs.md) are committed at `/feature-end`, not during development
   - If no non-feature changes exist, inform user and exit

## Workflow

### 1. Gather Context

1. **Read tasks.md**
   - Parse all tasks and their status (completed vs pending)
   - Find the most recent commit point marker above current position
   - Identify which tasks have been completed

2. **Determine completed tasks since last commit**
   - Check git log to find the last commit
   - Compare tasks.md status to determine which completed tasks are uncommitted
   - These are the tasks that will be described in the commit message

3. **Check for commit point message**
   - If there's a commit point marker (`📍 **Commit Point:**`) immediately after the last completed task, extract its suggested message
   - This becomes the primary commit message

### 2. Generate Commit Message

**If at a commit point:**
- Use the suggested message from the commit point marker
- Add task details in the body

**If not at a commit point:**
- Generate message from completed task descriptions
- Format: summarize what was done based on task titles

Example commit message structure:
```
<summary line from commit point or generated>

Tasks completed:
- TSK3: Create GET /users endpoint
- TSK4: Create POST /users endpoint
- TSK5: Add error handling

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### 3. Show Summary and Confirm

Display to user:
```
═══════════════════════════════════════════════════════
📍 READY TO COMMIT
═══════════════════════════════════════════════════════

Completed tasks to include:
- TSK3: Create GET /users endpoint
- TSK4: Create POST /users endpoint
- TSK5: Add error handling

Commit message:
  "Add user CRUD API endpoints"

Files to commit:
  M src/api/users.ts
  A src/utils/errors.ts
  M src/routes/index.ts

Excluded (committed at /feature-end):
  M work/features/my-feature/tasks.md

═══════════════════════════════════════════════════════
→ Proceed? (yes / edit / no)
═══════════════════════════════════════════════════════
```

### 4. Handle User Response

- **"yes"** → Stage all changes and create commit
- **"edit"** → Ask user for their preferred commit message, then commit
- **"no"** → Cancel, no commit made

### 5. Execute Commit

```bash
# Stage all changes EXCEPT work/features/
git add -A
git reset HEAD -- work/features/

# Commit only the staged changes
git commit -m "<message>"
```

After successful commit, show:
```
✓ Committed: "<commit message>"
  <short hash> | <number> files changed
```

## Error Handling

**Not in a feature worktree:**
```
Error: This command should be run in a feature worktree.

You are in: [current directory]
Run /feature-prep first to set up a worktree.
```

**No changes to commit:**
```
Nothing to commit - working tree is clean.

All changes have already been committed.
```

**Only feature files changed:**
```
No code changes to commit.

Only work/features/ files have changed (tasks.md, etc.).
These are committed automatically during /feature-end.

Continue working on tasks, then run /feature-commit when you have code changes.
```

**No completed tasks found:**
```
No completed tasks found in tasks.md.

Complete some tasks first, then run /feature-commit.
```

## Extensions

Check for `.claude/claudeflow-extensions/feature-commit.md`. If it exists, read it and incorporate any additional instructions or workflow modifications.
