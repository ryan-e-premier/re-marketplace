---
description: Update npm packages in pnpm monorepo with version tracking and migration docs
---

# Update Packages

Update npm packages across a pnpm monorepo with version tracking, build validation, and migration documentation.

## Prerequisites

1. **Verify pnpm monorepo**
   - Check for `pnpm-workspace.yaml` in current directory
   - If not found, show error and stop:
     ```
     Error: No pnpm-workspace.yaml found.
     This command must be run from the root of a pnpm monorepo.
     ```

2. **Check for uncommitted changes**
   - Run `git status --porcelain`
   - If changes exist, warn user:
     ```
     Warning: You have uncommitted changes.
     Package updates will modify package.json and pnpm-lock.yaml.
     ```
   - Ask user: "Continue anyway?" (yes/no)

3. **Ensure dependencies are installed**
   - **CRITICAL: Run `pnpm install` before checking for updates**
   - This ensures the lockfile is up to date and accurate version information is available
   - If packages show as "missing" in the outdated output, this step was skipped

## Workflow

### Step 1: Install Dependencies First

**Always run `pnpm install` before checking for updates:**

```bash
pnpm install
```

This ensures:
- All packages are installed
- The lockfile is synchronized
- Accurate version information is available for comparison

### Step 2: Show Current Package Status

**Run the pnpm-outdated-summary script to display a color-coded summary:**

```bash
~/.claude/scripts/pnpm-outdated-summary.sh
```

**About the script:**
- Located at `~/.claude/scripts/pnpm-outdated-summary.sh`
- Runs `pnpm -r outdated` internally (checks ALL workspaces)
- Parses the output and categorizes packages into:
  - **Deprecated** (yellow) - Packages marked as deprecated
  - **Safe Updates** (green) - Patch and minor version updates
  - **Major Updates** (red) - Major version updates with potential breaking changes
- Shows which workspaces use each package
- Displays summary counts at the bottom

If the script shows "All packages are up to date! Nothing to update.", stop here.

### Step 3: Capture Pre-Update State for Migration Doc

The output from Step 2 serves as the pre-update state. Save this information to generate the migration document later.

### Step 4: Select Update Type

Use AskUserQuestion with the following configuration:

**Question:** "Which types of updates would you like to apply?"

**Options (multiSelect: true):**
1. **Safe updates** - "Updates to 'Wanted' version (within semver ranges). Includes patch and minor updates."
2. **Major updates** - "Updates to 'Latest' version (may include breaking changes)."

### Step 5: Execute Updates

Based on user selection, run the appropriate command:

| Selection | Command |
|-----------|---------|
| Safe only | `pnpm -r update` |
| Major only | `pnpm -r update --latest` |
| Both | `pnpm -r update --latest` |

Display progress with colors:
```
\033[1;96m═══════════════════════════════════════════════════════\033[0m
\033[1;96m  UPDATING PACKAGES\033[0m
\033[1;96m═══════════════════════════════════════════════════════\033[0m

\033[2mRunning:\033[0m pnpm -r update [--latest]
```

Stream the command output to the user.

### Step 6: Capture Post-Update State

Run `pnpm -r outdated` again to see what packages still need updates (if any).

Compare before/after to determine:
- Which packages were updated
- Old version → New version
- Update type (patch/minor/major)

### Step 7: Build Validation

Display with colors:
```
\033[1;96m═══════════════════════════════════════════════════════\033[0m
\033[1;96m  VALIDATING BUILDS\033[0m
\033[1;96m═══════════════════════════════════════════════════════\033[0m

\033[2mRunning build validation (tests skipped)...\033[0m
```

Run build commands sequentially. Check if these proof scripts exist first:
```bash
pnpm proof-packages && pnpm proof-apps && pnpm proof-caden-apps
```

If proof scripts don't exist, fall back to:
```bash
pnpm build
```

**If builds fail:**
- Show error output
- Use AskUserQuestion: "Builds failed. What would you like to do?"
  - Options:
    - "View detailed logs" - Show more context from proof_logs/ if available
    - "Revert all changes" - Run `git checkout -- . && pnpm install`
    - "Continue anyway" - Proceed to generate migration doc with failure noted

