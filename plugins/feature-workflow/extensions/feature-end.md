# Feature End Extensions

## Never Commit work/ Directory

**CRITICAL:** Never commit any files in the `work/` directory. This includes:
- `work/features/*/reqs.md`
- `work/features/*/plan.md`
- `work/features/*/tasks.md`
- Any other files in `work/`

When committing final changes before PR/merge:
1. **Always exclude `work/`** - Use `git add` with specific paths, never `git add .` or `git add -A`
2. **If work/ files are accidentally staged**, unstage them: `git reset HEAD work/`
3. **Before committing**, verify no work/ files are staged: `git diff --cached --name-only | grep -q "^work/" && echo "WARNING: work/ files staged!" || echo "OK"`

The `work/` directory contains local planning documents that should not be part of the repository history.

## Skip Docker Steps

**Do NOT** check for running Docker containers or prompt to stop them. Skip step 1 ("Check for running Docker containers") in Phase 1 entirely. Proceed directly to showing the summary.

## Create PR Instead of Merging to Main

This extension modifies the default behavior of `/feature-end` to create a Pull Request instead of directly merging to main when the `git-manager` agent is available.

### Check for git-manager Agent

Before completing the feature, check if the `git-manager` MCP server/agent is available:

```bash
# Check if git-manager is configured in MCP settings
cat ~/.claude/settings.json 2>/dev/null | grep -q "git-manager" && echo "available" || echo "not-available"
```

Alternatively, check the project's local MCP configuration:

```bash
cat .mcp.json 2>/dev/null | grep -q "git-manager" && echo "available" || echo "not-available"
```

### Behavior Based on git-manager Availability

#### If git-manager IS Available

**Do NOT merge to main.** Instead, create a Pull Request:

1. **Ensure all changes are committed** - Commit any uncommitted work first
2. **Push the feature branch to remote**:
   ```bash
   git push -u origin <feature-branch-name>
   ```
3. **Create the Pull Request** using the git-manager agent:
   - Use the `mcp__git-manager__create_pull_request` tool (or equivalent)
   - Set the base branch to `main`
   - Set the head branch to the current feature branch
   - Generate a descriptive title from the feature name
   - Include a summary of changes in the PR body

4. **Inform the user**:
   > "Created PR #<number> for feature '<feature-name>'. The worktree has been preserved so you can continue working or address review feedback. Run `/feature-end` again after the PR is merged to clean up the worktree."

5. **Do NOT delete the worktree** - Keep it available for potential changes based on PR feedback

6. **Do NOT switch back to main** - Stay in the feature worktree

#### If git-manager is NOT Available

Notify the user and ask how to proceed using `AskUserQuestion`:

**Question:** "The git-manager agent is not available. How would you like to complete this feature?"

**Options:**
1. **Merge to main** - Proceed with the default behavior (merge to main and cleanup)
2. **Create PR manually** - Push the branch and provide instructions for manual PR creation
3. **Cancel** - Do nothing and stay in the current state

##### Option: Create PR Manually

If the user selects manual PR creation:

1. **Push the feature branch**:
   ```bash
   git push -u origin <feature-branch-name>
   ```

2. **Provide the PR creation URL**:
   > "Branch pushed to remote. Create your PR at: https://github.com/<owner>/<repo>/compare/main...<feature-branch-name>"

   Get the repo URL with:
   ```bash
   git remote get-url origin | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//'
   ```

3. **Keep the worktree** - Do not delete until PR is merged

### PR Content Template

When creating a PR (either via git-manager or providing manual instructions), use this format:

**Title:** `feat: <feature-name>` or derive from the feature description

**Body:**
```markdown
## Summary

<Brief description of what this feature does>

## Changes

<List of main changes/files modified>

## Testing

<How the feature was tested, if applicable>

---
*Created via ClaudeFlow `/feature-end`*
```

### Post-PR Workflow Note

After the PR is created, inform the user:

> "Next steps:
> - Review and merge the PR on GitHub
> - After merging, run `/feature-end` again to clean up the worktree
> - Or continue working in this worktree if changes are needed"
