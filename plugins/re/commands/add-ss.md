---
description: Capture Chrome screenshots and save them ready to drop into the PR
---

# Add Screenshots to PR

Captures screenshots from Chrome tabs, saves them to disk, and opens the PR
in Chrome so you can drag them into the Screenshots section.

## Usage

- `/re:add-ss` — Auto-detects the PR and asks which tab(s) to capture
- `/re:add-ss login page` — Captures the tab whose title/URL best matches
  the description

---

## Step 1: Detect PR

Run:

```bash
gh pr view --json number,url,title,state,isDraft 2>&1
```

**If no PR exists:**

```text
═══════════════════════════════════════════════════════════════════════
⚠️  No PR Found
═══════════════════════════════════════════════════════════════════════

No open or draft pull request found for the current branch.

Create a PR first, then run /re:add-ss to add screenshots.

═══════════════════════════════════════════════════════════════════════
```

Then exit.

**If found:** store `number` and `url`. Continue.

---

## Step 2: Check for Screenshots Section

Scan the PR body for a Screenshots heading (case-insensitive):

- `## Screenshots`
- `### Screenshots`
- `## Screenshot`
- `### Screenshot`

```bash
gh pr view --json body --jq '.body'
```

**If no Screenshots section exists:**

```text
⚠️  No Screenshots section found in PR #<number>.

The PR description doesn't contain a "## Screenshots" heading.
Add the heading where you want screenshots to appear, then run
/re:add-ss again.
```

Then exit.

---

## Step 3: Get Chrome Context

Call `tabs_context_mcp` (with `createIfEmpty: true` if needed).

**If Chrome is not reachable:**

```text
⚠️  Could not connect to Chrome.

Make sure Chrome is open and the Claude in Chrome extension is active,
then run /re:add-ss again.
```

Then exit.

---

## Step 4: Select Tab(s) to Capture

**If an argument was provided** (e.g., `/re:add-ss login page`):

Find the first tab whose title or URL contains the argument text
(case-insensitive). If no match, fall through to interactive selection.

**Otherwise**, use `AskUserQuestion`:

```text
question: "Which tab(s) should I screenshot?"
header: "Tabs"
multiSelect: true
options: one per tab — label = title (≤50 chars), description = URL (≤80 chars)
```

---

## Step 5: Create Output Directory

Create a temp directory to hold the screenshots:

```bash
mkdir -p /tmp/add-ss-pr-<number>
```

---

## Step 6: Capture Each Tab

For each selected tab, capture via `javascript_tool` using html2canvas and
save to disk. Process tabs one at a time.

### 6a. Capture as data URL

Run `javascript_tool` on the source tab:

```javascript
(async () => {
  if (!window.html2canvas) {
    await new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js';
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

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

  const maxW = 1440;
  const ratio = Math.min(1, maxW / canvas.width);
  const out = document.createElement('canvas');
  out.width = Math.round(canvas.width * ratio);
  out.height = Math.round(canvas.height * ratio);
  out.getContext('2d').drawImage(canvas, 0, 0, out.width, out.height);

  return out.toDataURL('image/jpeg', 0.85);
})()
```

**If html2canvas fails** (e.g., CSP blocks the CDN script), fall back to
macOS `screencapture`:

```bash
# Focus Chrome and capture the visible screen
osascript -e 'tell application "Google Chrome" to activate'
sleep 0.5
screencapture -x /tmp/add-ss-pr-<number>/screenshot-<N>.jpg
```

### 6b. Save to disk

If html2canvas succeeded, decode the data URL and save:

```bash
python3 - <<'PYEOF'
import sys, base64
data_url = """DATA_URL_HERE"""
b64 = data_url.split(',', 1)[1]
with open('/tmp/add-ss-pr-<number>/screenshot-<N>.jpg', 'wb') as f:
    f.write(base64.b64decode(b64))
PYEOF
```

Replace `DATA_URL_HERE` with the actual data URL returned from 6a, and `N`
with the screenshot index (1, 2, …).

Repeat for each selected tab.

---

## Step 7: Open PR in Chrome

Navigate to the PR URL in Chrome (use the MCP tab or an existing tab):

```
navigate to: <pr_url>
```

Wait for the page to load. Scroll down to the Screenshots section so it is
visible.

---

## Step 8: Show Instructions

Display the file paths and tell the user what to do:

```text
📸 Screenshots saved — drag them into the PR

   Files:
     /tmp/add-ss-pr-<number>/screenshot-1.jpg
     /tmp/add-ss-pr-<number>/screenshot-2.jpg   ← (if multiple)

   The PR is open in Chrome. Drag the file(s) above into the
   "## Screenshots" section of the PR description and click Save.

   Tip: click the description's edit (✏️) button, then drag the
   files into the text area near the Screenshots heading.
```

Also open Finder to the screenshot folder for easy drag-and-drop:

```bash
open /tmp/add-ss-pr-<number>/
```

---

## Error Handling

### html2canvas fails and screencapture fallback is used

Warn the user that the screencapture fallback captures the full visible
screen, so they should ensure the target Chrome tab is in the foreground
before the fallback runs.

### No screenshots were saved

If all capture attempts failed:

```text
⚠️  No screenshots were captured. Nothing was saved.
```

Then exit.

---

## Notes

- Works with both open and draft PRs.
- Screenshots are saved to `/tmp/add-ss-pr-{number}/` and are not committed
  to the branch.
- The PR description is not modified automatically — the user drags the
  files in via GitHub's editor, which uploads them to GitHub's CDN.
