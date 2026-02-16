# Feature Workflow Plugin

Complete feature development lifecycle with git worktrees, planning, task
management, testing, and Docker integration.

## Overview

This plugin implements a git worktree-based feature development workflow that
isolates each feature in its own directory with integrated task management,
testing workflows, and Docker support.

## Commands

### Core Workflow

- `/feature-start` - Start a new feature by creating requirements document
- `/feature-prep` - Prepare feature for development (create worktree, task
  list)
- `/feature-plan` - Create implementation plan for a feature
- `/feature-build` - Build feature by implementing tasks one at a time
- `/feature-commit` - Commit feature progress with context-aware message
- `/feature-review` - Quick status check on current feature
- `/feature-end` - Complete feature (commit, merge to main, cleanup)
- `/feature-help` - Explain the feature development workflow

### Docker Management

- `/feature-docker` - Manage Docker environment for current feature

### Merge & Conflict Resolution

- `/feature-merge-continue` - Continue merge after resolving conflicts

### Testing

- `/test-all-apps` - Extensively test every app in the repo sequentially
- `/test-devops-pd` - Test a DevOps PR (checkout branch, merge main, reinstall
  deps, run tests)

### Package Management

- `/update-packages` - Update npm packages in pnpm monorepo with version
  tracking and migration docs

### ClaudeFlow Customization

- `/claudeflow-extend` - Initialize extension files for customizing claudeflow
  commands

## Workflow

### 1. Start Feature

```bash
/feature-start
```

Creates a requirements document defining the feature scope, goals, and
acceptance criteria.

### 2. Prepare Development

```bash
/feature-prep
```

Creates a git worktree for isolated development and generates a task list from
requirements.

### 3. Plan Implementation

```bash
/feature-plan
```

Analyzes requirements and creates a detailed implementation plan.

### 4. Build Feature

```bash
/feature-build
```

Implements tasks one at a time with focused commits per task.

### 5. Review Progress

```bash
/feature-review
```

Quick status check showing current task, completion progress, and recent
commits.

### 6. Complete Feature

```bash
/feature-end
```

Final commit, merge to main, and cleanup worktree.

## Git Worktrees

Each feature gets its own isolated directory:

```
main-repo/           # Main working directory
feature-foo/         # Feature worktree
feature-bar/         # Another feature worktree
```

Benefits:

- Work on multiple features simultaneously
- No branch switching disruption
- Independent dependency installations
- Parallel testing environments

## ClaudeFlow Extensions

The plugin includes ClaudeFlow extension templates in the `extensions/`
directory:

- `feature-plan.md` - Custom implementation planning
- `feature-prep.md` - Custom worktree and task setup
- `feature-build.md` - Custom build workflow
- `feature-commit.md` - Custom commit message generation
- `feature-end.md` - Custom completion workflow

Use `/claudeflow-extend` to initialize these extensions in your project.

## Requirements

- Git
- tmux (recommended for parallel work)
- Docker (optional, for `/feature-docker`)
- pnpm (for `/update-packages`)

## Tips

- Use `/feature-help` to see workflow overview anytime
- Commit frequently with `/feature-commit` for granular history
- Review progress with `/feature-review` before `/feature-end`
- Run `/test-all-apps` before completing features
- Use ClaudeFlow extensions to customize the workflow for your project

## License

MIT
