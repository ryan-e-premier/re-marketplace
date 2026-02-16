---
description: Continue merge after resolving conflicts
argument-hint: (none)
---

Continue feature merge after conflict resolution

## When to Use

This command should only be run after:
1. `/feature-end` detected merge conflicts
2. You manually resolved all conflicts
3. You staged the resolved files with `git add`

## Workflow

1. **Verify in main branch**
   - Check we're in the main project directory (not worktree)
   - Confirm there's a merge in progress: `git status`

2. **Check for unresolved conflicts**
   - Run: `git diff --check`
   - Look for conflict markers (<<<<<<, ======, >>>>>>)
   - If conflicts remain: show error and stop

3. **Verify files are staged**
   - Run: `git status`
   - Ensure all conflicted files are now staged
   - If unstaged conflicts exist: remind user to `git add` them

4. **Complete merge**
   - Run: `git merge --continue`
   - Use the commit message that was prepared
   - Or prompt for new commit message if needed

5. **Clean up worktree**
   - Detect which worktree we merged from
   - Run: `git worktree remove ../<project>.worktrees/<feature-name>`
   - Confirm successful removal

6. **Success message**
   ```
   ✓ Conflicts resolved and merged!
   
   Feature '<feature-name>' is now in main.
   
   Summary:
   - Merge completed successfully
   - Worktree deleted
   - You're now on main branch
   
   Next steps:
   - Test the merged feature
   - Push to remote: git push origin main
   - Start a new feature: /feature-start
   ```

## Error Messages

If no merge in progress:
```
Error: No merge in progress.

This command is only for completing a merge after resolving conflicts.
Did you already complete the merge, or haven't started one yet?
```

If conflicts still exist:
```
Error: Conflicts not fully resolved.

Remaining conflicts in:
- src/components/Header.tsx (line 45)
- src/lib/config.ts (line 12)

To resolve:
1. Open each file
2. Find and fix conflict markers (<<<<<<)
3. Save the file
4. Run: git add <filename>
5. Run: /feature-merge-continue again
```

If not in main:
```
Error: This command must be run in the main project directory.

Current location: [detected path]
Expected: Main project root (not a worktree)

After resolving conflicts in worktree, switch back to main before running this command.
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-merge-continue.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Important Notes

- This command is part of the `/feature-end` workflow
- Only use it when explicitly instructed after conflicts
- Cannot be undone - worktree will be deleted
- Ensure all tests pass after merge before pushing
