---
description: Extensively test every app in the repo sequentially
---

# Manual Testing Workflow for All Apps

You are guiding the user through a comprehensive manual testing session for all frontend applications in the monorepo.

## Workflow Overview

1. Start `pnpm services#dev` in background (SSO + Mock Server)
2. Test apps that require SSO: legacy, main, uma, smart
3. Stop services#dev
4. Test apps that don't require SSO: backoffice, caden (use default port 3000)

## App Configuration

### Phase 1: Apps requiring SSO (services#dev running)

| App | Command | Port | URL | Notes |
|-----|---------|------|-----|-------|
| legacy | `pnpm main#dev` | 3005 | http://localhost:3005 | Started with main |
| main | `pnpm main#dev` | 3003 | http://localhost:3003/main/lists/guidelines/ | Started with legacy, not all pages migrated |
| uma | `pnpm uma#dev` | 3010 | http://localhost:3010 | |
| smart | `pnpm smart#dev` | 3006 | http://localhost:3006/tools/coding-care-dashboard | |

**Note:** `pnpm main#dev` starts BOTH the legacy app (port 3003) and main app (port 3005). Test them sequentially before stopping the process.

### Phase 2: Apps not requiring SSO (services#dev stopped)

| App | Command | Port | URL |
|-----|---------|------|-----|
| backoffice | `pnpm backoffice#dev` | 3000 | http://localhost:3000 |
| caden | `pnpm caden#dev` | 3000 | http://localhost:3000 |

## Execution Instructions

### Step 0: Pre-flight Environment Check

Before starting any services, verify the environment is ready for testing:

#### 0.1 Check Required Packages
Verify the following tools are installed by checking their availability:
```bash
command -v pnpm && command -v node && command -v git && command -v gh && command -v lsof && command -v curl && command -v python3
```

Required packages:
- `pnpm` - Package manager for running app scripts
- `node` - JavaScript runtime
- `git` - Version control
- `gh` - GitHub CLI for PR operations
- `lsof` - For checking ports in use
- `curl` - For HTTP requests in dev scripts
- `python3` - For JSON parsing in dev scripts

Optional packages (for specific features):
- `xmllint` - For XML parsing in dev-cerner script
- `tmux` - For proof recording popup

If any required packages are missing, list them and ask:
- "The following required packages are missing: {list}. Would you like me to install them?"
- Options: "Install missing packages" or "Skip (I'll install manually)"

If user selects "Install missing packages", attempt to install via Homebrew:
```bash
brew install {package_name}
```

#### 0.2 Check Ports in Use
Check if any of the required ports are already in use:
```bash
lsof -i :3000 -i :3001 -i :3003 -i :3006 -i :3010 | grep LISTEN
```

If any ports are in use, show the user which processes are using them and ask:
- "The following ports are in use: {list ports and process names}. Do you want to kill these processes?"
- Options: "Kill all" or "Skip (I'll handle it manually)"

If user selects "Kill all", kill the processes:
```bash
lsof -ti :3000 -ti :3001 -ti :3003 -ti :3006 -ti :3010 | xargs kill -9
```

#### 0.3 Check Dependencies
Run `pnpm install` status check:
```bash
# Check if node_modules exists and pnpm-lock.yaml is newer than node_modules
if [ ! -d "node_modules" ] || [ "pnpm-lock.yaml" -nt "node_modules" ]; then
  echo "Dependencies may be out of date"
fi
```
- If node_modules doesn't exist or pnpm-lock.yaml is newer, ask user: "Dependencies may need updating. Run `pnpm install`?"
- Options: "Run pnpm install" or "Skip (I know it's up to date)"

#### 0.4 Check Root .env Configuration
Compare root `.env` against `packages/@stn/dev-tools/config/env/root.env.staging`:
- Check if key environment variables match (STANSON_API, UMA_API, STANSON_AUTH_FRAME, etc.)
- If mismatch or `.env` doesn't exist, ask user: "Root .env doesn't match staging config. Run `pnpm setup-staging`?"
- Options: "Run setup-staging" or "Skip (keep current config)"

Key variables to check:
- `STANSON_API` should be `https://app-api.staging.stansonhealth.com/`
- `UMA_API` should be `https://uma-api.staging.stansonhealth.com/`
- `STANSON_AUTH_FRAME` should be `http://localhost:3000/`

#### 0.5 Check Backoffice .env
Compare `apps/backoffice/.env` against `packages/@stn/dev-tools/config/env/backoffice.env.dev`:
- Show diff if files differ
- Ask user: "Backoffice .env differs from branch template. Update to match template?"
- Options: "Update from template" or "Keep current"

#### 0.6 Check Caden .env
Compare `apps/caden/.env` against `packages/@stn/dev-tools/config/env/caden.env.dev`:
- Show diff if files differ
- Ask user: "Caden .env differs from branch template. Update to match template?"
- Options: "Update from template" or "Keep current"

