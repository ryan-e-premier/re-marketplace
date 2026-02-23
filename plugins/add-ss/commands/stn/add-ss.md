---
description: Capture Chrome screenshots and add them to the PR Screenshots section
---

# Add Screenshots to PR

Captures screenshots from Chrome tabs and uploads them to the `## Screenshots`
section of the open or draft PR for the current branch.

## Usage

- `/stn:add-ss` — Auto-detects the PR and asks which tab(s) to capture
- `/stn:add-ss login page` — Captures the tab whose title/URL best matches
  the description

---

## Step 1: Detect PR

Run:

```bash
gh pr view --json number,url,title,state,isDraft,body,headRepository
```

This returns all needed fields in one call. Parse:

- `number` — PR number
- `url` — full GitHub PR URL
- `title` — PR title
- `isDraft` — whether it is a draft PR
- `body` — current PR description (used in Step 2)
- `headRepository.owner.login` and `headRepository.name` — for API calls

Also capture `owner` and `repo` separately for use in `gh api` calls:

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

**If `gh pr view` fails or returns no PR:**

Display:

```text
═══════════════════════════════════════════════════════════════════════
⚠️  No PR Found
═══════════════════════════════════════════════════════════════════════

No open or draft pull request found for the current branch.

Create a PR first, then run /stn:add-ss to add screenshots.

═══════════════════════════════════════════════════════════════════════
```

Then exit.

---

## Step 2: Check for Screenshots Section

Scan the PR `body` from Step 1 for a Screenshots heading. Accept any of these
(case-insensitive):

- `## Screenshots`
- `### Screenshots`
- `## Screenshot`
- `### Screenshot`

**If no Screenshots section exists:**

Display:

```text
⚠️  No Screenshots section found in PR #<number>.

The PR description doesn't contain a "## Screenshots" heading.
Add the heading to your PR description where you want screenshots
to appear, then run /stn:add-ss again.
```

Then exit. Do NOT add the heading automatically — the user controls PR body
structure.

**If a Screenshots section exists:** note the exact heading text and line
position. Continue.

---

## Step 3: Get Chrome Context

Call `tabs_context_mcp` to get all available tabs. If the MCP tab group does
not exist yet, pass `createIfEmpty: true`.

**If Chrome is not reachable / no tabs are available:**

```text
⚠️  Could not connect to Chrome.

Make sure Chrome is open and the Claude in Chrome extension is active,
then run /stn:add-ss again.
```

Then exit.

---

## Step 4: Select Tab(s) to Capture

**If an argument was provided** (e.g., `/stn:add-ss login page`):

Search the available tabs for a title or URL that contains the argument text
(case-insensitive). Use the first match. If no match is found, fall through to
the interactive selection below.

**Otherwise**, use `AskUserQuestion` to let the user pick which tab(s) to
capture:

```text
question: "Which tab(s) should I screenshot?"
header: "Tabs"
multiSelect: true
options: one entry per tab — label = tab title (truncated to 50 chars),
         description = URL (truncated to 80 chars)
```

Allow selecting multiple tabs. Screenshots are added to the PR in selection
order.

---

## Step 5: Navigate to PR Comment Box

Before taking any screenshots, set up the upload target so screenshots can be
uploaded immediately after capture — image IDs expire quickly and must be used
before moving to the next tab.

### 5a. Navigate to PR page

Using one of the available Chrome tabs (prefer the MCP tab; create one if
needed), navigate to the PR URL from Step 1. Wait for the page to load.

### 5b. Locate the comment box textarea

Find the main "Leave a comment" textarea at the bottom of the PR thread. Use
`find` with query `"leave a comment textarea"` or try via `javascript_tool`:

```javascript
document.querySelector(
  '#new_comment_field, ' +
  'textarea[name="comment[body]"], ' +
  '.js-new-comment-form textarea'
)
```

### 5c. Locate the file attachment input

GitHub's comment form has a hidden `<input type="file">` for attachments. Use
`find` with query `"attach files file input"` or locate it via
`javascript_tool`:

```javascript
document.querySelector(
  '.js-new-comment-form input[type="file"], ' +
  'form[action*="comments"] input[type="file"]'
)
```

Store the ref for the file input — it will be reused for every upload.

---

## Step 6: Capture and Upload Each Screenshot Immediately

**Process each selected tab one at a time.** For each tab, take the screenshot
and upload it before moving on. Do not batch screenshots — image IDs expire
quickly and must be used right away.

For tab N:

