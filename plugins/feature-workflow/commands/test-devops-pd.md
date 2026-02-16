---
description: Test a DevOps PR - checkout branch, merge main, reinstall deps, run all app tests
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion, SlashCommand
---

# DevOps PR Testing Workflow

You are helping the user test a DevOps-related pull request (typically dependency updates like lodash, qs, etc.).

## Step 1: Get PR Number

The PR number is provided as an argument: $ARGUMENTS

If no argument is provided (empty), tell the user to run the command with a PR number:
```
Usage: /test-devops-pd <PR_NUMBER>
Example: /test-devops-pd 513
```
Then stop.

## Step 2: Fetch PR Branch Information

Once you have the PR number, use the GitHub CLI to get the branch name:

```bash
gh pr view {PR_NUMBER} --json headRefName,title,state
```

Parse the response to get:
- `headRefName` - The branch name to checkout
- `title` - Display to user for confirmation
- `state` - Verify it's OPEN

If the PR is not found or not OPEN, inform the user and stop.

## Step 3: Checkout the PR Branch

Fetch and checkout the branch:

```bash
git fetch origin {BRANCH_NAME} && git checkout {BRANCH_NAME}
```

If there are uncommitted changes, ask the user how to proceed:
- Options: "Stash changes", "Discard changes", "Abort"

## Step 4: Merge Main into the Branch

Merge the latest main branch:

```bash
git fetch origin main && git merge origin/main --no-edit
```

### Handle Merge Conflicts

If there are merge conflicts:
1. List conflicted files: `git diff --name-only --diff-filter=U`
2. For each conflicted file:
   - Read the file to understand the conflict
   - Resolve the conflict (typically for lock files or package.json, prefer accepting both changes or the newer versions)
   - Stage the resolved file: `git add {FILE}`
3. Commit the merge resolution:
   ```bash
   git commit -m "chore: merge main and resolve conflicts"
   ```

If merge succeeds without conflicts, continue to next step.

## Step 5: Run clean-modules.sh

Run the clean modules script to remove all node_modules and reinstall:

```bash
./clean-modules.sh
```

Use a timeout of 600000ms (10 minutes) as this can take a while.

Wait for completion and verify it succeeds.

## Step 6: Check and Commit Lock File Changes

Check if pnpm-lock.yaml has been modified:

```bash
git status --porcelain pnpm-lock.yaml
```

If pnpm-lock.yaml has changes (output is not empty):

1. Stage and commit:
   ```bash
   git add pnpm-lock.yaml && git commit -m "chore: update pnpm-lock.yaml"
   ```

2. Push the changes:
   ```bash
   git push
   ```

If no changes to lock file, inform user and continue.

## Step 7: Run test-all-apps

Execute the test-all-apps slash command to run the comprehensive app testing workflow:

Use the SlashCommand tool with command: "/test-all-apps"

This will guide the user through testing all frontend applications.

## Error Handling

- If any git command fails, show the error and ask user how to proceed
- If clean-modules.sh fails, show the error and ask if user wants to retry or abort
- If push fails (e.g., due to protected branch), inform user they may need to push manually

## Summary

At each major step, briefly inform the user what you're doing:
- "Checking out branch {BRANCH} for PR #{NUMBER}: {TITLE}"
- "Merging latest main..."
- "Running clean-modules.sh to reinstall dependencies..."
- "Lock file updated, committing and pushing..."
- "Starting comprehensive app testing..."
