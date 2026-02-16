# Feature Commit Extensions

## Never Commit work/ Directory

**CRITICAL:** Never commit any files in the `work/` directory. This includes:
- `work/features/*/reqs.md`
- `work/features/*/plan.md`
- `work/features/*/tasks.md`
- Any other files in `work/`

When staging files for commit:
1. **Always exclude `work/`** - Use `git add` with specific paths, never `git add .` or `git add -A`
2. **If work/ files are accidentally staged**, unstage them: `git reset HEAD work/`
3. **Before committing**, verify no work/ files are staged: `git diff --cached --name-only | grep -q "^work/" && echo "WARNING: work/ files staged!" || echo "OK"`

The `work/` directory contains local planning documents that should not be part of the repository history.
