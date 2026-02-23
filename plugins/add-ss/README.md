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
- **No imageId expiry** — captures pages via `javascript_tool` + html2canvas
  as data URLs, bypassing the time-sensitive screenshot imageId mechanism
  entirely
- **Branch-hosted images** — screenshots are committed to
  `.github/screenshots/pr-{number}/` on the current branch and referenced
  via `raw.githubusercontent.com`; no external service needed
- **API-only PR update** — the PR description is updated with `gh api PATCH`,
  not by navigating the GitHub web editor
- **Confirm before update** — always asks before patching the PR

## Requirements

- `gh` (GitHub CLI) authenticated with your account
- `jq` for JSON payload construction
- `python3` for base64 decoding (pre-installed on macOS)
- Chrome open with the
  [Claude in Chrome](https://github.com/anthropics/claude-in-chrome) extension
  active

## How It Works

### Step 1: Detect PR

Uses `gh pr view` to find any open or draft PR for the current branch. Exits
early with a helpful message if none is found.

### Step 2: Verify Screenshots Section

Reads the current PR body and checks for a `## Screenshots` or
`### Screenshots` heading. If absent, tells you to add it first — the command
never silently modifies your PR structure.

### Step 3: Select Tabs

Lists all open Chrome tabs via the Claude in Chrome extension. You can
multi-select tabs. If you pass a description argument (e.g.,
`/stn:add-ss dashboard`), it matches the best tab automatically.

### Step 4: Capture via javascript_tool

For each selected tab, injects
[html2canvas](https://html2canvas.hertzen.com/) into the page and captures
the visible viewport as a JPEG data URL. The data URL is returned directly
to Claude — no imageId, no expiry risk.

### Step 5: Save and Commit

Decodes each data URL to a `.jpg` file on disk, copies it to
`.github/screenshots/pr-{number}/`, and commits + pushes in a single
`chore: add screenshots` commit.

### Step 6: Update PR via API

Builds the new PR body with `raw.githubusercontent.com` image URLs inserted
at the top of the Screenshots section, then runs:

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

   Screenshots committed to:
   .github/screenshots/pr-42/
```

## Note on Committed Screenshots

Screenshot files are committed to `.github/screenshots/pr-{number}/` on
your branch. You can squash or drop this commit before merging if you prefer
a clean history, or add `.github/screenshots/` to `.gitignore` and host the
images elsewhere.