#### 0.7 (Optional) Batch Update Multiple PRs
Ask user using AskUserQuestion: "Do you want to batch test multiple PRs together? (⚠️ UNTESTED)"
- Options: "Yes (experimental)" and "Skip"

If user selects "Yes":
1. Ask for a comma-separated list of PR numbers (e.g., "123, 456, 789")
2. Get the branch names for each PR using `gh pr view {pr_number} --json headRefName -q .headRefName`
3. Create a new combined branch from main:
   ```bash
   git fetch origin main
   git checkout -b batch-test-{timestamp} origin/main
   ```
4. Merge each PR branch into the combined branch:
   ```bash
   git fetch origin {branch_name}
   git merge origin/{branch_name} --no-edit
   ```
   - If merge conflicts occur, inform the user and ask how to proceed
5. Inform user: "Created batch branch with changes from PRs: {pr_list}"
6. **Skip step 0.8** (ticket step not needed for batch testing)

#### 0.8 (Optional) Add Ticket to PR Description
**Skip this step if batch update was selected in 0.7.**

Ask user using AskUserQuestion: "Do you want to add a ticket link to the PR description?"
- Options: "Yes" and "Skip"

If user selects "Yes":
1. Ask for ticket name (e.g., "STAN-1234: Fix patient search")
2. Ask for ticket URL (e.g., "https://stansonhealth.atlassian.net/browse/STAN-1234")
3. Get the current PR description using `gh pr view --json body -q .body`
4. Append the following to the PR description:
   ```
   ### Ticket
   [{ticket_name}]({ticket_url})

   ### Proof
   <!-- Add screenshots or recordings of your testing below -->
   ```
5. Update the PR using `gh pr edit --body "{updated_body}"`

**After all checks pass, proceed to Step 1.**

### Step 1: Start All Phase 1 Services

Start all Phase 1 services concurrently (they can all run at the same time):

1. **Start services#dev** using `run_in_background: true`:
   ```bash
   pnpm services#dev
   ```
   This starts SSO (port 3000) and Mock Server (port 3001).

2. **Start main#dev** using `run_in_background: true`:
   ```bash
   pnpm main#dev
   ```
   This starts both legacy (port 3005) and main (port 3003).

3. **Start uma#dev** using `run_in_background: true`:
   ```bash
   pnpm uma#dev
   ```

4. **Start smart#dev** using `run_in_background: true`:
   ```bash
   pnpm smart#dev
   ```

5. **Wait for all servers to be ready** - check output from each process until you see "Compiled successfully" or similar for each app.

**Note:** Keep track of all shell IDs - we won't stop these until after testing all Phase 1 apps.

### Step 2: Test Legacy App

1. **Display banner**:

```
════════════════════════════════════════════════════════════════════════

  🚀 LEGACY APP READY FOR TESTING

  ➜  Navigate to:  http://localhost:3005

  🔐 SSO Auth:     http://localhost:3000

════════════════════════════════════════════════════════════════════════
```

2. **Prompt user** using AskUserQuestion: "Select an option when done."
   - Options: "Done testing" and "Skip this app"

### Step 3: Test Main App

1. **Display banner**:

```
════════════════════════════════════════════════════════════════════════

  🚀 MAIN APP READY FOR TESTING

  ➜  Navigate to:  http://localhost:3003

  🔐 SSO Auth:     http://localhost:3000

  ℹ️  Not all pages are migrated yet. Start testing from:
      http://localhost:3003/main/lists/guidelines/

════════════════════════════════════════════════════════════════════════
```

2. **Prompt user** using AskUserQuestion: "Select an option when done."
   - Options: "Done testing" and "Skip this app"

### Step 4: Test UMA App

1. **Display banner**:

```
════════════════════════════════════════════════════════════════════════

  🚀 UMA APP READY FOR TESTING

  ➜  Navigate to:  http://localhost:3010

  🔐 SSO Auth:     http://localhost:3000

════════════════════════════════════════════════════════════════════════
```

2. **Prompt user** using AskUserQuestion: "Select an option when done."
   - Options: "Done testing" and "Skip this app"

3. **Collect tokens for SMART app**:
   - Display this banner:

```
════════════════════════════════════════════════════════════════════════

  📋 COLLECT TOKENS FROM UMA FOR SMART APP

  KEEP UMA OPEN! You need to copy tokens from UMA's localStorage.

  In UMA app (localhost:3010):
  1. Open DevTools (F12 or Cmd+Option+I)
  2. Go to Application > Local Storage > localhost:3010
  3. Find and copy these values:
     • Stanson.tokenId
     • Stanson.tokenRefreshTime

════════════════════════════════════════════════════════════════════════
```

   - Then use AskUserQuestion to collect the tokenId:
     - Question: "Paste the Stanson.tokenId value here (select 'Other' to type/paste)"
     - Options: ["Skip SMART app testing", "I'll paste it manually in SMART later"]
     - **IMPORTANT**: User can select "Other" to paste the actual token value
   - If user provides a token or selects "I'll paste it manually":
     - Use AskUserQuestion to collect the tokenRefreshTime:
       - Question: "Paste the Stanson.tokenRefreshTime value here (select 'Other' to type/paste)"
       - Options: ["Skip SMART app testing", "I'll paste it manually in SMART later"]
   - **Store the collected tokens** (if user pasted via "Other") for display in SMART step
   - If user selected "Skip SMART app testing" at any point, set a flag to skip Step 5

### Step 5: Test SMART App

**IMPORTANT:** If user selected "Skip SMART app testing" in Step 4, skip this entire step.

1. **Display banner with token instructions**:

```
════════════════════════════════════════════════════════════════════════

  🚀 SMART APP READY FOR TESTING

  ➜  Navigate to:  http://localhost:3006/tools/coding-care-dashboard

  🔐 SSO Auth:     http://localhost:3000

  ────────────────────────────────────────────────────────────────────

  📋 TOKENS FOR SMART APP localStorage:

  Open DevTools > Application > Local Storage > localhost:3006

  You need to set:
    • Stanson.smartToken (from UMA's Stanson.tokenId)
    • Stanson.smartTokenRefreshTime (from UMA's Stanson.tokenRefreshTime)

════════════════════════════════════════════════════════════════════════
```

2. **Prompt user with clipboard options** using AskUserQuestion:
   - Question: "Select an action for SMART app tokens:"
   - Options:
     - "Copy smartToken to clipboard" - Run `echo -n '{tokenId}' | pbcopy` then re-prompt
     - "Copy smartTokenRefreshTime to clipboard" - Run `echo -n '{refreshTime}' | pbcopy` then re-prompt
     - "Done testing" - Proceed to next step
     - "Skip this app" - Skip SMART and proceed

3. **When user selects a copy option:**
   - Use Bash tool to run `echo -n '{value}' | pbcopy`
   - Inform user: "Copied to clipboard! Paste into localStorage, then select another option."
   - Re-prompt with the same options

### Step 6: Stop Phase 1 Services

Stop all Phase 1 background processes using KillShell:
- Stop `pnpm smart#dev`
- Stop `pnpm uma#dev`
- Stop `pnpm main#dev`
- Stop `pnpm services#dev`

Inform the user: "Stopping all Phase 1 services. The remaining apps (backoffice, caden) don't require SSO."

### Step 7: Test Backoffice App

1. **Prompt user for dev script** using AskUserQuestion: "Which backoffice dev script should I run?"
   - Options: "dev-icr.sh" (from ~/.claude/scripts) and "Skip scripts"
2. **Start Backoffice and dev script concurrently**:
   - Start `pnpm backoffice#dev` with `run_in_background: true` (uses port 3000)
   - If user selected a script:
     - Copy the global script to the local scripts directory with a temp name:
       ```bash
       cp ~/.claude/scripts/dev-icr.sh apps/backoffice/scripts/dev-icr-temp.sh
       ```
     - **Display waiting message to user**:
       ```
       ⏳ Starting backoffice server and dev script...
          The browser will open shortly but may show an error until the server finishes compiling.
          This is normal - please wait for the "READY FOR TESTING" banner.
       ```
     - Start it with `run_in_background: true`:
       ```bash
       apps/backoffice/scripts/dev-icr-temp.sh
       ```
   - This runs both processes in parallel - the script will open Chrome while the server compiles
3. **Wait for compilation** - check backoffice output until you see "Compiled successfully"
4. **Capture script URL** - If dev script was run, check its output using BashOutput to capture the URL it generated. **IMPORTANT: Capture and display the FULL URL without truncation** - the URL contains auth tokens that must be complete.

5. **Display navigation banner**:

```
════════════════════════════════════════════════════════════════════════

  🚀 BACKOFFICE APP READY FOR TESTING

  ➜  Server running at:  http://localhost:3000

  ➜  Dev script URL (full, do not truncate):
      {FULL URL from dev-icr-temp.sh output - display on its own line if long}

  ℹ️  No SSO required - ICR script opened browser with auth token

════════════════════════════════════════════════════════════════════════
```
(Omit the "Dev script URL" line if no script was run)

6. **Prompt user** using AskUserQuestion: "Select an option when done."
   - Options: "Copy URL to clipboard", "Done testing", and "Skip this app"
   - If user selects "Copy URL to clipboard":
     - Run `echo -n '{full_dev_script_url}' | pbcopy`
     - Inform user: "URL copied to clipboard!"
     - Re-prompt with the same options