1. **Switch to the target tab** using `computer` with `action: "screenshot"`
   and the tab's ID to capture it. Note the returned image ID.

2. **Immediately upload** via `upload_image`:
   - `imageId`: the image ID just captured
   - `ref`: the file input ref from Step 5c
   - `filename`: `screenshot-<N>.png`

3. **Wait ~3 seconds** for GitHub to process the upload.

4. **Extract the CDN URL** by reading the textarea value via `javascript_tool`:

   ```javascript
   document.querySelector(
     '#new_comment_field, textarea[name="comment[body]"]'
   ).value
   ```

   GitHub appends something like:

   ```text
   ![screenshot-1](https://github.com/owner/repo/assets/12345/uuid.png)
   ```

   Extract the full `![...](...)`  markdown string. If it doesn't appear
   after ~5 seconds (re-check once), warn and skip that screenshot.

5. **Store** the extracted image markdown.

6. **Clear the textarea** so the next upload's markdown is easy to isolate:

   ```javascript
   const ta = document.querySelector(
     '#new_comment_field, textarea[name="comment[body]"]'
   );
   ta.value = '';
   ta.dispatchEvent(new Event('input', { bubbles: true }));
   ```

7. Repeat for the next tab.

**Do NOT click the submit/comment button at any point.**

If a screenshot capture fails for a tab, log a warning and continue with the
next tab.

If **no** CDN URLs were collected at all:

```text
⚠️  No screenshots were captured. Nothing was added to the PR.
```

Then exit.

---

## Step 7: Build Updated PR Body

All image markdown strings are now collected. Construct the new PR body
in memory using the `body` from Step 1:

1. Locate the Screenshots heading line (found in Step 2).

2. Find the insertion point: the line immediately after the heading and any
   blank line that directly follows it, but before any existing content in
   the section or the next `##`/`###` heading.

3. Insert all collected image markdown strings at that point, each on its
   own line separated by a blank line.

4. Leave all other content in the body unchanged.

**Example — before:**

```text
## Screenshots

_No screenshots yet_

## Notes
```

**After (one screenshot uploaded):**

```text
## Screenshots

![screenshot-1](https://github.com/owner/repo/assets/...)

_No screenshots yet_

## Notes
```

---

## Step 8: Confirm and Update PR via API

Ask the user for confirmation before writing:

Use `AskUserQuestion`:

```text
question: "Add <N> screenshot(s) to PR #<number>?"
header: "Update PR"
options:
  - label: "Update"
    description: "Write the new body via gh api"
  - label: "Cancel"
    description: "Abort — no changes will be made"
multiSelect: false
```

**If "Cancel":** inform the user that nothing was changed and exit.

**If "Update":** write the new body to a temp file and PATCH via `gh api`:

```bash
printf '%s' "<new_body>" \
  | jq -Rs '{"body": .}' \
  > /tmp/add-ss-body.json

gh api repos/<owner>/<repo>/pulls/<number> \
  -X PATCH \
  --input /tmp/add-ss-body.json
```

Using `jq -Rs` to build the JSON payload ensures the body is correctly
escaped regardless of newlines or special characters.

Clean up the temp file after the API call:

```bash
rm -f /tmp/add-ss-body.json
```

---

## Step 9: Confirm

Display:

```text
✅ Screenshots added to PR #<number>

   <pr_title>
   <pr_url>

   Added <count> screenshot(s) to the Screenshots section.
```

---

## Error Handling

### Upload produces no image markdown

If the textarea does not contain an image URL after ~5 seconds:

```text
⚠️  Screenshot <N> upload may have failed — no GitHub URL was detected.
    You can attach it manually to the PR.
```

Continue with any remaining screenshots.

### Chrome not connected

If `tabs_context_mcp` fails or returns no usable tabs, instruct the user to
open Chrome with the Claude in Chrome extension active and retry.

### `gh api` PATCH fails

Display the error output from `gh api` verbatim so the user can diagnose it
(auth issue, network, etc.). Do not silently swallow the error.

### No CDN URLs were collected

If all uploads failed and no image markdown was captured:

```text
⚠️  No screenshots were successfully uploaded. The PR was not modified.
```

Then exit without calling `gh api`.

---

## Notes

- Works with both open and draft PRs.
- The PR comment box is used only as a temporary upload target to obtain
  GitHub CDN URLs; no comment is ever submitted.
- The PR description is updated entirely via `gh api` — no GitHub web UI
  editing required.
- When multiple tabs are selected the screenshots appear in the order they
  were selected.