**If builds pass:**
```
\033[1;32m✓ Build validation passed.\033[0m
```

### Step 7b: ESLint Validation

After builds pass, run ESLint to check for linting errors:

Display with colors:
```
\033[1;96m═══════════════════════════════════════════════════════\033[0m
\033[1;96m  VALIDATING ESLINT\033[0m
\033[1;96m═══════════════════════════════════════════════════════\033[0m

\033[2mRunning ESLint validation...\033[0m
```

Run:
```bash
pnpm lint
```

**If ESLint fails:**
- Show error output
- Fix all ESLint errors before proceeding
- Common issues after package updates:
  - New rules enabled in updated ESLint plugins
  - Deprecated rule configurations
  - Type inference changes causing new lint errors

**If ESLint passes:**
```
\033[1;32m✓ ESLint validation passed.\033[0m
```

### Step 8: Generate Migration Document with Researched Migration Steps

Create file: `PACKAGE_UPDATES_<YYYY-MM-DD>.md` in the **current workspace root** (not necessarily the git root).

**CRITICAL: Research migration steps for each updated package:**

For each package that was updated, use WebSearch and/or WebFetch to research:
1. The package's changelog or release notes
2. Any breaking changes between the old and new versions
3. Migration guides if available (especially for major updates)
4. Common issues or gotchas reported by users

**Research sources by package pattern:**

