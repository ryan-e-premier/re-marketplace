---
description: Capture Chrome screenshots and add them to the PR Screenshots section
---

# Add Screenshots to PR

Captures screenshots from Chrome tabs and adds them to the `## Screenshots`
section of the open or draft PR for the current branch.

## Usage

- `/stn:add-ss` — Auto-detects the PR and asks which tab(s) to capture
- `/stn:add-ss login page` — Captures the tab whose title/URL best matches
  the description

---

## Step 1: Detect PR

Run:

```bash
gh pr view --json number,url,title,state,isDraft,body,headRefName
```

Parse:

- `number` — PR number
- `url` — full GitHub PR URL
- `title` — PR title
- `body` — current PR description
- `headRefName` — current branch name (used for raw GitHub URLs)

Also capture owner and repo:

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

Scan the PR `body` for a Screenshots heading (case-insensitive):

- `## Screenshots`
- `### Screenshots`
- `## Screenshot`
- `### Screenshot`

**If no Screenshots section exists:**

```text
⚠️  No Screenshots section found in PR #<number>.

The PR description doesn't contain a "## Screenshots" heading.
Add the heading where you want screenshots to appear, then run
/stn:add-ss again.
```

Then exit. Do NOT add the heading automatically.

**If found:** note the exact heading text and line position. Continue.

---

## Step 3: Get Chrome Context

Call `tabs_context_mcp` (with `createIfEmpty: true` if needed).

**If Chrome is not reachable:**

```text
⚠️  Could not connect to Chrome.

Make sure Chrome is open and the Claude in Chrome extension is active,
then run /stn:add-ss again.
```

Then exit.

---

## Step 4: Select Tab(s) to Capture

**If an argument was provided** (e.g., `/stn:add-ss login page`):

Find the first tab whose title or URL contains the argument (case-insensitive).
If no match, fall through to interactive selection.

**Otherwise**, use `AskUserQuestion`:

```text
question: "Which tab(s) should I screenshot?"
header: "Tabs"
multiSelect: true
options: one per tab — label = title (≤50 chars), description = URL (≤80 chars)
```

---

## Step 5: Capture Each Tab via javascript_tool

Screenshot image IDs expire between tool calls, so this command avoids them
entirely. Instead, each tab is captured as a data URL using `javascript_tool`,
saved to disk via Bash, and committed to the branch for hosting.

**For each selected tab, in order:**

### 5a. Inject html2canvas and capture

Run `javascript_tool` on the source tab to capture the visible page as a
compressed JPEG data URL. Prefer JPEG to keep the data size manageable:

```javascript
(async () => {
  // Inject html2canvas if not already present
  if (!window.html2canvas) {
    await new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js';
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  // Capture at device pixel ratio, max 1440px wide
  const scale = Math.min(window.devicePixelRatio || 1, 2);
  const canvas = await html2canvas(document.documentElement, {
    useCORS: true,
    allowTaint: true,
    scale: scale,
    width: Math.min(document.documentElement.scrollWidth, 1440),
    height: window.innerHeight,
    windowWidth: Math.min(document.documentElement.scrollWidth, 1440),
    windowHeight: window.innerHeight,
    y: window.scrollY
  });

  // Resize to max 1440px wide to keep data URL manageable
  const maxW = 1440;
  const ratio = Math.min(1, maxW / canvas.width);
  const out = document.createElement('canvas');
  out.width = Math.round(canvas.width * ratio);
  out.height = Math.round(canvas.height * ratio);
  out.getContext('2d').drawImage(canvas, 0, 0, out.width, out.height);

  return out.toDataURL('image/jpeg', 0.85);
})()
```

The return value is a `data:image/jpeg;base64,...` string.

**If html2canvas injection or capture fails** (e.g., CSP blocks the CDN),
fall back to `computer` with `action: "screenshot"` and use that imageId
immediately in the next tool call with no intermediate steps — but treat
the expiry risk as acceptable for the fallback path only.

### 5b. Save to a temp file

Extract the base64 portion and save to disk:

```bash
python3 - <<'PYEOF'
import sys, base64, os
data_url = """DATA_URL_HERE"""
b64 = data_url.split(',', 1)[1]
img_bytes = base64.b64decode(b64)
path = '/tmp/add-ss-N.jpg'  # use actual N
with open(path, 'wb') as f:
    f.write(img_bytes)
print(f'Saved {len(img_bytes)} bytes to {path}')
PYEOF
```

Replace `DATA_URL_HERE` with the actual data URL from 5a and `N` with the
screenshot index (1, 2, …).

