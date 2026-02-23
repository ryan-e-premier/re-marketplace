# add-ss

Capture Chrome screenshots and add them to the `## Screenshots` section of
the open or draft PR for the current branch.

## Command

```text
/stn:add-ss [tab description]
```

- `/stn:add-ss` — Detects the PR, lists open Chrome tabs, asks which to
  capture
- `/stn:add-ss login flow` — Captures the Chrome tab whose title/URL best
  matches the description

## Features

- **Auto PR detection** — finds the open or draft PR for the current branch
  using `gh pr view`; displays a clear message if none exists
- **Screenshots section check** — verifies a `## Screenshots` (or
  `### Screenshots`) heading exists in the PR body before proceeding
- **Multi-tab capture** — lists all open Chrome tabs and lets you pick one
  or more; captures them in order
- **GitHub-hosted images** — uploads screenshots via the PR's comment box to
  get GitHub CDN URLs; no external hosting needed
- **API-only PR update** — the PR description is updated with `gh api PATCH`,
  not by navigating the GitHub web editor
- **Confirm before update** — always asks before calling `gh api`

## Requirements

- `gh` (GitHub CLI) authenticated with your account
- `jq` for JSON payload construction
- Chrome open with the
  [Claude in Chrome](https://github.com/anthropics/claude-in-chrome) extension
  active

## How It Works

### Step 1: Detect PR

Uses `gh pr view` to find any open or draft PR for the current branch. Exits
early with a helpful message if none is found.

### Step 2: Verify Screenshots Section

Reads the current PR body and checks for a `## Screenshots` or
`### Screenshots` heading. If absent, asks you to add the heading first —
the command never silently modifies your PR structure.

### Step 3: Select Tabs

Lists all open Chrome tabs via the Claude in Chrome extension. You can
multi-select the tabs you want captured. If you pass a description argument
(e.g., `/stn:add-ss dashboard`), it matches the best tab automatically.

### Step 4: Set Up Upload Target

Navigates to the GitHub PR page and locates the "Leave a comment" box at the
bottom of the thread. This is used as a temporary upload target to obtain
GitHub CDN URLs — **no comment is ever submitted**.

### Step 5: Capture & Upload (one tab at a time)

For each selected tab: takes the screenshot and immediately uploads it to the
comment box file input before moving on. The GitHub CDN URL is extracted from
the image markdown GitHub inserts into the textarea, then the textarea is
cleared. Screenshot image IDs are short-lived, so capture and upload happen
back-to-back for each tab.

### Step 6: Update PR via API

Builds the new PR body in memory by inserting the image markdown into the
Screenshots section, then runs:

```bash
gh api repos/{owner}/{repo}/pulls/{number} -X PATCH --input /tmp/add-ss-body.json
```

Asks for your confirmation before making the API call.

## Example Output

```text
✅ Screenshots added to PR #42

   feat: add dark mode toggle
   https://github.com/org/repo/pull/42

   Added 2 screenshot(s) to the Screenshots section.
```