| Package Pattern | Research Sources |
|-----------------|------------------|
| @babel/* | https://github.com/babel/babel/releases, https://babeljs.io/blog |
| @testing-library/* | https://github.com/testing-library/{name}/releases |
| @mui/* | https://mui.com/material-ui/migration/, https://github.com/mui/material-ui/releases |
| @tanstack/react-query | https://tanstack.com/query/latest/docs/react/guides/migrating-to-v5 |
| react, react-dom | https://react.dev/blog, https://github.com/facebook/react/releases |
| typescript | https://devblogs.microsoft.com/typescript/, https://github.com/microsoft/TypeScript/releases |
| eslint | https://eslint.org/blog/, https://github.com/eslint/eslint/releases |
| vite | https://vite.dev/guide/migration, https://github.com/vitejs/vite/releases |
| vitest | https://vitest.dev/guide/migration, https://github.com/vitest-dev/vitest/releases |
| axios | https://github.com/axios/axios/releases, https://axios-http.com/docs/migrating |
| Other | https://www.npmjs.com/package/{name}, search "{package} {version} migration guide" |

**Document structure:**

```markdown
# Package Updates - <Month Day, Year>

## Summary

| Metric | Value |
|--------|-------|
| Update Type | Safe / Major / Both |
| Packages Updated | X |
| Build Validation | Passed / Failed |
| Generated | <timestamp> |

---

## Updates by Package

### @babel/core

**Version:** 7.23.4 → 7.24.0 (minor)

**Changelog:** [GitHub Releases](https://github.com/babel/babel/releases/tag/v7.24.0)

**Migration Notes:**
- [Researched notes about what changed in this version]
- [Any deprecations or new features]
- [Required code changes if any]

**Action Required:** None / Review recommended / Code changes needed

---

### @mui/material

**Version:** 5.15.0 → 6.0.0 (MAJOR)

**Changelog:** [GitHub Releases](https://github.com/mui/material-ui/releases/tag/v6.0.0)

**Migration Guide:** [MUI v6 Migration](https://mui.com/material-ui/migration/migration-v5/)

**Breaking Changes:**
- [Specific breaking change 1 with code example if applicable]
- [Specific breaking change 2]
- [etc.]

**Migration Steps:**
1. [Step 1 - specific action to take]
2. [Step 2 - specific action to take]
3. [etc.]

**Action Required:** Code changes needed

---

[...continue for each updated package...]

---

## Packages with No Migration Required

These packages were updated with no breaking changes or required actions:
- package-a (1.0.0 → 1.0.1) - patch
- package-b (2.1.0 → 2.2.0) - minor, new features only
- [etc.]

---

## Build Validation Output

<details>
<summary>Click to expand build output</summary>

\`\`\`
[proof command output here]
\`\`\`

</details>

---

## Next Steps

1. [ ] Review packages marked "Code changes needed"
2. [ ] Apply migration steps for major updates
3. [ ] Run full test suite: `pnpm test`
4. [ ] Test affected features manually
5. [ ] Commit changes: `git add -A && git commit -m "chore(deps): update packages"`
6. [ ] Create PR for review
```

**Research priority:**
1. **Major updates** - Always research thoroughly, find migration guides
2. **Minor updates with deprecations** - Check for deprecated APIs
3. **Patch updates** - Quick scan for any security fixes or important notes
4. **Group related packages** - e.g., research all @babel/* together, all @mui/* together

### Step 9: Final Summary

Display with colors:
```
\033[1;32m═══════════════════════════════════════════════════════\033[0m
\033[1;32m  ✓ PACKAGE UPDATE COMPLETE\033[0m
\033[1;32m═══════════════════════════════════════════════════════\033[0m

\033[1mUpdated\033[0m \033[36mX packages\033[0m across \033[35mY workspaces\033[0m
\033[1mBuild validation:\033[0m \033[32mPassed\033[0m / \033[91mFailed\033[0m

\033[1mMigration document created:\033[0m
  \033[2m→\033[0m \033[36m./PACKAGE_UPDATES_<date>.md\033[0m

\033[1mFiles modified:\033[0m
  \033[33mM\033[0m package.json
  \033[33mM\033[0m pnpm-lock.yaml
  \033[33mM\033[0m apps/main/package.json
  \033[33mM\033[0m apps/uma/package.json
  \033[2m[etc.]\033[0m

\033[1mReview the migration document for:\033[0m
  \033[2m•\033[0m Changelog links for each package
  \033[2m•\033[0m Breaking changes in major updates
  \033[2m•\033[0m Build validation results

\033[1mSuggested commit:\033[0m
  \033[36mgit add -A && git commit -m "chore(deps): update packages"\033[0m

\033[1;32m═══════════════════════════════════════════════════════\033[0m
```

### Step 10: Offer to Continue with Next Steps

After displaying the final summary, use AskUserQuestion to offer help with the remaining tasks from the migration document:

**Question:** "Would you like to continue with any of the remaining tasks?"

**Options (multiSelect: true):**
1. **Run full test suite** - "Execute `pnpm test` to run all tests across the monorepo"
2. **Manual validation** - "Run /test-all-apps to extensively test every app in the repo"
3. **Commit changes** - "Stage and commit the package updates with a conventional commit message"
4. **Create PR** - "Create a pull request for the package updates"
5. **Done for now** - "I'll handle the remaining steps manually"

Based on user selection:
- **Run full test suite**: Execute `pnpm test` and report results
- **Manual validation**: Tell the user to run the `/test-all-apps` command to extensively test every app in the repo sequentially
- **Commit changes**: Run `git add -A && git commit -m "chore(deps): update packages"`
- **Create PR**: Use `gh pr create` with the migration document summary as the PR body
- **Done for now**: End the workflow

## Error Handling

**Not a pnpm monorepo:**
```
\033[1;91m✗ Error:\033[0m No pnpm-workspace.yaml found.
  This command must be run from the root of a pnpm monorepo.
```

**No updates available:**
```
\033[1;32m✓ All packages are up to date! Nothing to update.\033[0m
```

**User cancels due to uncommitted changes:**
```
\033[33m⚠ Update cancelled.\033[0m Commit or stash your changes first.
```

**Build failures with revert:**
```
\033[33m⚠ Reverting changes...\033[0m
\033[2mRunning:\033[0m git checkout -- . && pnpm install
\033[32m✓ Changes reverted.\033[0m No packages were updated.
```

**Packages showing as "missing":**
```
\033[33m⚠ Warning:\033[0m Some packages show as "missing". Running pnpm install first...
```
Then run `pnpm install` and re-run `pnpm outdated`.

## Important Notes

- **Always run `pnpm install` first** to ensure accurate version information
- This command does NOT run tests (only builds) for faster feedback
- Run `pnpm test` manually after reviewing the migration document
- The migration document is meant to be reviewed and then deleted (not committed)
- Always review major version updates carefully before deploying