### 5c. Copy into the repo

Place the file in a `.github/screenshots/` directory scoped to the PR:

```bash
mkdir -p .github/screenshots/pr-<number>
cp /tmp/add-ss-N.jpg .github/screenshots/pr-<number>/screenshot-N.jpg
```

### 5d. Repeat for remaining tabs

If **no** tabs were captured successfully at all:

```text
⚠️  No screenshots were captured. Nothing was added to the PR.
```

Then exit.

---

## Step 6: Commit, Push, and Capture SHA

Stage and commit all captured screenshots in a single commit:

```bash
git add .github/screenshots/pr-<number>/
git commit -m "chore: add screenshots for PR #<number> [skip ci]"
git push
```

Immediately capture the commit SHA:

```bash
git rev-parse HEAD
```

Build image URLs using the **commit SHA** (not the branch name). This makes
the URLs immutable — they will keep working even after the files are deleted
from the branch in Step 9:

```text
https://raw.githubusercontent.com/<owner>/<repo>/<sha>/.github/screenshots/pr-<number>/screenshot-N.jpg
```

Construct one URL per screenshot. These are the image URLs used in the PR
body update.

---

## Step 7: Build Updated PR Body

Construct the new PR body in memory using the `body` from Step 1:

1. Locate the Screenshots heading (found in Step 2).

2. Find the insertion point: immediately after the heading and any blank line
   that follows it, before any existing section content or the next
   `##`/`###` heading.

3. Insert all image markdown strings at that point, each on its own line
   separated by a blank line:

   ```text
   ![screenshot-1](https://raw.githubusercontent.com/.../screenshot-1.jpg)

   ![screenshot-2](https://raw.githubusercontent.com/.../screenshot-2.jpg)
   ```

4. Leave all other content unchanged.

---

## Step 8: Confirm and Update PR via API

Use `AskUserQuestion`:

```text
question: "Add <N> screenshot(s) to PR #<number>?"
header: "Update PR"
options:
  - label: "Update"
    description: "Patch the PR description via gh api"
  - label: "Cancel"
    description: "Abort — screenshot commit already pushed but PR not modified"
multiSelect: false
```

**If "Cancel":** inform the user and exit. The screenshot commit is already
pushed; proceed to Step 9 anyway to clean up the files from the branch, but
skip the `gh api` call.

**If "Update":**

```bash
printf '%s' "<new_body>" \
  | jq -Rs '{"body": .}' \
  > /tmp/add-ss-body.json

gh api repos/<owner>/<repo>/pulls/<number> \
  -X PATCH \
  --input /tmp/add-ss-body.json

rm -f /tmp/add-ss-body.json
```

---

## Step 9: Remove Screenshot Files from Branch

Now that the PR body references images by commit SHA (not branch), the files
themselves are no longer needed on the branch. Remove them:

```bash
git rm -r .github/screenshots/pr-<number>/
git commit -m "chore: remove temp screenshots for PR #<number> [skip ci]"
git push
```

If `.github/screenshots/` is now empty, remove the directory too:

```bash
rmdir .github/screenshots 2>/dev/null || true
```

The SHA-based image URLs in the PR description continue to work — the commit
from Step 6 remains in the branch's git history and is permanently reachable.

---

## Step 10: Confirm

```text
✅ Screenshots added to PR #<number>

   <pr_title>
   <pr_url>

   Added <count> screenshot(s) to the Screenshots section.
   Screenshot files removed from branch.
```

---

## Error Handling

### html2canvas fails (CSP or load error)

If the CDN script is blocked or html2canvas throws, warn the user and try
the `computer` screenshot fallback (see Step 5a). If both fail, skip that
tab and continue.

### Git push fails (Step 6)

Display the error and ask the user to push manually. Do not proceed to update
the PR body until the push succeeds — the SHA-based raw URLs will 404 until
the commit is on the remote.

### `gh api` PATCH fails

Display the `gh api` error verbatim so the user can diagnose it.

---

## Notes

- Screenshots are committed to `.github/screenshots/pr-<number>/` on the
  current branch and hosted via `raw.githubusercontent.com`. No external
  service or GitHub CDN upload is required.
- This approach avoids screenshot `imageId` expiry entirely — capture and
  disk save happen via `javascript_tool` and Bash, with no time-sensitive
  IDs involved.
- The `[skip ci]` flag on the screenshot commit prevents CI from running
  on a cosmetic commit. Remove it if your CI should run on all commits.
- Works with both open and draft PRs.
