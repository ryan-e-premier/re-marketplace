# add-ss

Capture Chrome screenshots and save them to disk, ready to drag into the
`## Screenshots` section of the open or draft PR for the current branch.

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
  as data URLs saved to disk; falls back to `screencapture` if html2canvas
  is blocked
- **Opens PR and Finder** — navigates Chrome to the PR and opens Finder to
  the screenshot folder so you can drag files straight in

## Requirements

- `gh` (GitHub CLI) authenticated with your account
- `python3` for base64 decoding (pre-installed on macOS)
- Chrome open with the
  [Claude in Chrome](https://github.com/anthropics/claude-in-chrome) extension
  active

## How It Works

1. Detects the PR for the current branch via `gh pr view`
2. Checks that a `## Screenshots` heading exists in the PR body
3. Lists Chrome tabs for you to select (or auto-matches from an argument)
4. Captures each tab using html2canvas → data URL → saved as
   `/tmp/add-ss-pr-{number}/screenshot-N.jpg`
5. Navigates Chrome to the PR page and scrolls to the Screenshots section
6. Opens Finder to `/tmp/add-ss-pr-{number}/`
7. Tells you to drag the files into the PR description editor

GitHub handles the upload and CDN hosting when you drop the files in.

## Example Output

```text
📸 Screenshots saved — drag them into the PR

   Files:
     /tmp/add-ss-pr-42/screenshot-1.jpg
     /tmp/add-ss-pr-42/screenshot-2.jpg

   The PR is open in Chrome. Drag the file(s) above into the
   "## Screenshots" section of the PR description and click Save.
```
