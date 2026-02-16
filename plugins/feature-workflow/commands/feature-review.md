---
description: Quick status check on current feature
argument-hint: [name]
---

Review feature status: $ARGUMENTS

## Purpose

Quick way to see where you are without starting work. Shows summary and task progress.

## Workflow

1. **Identify feature** (same auto-detection as other commands)
2. **Read `tasks.md`**
3. **Output status:**

```
## Feature: <feature-name>

### Summary
<summary section from tasks.md>

### Progress
- Completed: 3/8 tasks (TSK1, TSK2, TSK3)
- Next: TSK4 - <next task description>

### Files changed
<git status --short if any uncommitted changes>
```

## Extensions

Check for `.claude/claudeflow-extensions/feature-review.md`.