7. **Stop Backoffice** using KillShell
8. **Cleanup temp script** - If dev-icr-temp.sh was created, delete it:
   ```bash
   rm -f apps/backoffice/scripts/dev-icr-temp.sh
   ```

### Step 8: Test Caden App

1. **Prompt user for dev script** using AskUserQuestion: "Which Caden dev script should I run?"
   - Options: "dev-cerner.sh" (from ~/.claude/scripts, verified to work) and "Skip scripts"
2. **Start Caden and dev script concurrently**:
   - Start `pnpm caden#dev` with `run_in_background: true` (uses port 3000)
   - If user selected a script:
     - Copy the global scripts to the local scripts directory with temp names:
       ```bash
       cp ~/.claude/scripts/dev-cerner.sh apps/caden/scripts/dev-cerner-temp.sh
       cp ~/.claude/scripts/dev.sh apps/caden/scripts/dev-temp.sh
       ```
     - Update dev-cerner-temp.sh to call dev-temp.sh:
       ```bash
       sed -i '' 's|/dev.sh"|/dev-temp.sh"|' apps/caden/scripts/dev-cerner-temp.sh
       ```
     - Start it with `run_in_background: true`:
       ```bash
       apps/caden/scripts/dev-cerner-temp.sh
       ```
   - This runs both processes in parallel - the script will open the browser while the server compiles
3. **Wait for compilation** - check output until you see "Compiled successfully"
4. **Capture script URL** - If dev script was run, check its output using BashOutput to capture the URL it generated. **IMPORTANT: Capture and display the FULL URL without truncation** - the URL contains auth tokens that must be complete.

5. **Display navigation banner**:

```
════════════════════════════════════════════════════════════════════════

  🚀 CADEN APP READY FOR TESTING

  ➜  Server running at:  http://localhost:3000

  ➜  Dev script URL (full, do not truncate):
      {FULL URL from dev-cerner-temp.sh output - display on its own line if long}

  ℹ️  No SSO required - dev script opened browser with auth token

════════════════════════════════════════════════════════════════════════
```
(Omit the "Dev script URL" line if no script was run)

6. **Prompt user** using AskUserQuestion: "Select an option when done."
   - Options: "Copy URL to clipboard", "Done testing", and "Skip this app"
   - If user selects "Copy URL to clipboard":
     - Run `echo -n '{full_dev_script_url}' | pbcopy`
     - Inform user: "URL copied to clipboard!"
     - Re-prompt with the same options
7. **Stop Caden** using KillShell
8. **Cleanup temp scripts** - If temp scripts were created, delete them:
   ```bash
   rm -f apps/caden/scripts/dev-cerner-temp.sh apps/caden/scripts/dev-temp.sh
   ```

### Error Handling

- If an app fails to start, inform the user and ask if they want to skip or retry
- If services fail to start, stop the workflow and report the error
- Track which apps were successfully tested vs skipped

### Summary

At the end, provide a summary:
- Which apps were tested
- Which apps were skipped
- Any errors encountered

**If any tests failed:**

Ask user using AskUserQuestion: "Would you like to post this test summary to the PR?"
- Options: "Yes" and "No"

If user selects "Yes", post a comment to the PR using:
```bash
gh pr comment --body "$(cat <<'EOF'
## Test Summary

### ✅ Apps Tested Successfully
{list of successful apps}

### ⏭️ Apps Skipped
{list of skipped apps}

### ❌ Errors Encountered
{list of errors}

---
🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 9: (Optional) Run Proof Recording

1. **Check if TMUX is available**:
   ```bash
   echo $TMUX
   ```
   - If `$TMUX` is empty, skip this step entirely (don't ask the user)

2. **If TMUX is available**, ask user using AskUserQuestion: "Would you like to run `pnpm proof` to record testing proof?"
   - Options: "Yes" and "Skip"

3. **If user selects "Yes"**, open a TMUX popup and run the proof command:
   ```bash
   tmux popup -d "#{pane_current_path}" -w 80% -h 80% "pnpm proof"
   ```
   - This opens a centered popup window at 80% width/height in the current directory
   - The user can interact with the proof recording tool
   - The popup will close automatically when the command completes, or user can press `q` or `Ctrl-C` to exit

## Important Notes

- All Phase 1 servers (services#dev, main#dev, uma#dev, smart#dev) run concurrently
- Keep all Phase 1 servers running until legacy, main, uma, and smart are all tested
- `pnpm main#dev` starts BOTH legacy (port 3005) and main (port 3003)
- Stop all Phase 1 services before starting backoffice or caden (they use port 3000)
- Use BashOutput to check if processes are ready before prompting user
- Keep track of all shell IDs so you can clean up properly
