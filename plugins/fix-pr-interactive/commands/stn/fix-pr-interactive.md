---
description: Interactively review and address PR feedback one comment at a time
---

# Interactive PR Comment Resolution

This command provides an interactive workflow for reviewing and addressing PR
comments one-by-one. Each comment is presented with full context, and you
decide whether to fix it, respond, or skip.

## Usage

- `/stn:fix-pr-interactive` - Lists open PRs and asks which to fix
- `/stn:fix-pr-interactive 366` - Addresses feedback for PR #366

---

## Session Persistence

This command maintains a session file to track progress. If context is lost
mid-session, running the command again will offer to resume from where you
left off.

### Session File Location

```text
{repo_root}/.fix-pr-session-{PR_NUMBER}.json
```

Example: `.fix-pr-session-519.json`

### Session File Structure

```json
{
  "pr_number": 519,
  "repo": "owner/repo",
  "started_at": "2025-01-26T15:30:00Z",
  "last_updated_at": "2025-01-26T15:45:00Z",
  "phase": "processing",
  "current_index": 3,
  "counters": {
    "total_fetched": 15,
    "comments_fixed": 2,
    "responded": 0,
    "deferred": 0,
    "skipped": 1,
    "already_resolved": 5,
    "already_processed": 2
  },
  "commits": [
    { "hash": "abc123", "description": "add null check" },
    { "hash": "def456", "description": "rename variable" }
  ],
  "raw_comments": [],
  "comments": [
    {
      "id": 12345,
      "body": "Please add a null check here",
      "user": "reviewer",
      "path": "src/components/Foo.tsx",
      "line": 42,
      "diff_hunk": "@@ -40,6 +40,8 @@ ...",
      "comment_type": "inline",
      "status": "fixed",
      "action_taken": "Fixed in commit abc123"
    },
    {
      "id": 12346,
      "body": "Why is this approach used?",
      "user": "reviewer",
      "path": null,
      "line": null,
      "diff_hunk": null,
      "comment_type": "pr-level",
      "status": "pending",
      "action_taken": null
    }
  ]
}
```

### Session Phase Values

- `fetching` - Currently fetching comments from GitHub API
- `filtering` - Filtering resolved/already-processed comments
- `processing` - Interactive comment review loop (main phase)
- `complete` - All comments processed (file will be deleted)

### Comment Status Values

- `pending` - Not yet addressed
- `fixed` - Code change made and committed
- `responded` - Reply posted without code change
- `skipped` - User chose to skip
- `deferred` - Saved to deferred file for later

### Deferred Comments File

When user defers a comment, it's saved to a markdown file for later reference:

**File location:** `.pr-{PR_NUMBER}-deferred.md`

**File format:**

```markdown
# Deferred PR Comments - PR #{PR_NUMBER}

> These comments were deferred during interactive review.
> Address them manually when ready.

---

## Comment 1: {brief_description}

**File:** `{file_path}:{line_number}`
**Author:** @{username} | **Type:** {CODE CHANGE|QUESTION|etc}
**GitHub:** {direct_link_to_comment}

### Comment
{full_comment_body}

### Code Context
```{language}
{diff_hunk_or_code_context}
```

### Notes
{user_note_if_provided}

---
```

This file is **NOT gitignored** - you may want to commit it or add to
`.gitignore` based on preference.

---

## Step 1: PR Detection & Setup

### 1a. Detect PR Number

**If PR number provided in args:**

- Use the provided number directly
  (e.g., `/stn:fix-pr-interactive 366` → PR #366)

**If no PR number provided:**

- List open PRs for the current repository:
  ```bash
  gh pr list --state open --author @me
  ```
- If multiple PRs exist, use AskUserQuestion to let user select which PR to
  address
- If only one PR exists, confirm with user before proceeding
- If no open PRs exist, inform user and exit

### 1b. Check for Existing Session

After determining the PR number, check if a session file exists:

```bash
ls .fix-pr-session-{PR_NUMBER}.json 2>/dev/null
```

**If session file exists:**

1. Read the session file to get current state
2. Check the `phase` to determine where to resume:
   - `fetching` → Resume from Step 1c (may have partial data)
   - `filtering` → Resume from Step 2 with raw_comments
   - `processing` → Resume from Step 3 at current_index

3. Display session summary:

   ```text
   ═══════════════════════════════════════════════════════════════════════
   📂 Existing Session Found for PR #{pr_number}
   ═══════════════════════════════════════════════════════════════════════

   Phase: {phase}
   Started: {started_at}
   Last updated: {last_updated_at}

   Progress:
     • {current_index} of {total_comments} comments processed
     • Fixed: {comments_fixed}
     • Responded: {responded}
     • Skipped: {skipped}

   ═══════════════════════════════════════════════════════════════════════
   ```

4. Use AskUserQuestion to ask:
   ```text
   question: "Resume previous session or start fresh?"
   header: "Session"
   options:
     - label: "Resume"
       description: "Continue from where you left off"
     - label: "Start fresh"
       description: "Discard progress and re-fetch all comments"
   multiSelect: false
   ```

5. **If user selects "Resume":**
   - Load all state from the session file
     (counters, commits, comments, raw_comments)
   - **Resume based on phase:**
     - `fetching`: Re-fetch comments (partial fetch may be corrupted)
     - `filtering`: Use `raw_comments` from session, skip to Step 2 filtering
     - `processing`: Use `comments` array, find first `status: "pending"`,
       skip to Step 3
   - **DO NOT re-fetch comments if phase is `filtering` or `processing`**

6. **If user selects "Start fresh":**
   - Delete the existing session file
   - Continue with Step 1c (Fetch All Comments)

**If no session file exists:**

- Continue with Step 1c (Fetch All Comments)

### 1c. Fetch All Comments

**FIRST: Create/Update Session File (prevents data loss)**

Before fetching, create the session file to track progress:

```json
{
  "pr_number": "{PR_NUMBER}",
  "repo": "{owner}/{repo}",
  "started_at": "{ISO timestamp}",
  "last_updated_at": "{ISO timestamp}",
  "phase": "fetching",
  "current_index": 0,
  "counters": {
    "total_fetched": 0,
    "comments_fixed": 0,
    "responded": 0,
    "deferred": 0,
    "skipped": 0,
    "already_resolved": 0,
    "already_processed": 0
  },
  "commits": [],
  "raw_comments": [],
  "comments": []
}
```

**Use the Write tool** to create `.fix-pr-session-{PR_NUMBER}.json` at the
repo root.

---

Fetch both types of comments using pagination to ensure all comments are
retrieved.

**CRITICAL: Use pagination and combine results**

```bash
# Inline review comments (on specific code lines)
gh api --paginate repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments \
  | jq -s 'add // []'

# PR-level comments (general discussion)
gh api --paginate repos/{owner}/{repo}/issues/{PR_NUMBER}/comments \
  | jq -s 'add // []'
```

**Why `jq -s 'add // []'`:** The `--paginate` flag returns each page as a
separate JSON array. `jq -s 'add'` combines them into a single array, and
`// []` handles empty results.

### 1d. Normalize Comment Data

For each comment, extract and store:

- `id` - Comment ID (for replies)
- `body` - Comment text
- `user.login` - Author username
- `created_at` - Timestamp
- `path` - File path (inline comments only)
- `line` or `original_line` - Line number (inline comments only)
- `diff_hunk` - Code context (inline comments only)
- `in_reply_to_id` - Parent comment ID if this is a reply
- `comment_type` - "inline" or "pr-level"

### 1e. Save Raw Comments to Session (CHECKPOINT)

**IMMEDIATELY after fetching and normalizing, update the session file:**

1. Set `phase` to `"filtering"`
2. Store all normalized comments in `raw_comments` array
3. Update `counters.total_fetched` with the count
4. Update `last_updated_at` timestamp

**Use the Write tool** to update `.fix-pr-session-{PR_NUMBER}.json`

This checkpoint ensures that if context is lost during filtering, we can
resume without re-fetching from GitHub API.

---

## Step 2: Comment Filtering

Filter out comments that don't need attention and track counts for the final
summary.

### 2a. Initialize Counters

Set up counters to track throughout the workflow:

- `total_comments` - Total comments fetched
- `already_resolved` - Comments resolved via GitHub's resolution feature
- `already_processed` - Comments with existing AI reply marker
- `actionable_comments` - Comments remaining after filtering

### 2b. Filter Resolved Comments

For inline review comments, check the `position` field:

- If `position` is `null` AND the comment is part of a resolved review
  thread, it's resolved
- Check the pull request review threads for resolution status:
  ```bash
  gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/reviews
  ```
- Increment `already_resolved` counter for each filtered comment

**Note:** PR-level comments (issue comments) don't have a resolved state in
GitHub.

### 2c. Filter Already-Processed Comments

Check if any reply to the comment contains the AI attribution marker:

**Marker to check for:** `🤖 *Claude Code*:`

For each comment:

1. Find all replies (comments where `in_reply_to_id` matches this comment's
   `id`)
2. Check if any reply body starts with or contains `🤖 *Claude Code*:`
3. If found, this comment was already addressed in a previous run
4. Increment `already_processed` counter and skip this comment

### 2d. Build Actionable Comments List

After filtering, create a list of comments that need attention:

- Exclude resolved comments
- Exclude comments with existing AI replies
- Sort by file path, then by line number (for logical ordering)
- Store as `actionable_comments` list

### 2e. Group Duplicate/Similar Comments

**IMPORTANT:** Before presenting comments to the user, detect and group
duplicates.

**Detection criteria for duplicates:**

- **Exact duplicates:** Comments with identical `body` text
- **Similar comments:** Comments where the body text has >80% similarity
  (same request, minor wording differences)

**Grouping logic:**

1. Compare each comment's `body` to all other comments
2. Group comments with identical or highly similar text
3. Store groups in session as `comment_groups` array

**Group structure:**

```json
{
  "comment_groups": [
    {
      "group_id": 1,
      "is_duplicate_group": true,
      "representative_body": "nit: Consider adding a comment here",
      "comment_ids": [2728969825, 2728969826],
      "locations": [
        { "path": "src/foo.ts", "line": 50 },
        { "path": "src/foo.ts", "line": 100 }
      ],
      "status": "pending"
    },
    {
      "group_id": 2,
      "is_duplicate_group": false,
      "representative_body": "Please add error handling",
      "comment_ids": [12345],
      "locations": [{ "path": "src/bar.ts", "line": 25 }],
      "status": "pending"
    }
  ]
}
```

**Benefits of grouping:**

- User sees all instances of the same feedback at once
- User can choose to fix all instances with one action
- Reduces repetitive prompts for identical feedback

### 2f. Report Filtering Results

Display to user:

```text
Found {total_comments} total comments
  - {already_resolved} already resolved
  - {already_processed} already addressed (have AI replies)
  - {actionable_comments.length} need attention
```

If no actionable comments remain, inform the user and exit:

```text
✓ All PR comments have been addressed!
  No further action needed.
```

### 2g. Update Session File (CHECKPOINT)

After filtering is complete (and there are actionable comments), update the
session file:

**Session file path:** `.fix-pr-session-{PR_NUMBER}.json`

**Update the session with:**

1. Set `phase` to `"processing"`
2. Update `counters.already_resolved` with count
3. Update `counters.already_processed` with count
4. Set `comments` array to actionable comments (each with
   `status: "pending"`)
5. Update `last_updated_at` timestamp

**Use the Write tool** to update this file at the repo root.

**Important:** Add `.fix-pr-session-*.json` to `.gitignore` to avoid
committing session state.

---

## Step 3: Interactive Loop

For each unresolved comment, execute the following steps:

### 3a. Display Comment

For each comment, display full context using the **rich format**:

```text
───────────────────────────────────────────────────────────────────────────

📝 Comment {current_index} of {total} | [{comment_type_badge}]

👤 {username} • {date}

📁 {file_path}:{line}

{section_header_from_file}

{code_context_from_file}

💬 Comment:
{comment_body}

───────────────────────────────────────────────────────────────────────────
```

**Key elements to include:**

1. **Section header** - Find the nearest markdown header (###, ##, #) above
   the commented line
2. **Code context** - Read ±5 lines around the comment line to show relevant
   code
3. **Comment body** - The full reviewer comment

**Comment Type Badge:**

- `[CODE CHANGE]` - Comment suggests or requests a code modification
- `[QUESTION]` - Comment asks a question or seeks clarification
- `[SUGGESTION]` - Comment offers an optional improvement
- `[NITPICK]` - Minor style or preference comment

**Determining comment type:** Analyze the comment body for keywords:

- Code change: "please change", "should be", "needs to", "fix", "update",
  "remove", "add"
- Question: ends with "?", "why", "how", "what", "can you explain"
- Suggestion: "consider", "might want to", "could", "optional"
- Nitpick: "nit:", "minor:", "style:"

**Code context (for inline comments):**

1. **Show `diff_hunk` first** - This shows the code at the time the comment
   was made
2. **Read and show current code** - Use Read tool:
   `Read file: {path}, lines {line - 5} to {line + 5}`
3. **Compare and annotate:**
   - If code is unchanged: show "(unchanged)" in header
   - If code has changed: show both versions
   - Add `↑` annotations pointing to the specific issue

**For PR-level comments:**

- No code context needed unless the comment references specific code
- If it references a file/function, read that context

### 3a-group. Display Duplicate Group (when applicable)

**When a comment is part of a duplicate group, show ALL instances:**

```text
───────────────────────────────────────────────────────────────────────────

📝 Comment Group {group_index} of {total_groups} | [{badge}] | 🔁 {count} DUPLICATES

💬 Comment:
{representative_body}

───────────────────────────────────────────────────────────────────────────

📍 Instance 1 of {count}

👤 {username} • {date}

📁 {file_path}:{line}

{section_header}

{code_context}

───────────────────────────────────────────────────────────────────────────
```

**User options for duplicate groups:**

- **"Fix all"** - Apply the same fix to all locations
- **"Handle individually"** - Break group apart and handle one-by-one
- **"Skip all"** - Skip all instances in the group
- **"Defer all"** - Defer all instances to the deferred file

### 3b. User Decision

After displaying the comment, use AskUserQuestion to get the user's decision.

**IMPORTANT: Always include comment context in the question**

The question text MUST include:

- Progress indicator: `[{current}/{total}]`
- File location (for inline) or "PR comment" (for PR-level)
- First ~50 chars of the comment body (truncated with "...")

**For CODE CHANGE comments:**

```text
question: "[{current}/{total}] {file_path}:{line} — \"{first_50_chars}...\" — Fix this?"
header: "Action"
options:
  - label: "Yes, fix it"
    description: "Implement the requested change"
  - label: "Defer"
    description: "Save to deferred file for later"
  - label: "Skip"
    description: "Move to next comment without changes"
multiSelect: false
```

**For QUESTION comments:**

```text
question: "[{current}/{total}] {file_path}:{line} — \"{first_50_chars}...\" — Respond?"
header: "Action"
options:
  - label: "Yes, respond"
    description: "Draft a response to post on GitHub"
  - label: "Defer"
    description: "Save to deferred file for later"
  - label: "Skip"
    description: "Move to next comment without responding"
multiSelect: false
```

**For SUGGESTION/NITPICK comments:**

```text
question: "[{current}/{total}] {file_path}:{line} — \"{first_50_chars}...\" — Implement?"
header: "Action"
options:
  - label: "Yes, implement"
    description: "Make the suggested change"
  - label: "Defer"
    description: "Save to deferred file for later"
  - label: "Skip"
    description: "Move to next comment without changes"
multiSelect: false
```

**For PR-level comments (no file):**

```text
question: "[{current}/{total}] PR comment — \"{first_50_chars}...\" — Fix this?"
```

**Handling user response:**

- If user selects "Yes" option → proceed to Step 3c (Implement Fix) or draft
  response
- If user selects "Defer" → proceed to Step 3f (Defer Comment)
- If user selects "Skip" → increment `skipped` counter, update session file,
  move to next comment
- If user provides custom input via "Other" → interpret their intent and act
  accordingly

**On Skip:** Update the session file immediately:

1. Set the current comment's `status` to `"skipped"`
2. Increment `counters.skipped`
3. Increment `current_index`
4. Update `last_updated_at` timestamp
5. Write the updated session to the file

### 3c. Implement Fix (if applicable)

**Step 1: Read the affected file**

For inline comments:

- If `diff_hunk` provides enough context, skip the file read
- Otherwise use Read tool on `{path}` with ±5 lines around `{line_number}`

For PR-level comments referencing specific code:

- Parse the comment body for file/function references
- Read the relevant file(s)

**Step 2: Understand the requested change**

Analyze the comment to determine:

- What specific change is being requested?
- Is it a bug fix, style change, refactor, or addition?
- Are there any constraints or preferences mentioned?

**Step 3: Implement the change**

Use the Edit tool to make the necessary modifications:

- Make minimal, focused changes that address the comment
- Follow existing code style and patterns in the file
- Don't introduce unrelated changes or "improvements"

**Step 4: Verify the fix**

After making the change:

- Re-read the modified section to confirm correctness
- Ensure the change addresses the reviewer's concern
- Check for any obvious issues (syntax, imports, etc.)

**For complex fixes:**

If the fix requires significant changes across multiple files:

1. Inform the user: "This fix is complex and may require more extensive
   changes."
2. Check `.claude/agents/` for a specialist agent relevant to the affected
   code (e.g., an agent matching the language, framework, or domain of the
   file being changed)
3. If found, offer to delegate: "I found a `{agent_name}` agent — delegate
   this fix to it?"
4. Get user confirmation before proceeding with either delegation or
   direct changes

**Tracking:** Increment `comments_fixed` counter after successful
implementation. Store the file path and brief description for the commit
message.

### 3d. Commit & Push (if fix made)

**Step 1: Stage the changed files**

```bash
git add {modified_file_paths}
```

Only stage files modified for this specific fix.

**Step 2: Create the commit**

```bash
git commit -m "$(cat <<'EOF'
fix: {brief description} per review feedback

Addresses PR comment by @{reviewer_username}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Step 3: Push to remote**

```bash
git push
```

Push immediately after each commit so the reviewer can see incremental
progress and CI/CD can run on the latest changes.

**Step 4: Capture commit info**

```bash
git rev-parse --short HEAD
```

**Step 5: Update session file**

1. Set the current comment's `status` to `"fixed"`
2. Set `action_taken` to `"Fixed in commit {hash}"`
3. Add to `commits` array: `{ "hash": "{short_hash}", "description": "{desc}" }`
4. Increment `counters.comments_fixed`
5. Increment `current_index`
6. Update `last_updated_at` timestamp
7. Write the updated session to the file

**Important notes:**

- Each fix gets its own separate commit (not batched)
- Push after every commit (not batched)
- Always update session file after each action to preserve progress
- If push fails, inform user and continue to next comment

### 3e. Post Reply (optional)

After each action (fix, respond, or skip), offer to post a reply to the
GitHub comment.

> ⚠️ **CRITICAL: AI ATTRIBUTION REQUIRED**
>
> Every reply posted to GitHub **MUST** start with the AI attribution prefix:
>
> ```text
> 🤖 *Claude Code*:
> ```
>
> This is **MANDATORY** - never post a reply without this prefix. It
> identifies AI-generated responses and allows future runs to detect
> already-processed comments.

**Step 1: Ask about posting reply**

```text
question: "[{current}/{total}] {file_path}:{line} — Post reply to GitHub?"
header: "Reply"
options:
  - label: "Yes"
    description: "Post a reply to this comment on GitHub"
  - label: "No"
    description: "Continue without posting a reply"
multiSelect: false
```

**Step 2: Draft the reply**

**Reply format (MANDATORY):**

1. Quote of original comment (for context)
2. Blank line
3. **AI attribution prefix** `🤖 *Claude Code*:` (REQUIRED - NEVER OMIT)
4. Response text

**For fixes:**

```text
> {first 1-2 sentences of original comment}

🤖 *Claude Code*: Fixed in commit {commit_hash} - {brief description}.
```

**For question responses:**

```text
> {the question being answered}

🤖 *Claude Code*: {answer to the question}
```

**Step 3: Validate the reply (BEFORE posting)**

Verify the reply text contains the AI attribution:

```text
✓ Check: Does the reply contain "🤖 *Claude Code*:" ?
```

**If the attribution is missing, DO NOT POST.** Add it first, then post.

**Step 4: Post the reply**

**First, look for a suitable agent in the workspace:**

```bash
ls .claude/agents/ 2>/dev/null
```

Scan the names and (optionally) the first few lines of each agent file for
keywords: `git`, `github`, `pr`, `pull request`, `gh api`. A name like
`git-manager`, `gh-helper`, or `pr-agent` is a strong match. A description
mentioning "GitHub API" or "PR comments" is also a match.

**If a suitable agent is found:** delegate via the Task tool:

```text
Task tool with:
  subagent_type: "{discovered_agent_name}"
  prompt: "Post a reply to PR #{PR_NUMBER} comment ID {comment_id}.

  Comment type: {inline|pr-level}
  Reply text:
  {reply_text}

  Use the appropriate GitHub API endpoint:
  - inline → gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments
              -X POST -f body='...' -F in_reply_to={comment_id}
  - pr-level → gh api repos/{owner}/{repo}/issues/{PR_NUMBER}/comments
               -X POST -f body='...'
  Confirm when posted successfully."
```

**If no suitable agent is found:** post the reply directly.

For **inline** review comments:

```bash
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments \
  -X POST \
  -f body="{reply_text}" \
  -F in_reply_to={comment_id}
```

For **PR-level** comments:

```bash
gh api repos/{owner}/{repo}/issues/{PR_NUMBER}/comments \
  -X POST \
  -f body="{reply_text}"
```

**Step 5: Track reply and update session**

**For question responses (no code fix):**

1. Set the current comment's `status` to `"responded"`
2. Set `action_taken` to `"Replied to question"`
3. Increment `counters.responded`
4. Increment `current_index`
5. Update `last_updated_at` timestamp
6. Write the updated session to the file

**For replies after fixes:**

- The session was already updated in Step 3d with `status: "fixed"`
- No additional session update needed

**If reply fails:**

- Inform user but continue to next comment

### 3f. Defer Comment (if selected)

**Step 1: Optionally ask for a note**

```text
question: "[{current}/{total}] {file_path}:{line} — Add a note for this deferred comment?"
header: "Note"
options:
  - label: "No note"
    description: "Save without additional notes"
  - label: "Add note"
    description: "I'll type a note to remember why I'm deferring"
multiSelect: false
```

If user selects "Add note", they can type their note via "Other".

**Step 2: Build the GitHub comment link**

```text
https://github.com/{owner}/{repo}/pull/{PR_NUMBER}#discussion_r{comment_id}
```

For PR-level comments:

```text
https://github.com/{owner}/{repo}/pull/{PR_NUMBER}#issuecomment-{comment_id}
```

**Step 3: Append to deferred file**

**File:** `.pr-{PR_NUMBER}-deferred.md`

If file doesn't exist, create it with header:

```markdown
# Deferred PR Comments - PR #{PR_NUMBER}

> These comments were deferred during interactive review.
> Address them manually when ready.

---
```

Append the comment entry:

```markdown
## {comment_type}: {first_10_words_of_comment}...

**File:** `{file_path}:{line_number}` (or "General PR comment")
**Author:** @{username} | **Type:** {comment_type_badge}
**GitHub:** [{short_link}]({full_url})

### Comment
{full_comment_body}

### Code Context
```{language_from_file_extension}
{diff_hunk_or_read_code_context}
```

### Notes
{user_note_or_"No notes"}

---
```

**Step 4: Update session file**

1. Set the current comment's `status` to `"deferred"`
2. Increment `counters.deferred`
3. Increment `current_index`
4. Update `last_updated_at` timestamp
5. Write the updated session to the file

**Step 5: Confirm and continue**

```text
📌 Deferred to .pr-{PR_NUMBER}-deferred.md
```

---

## Step 4: Summary

After processing all comments, display a final summary.

### Summary Display Template

```text
✅ PR #{pr_number} Review Complete
Fixed: {comments_fixed} | Responded: {responded} | Deferred: {deferred} | Skipped: {skipped}
(Filtered: {already_resolved} resolved, {already_processed} already processed)
{commits_list_if_any}
{deferred_file_note_if_any}
```

If `deferred > 0`, add:

```text
📌 {deferred} comment(s) saved to .pr-{PR_NUMBER}-deferred.md
```

### Commits Section (if any fixes were made)

```text
Commits: {hash1} {desc1}, {hash2} {desc2}, ...
```

### Next Steps Suggestion

- **If fixes made:** "Run your tests, then request re-review"
- **If no changes:** "All comments addressed or skipped"

### Session Cleanup

After successfully completing all comments, **delete the session file**:

```bash
rm .fix-pr-session-{PR_NUMBER}.json
```

This indicates the session is complete. If the user runs the command again,
it will fetch fresh comments and filter out previously-addressed ones via the
AI reply marker check.

**Important:** Only delete the session file on successful completion. If the
user aborts mid-session, the session file remains so they can resume later.

---

## Step 5: Error Handling

### Edge Case: No PR Number and No Open PRs

```text
═══════════════════════════════════════════════════════════════════════
⚠️ No Open PRs Found
═══════════════════════════════════════════════════════════════════════

No open pull requests found for your user.

To use this command:
  • Create a PR first, then run `/stn:fix-pr-interactive`
  • Or specify a PR number: `/stn:fix-pr-interactive 123`

═══════════════════════════════════════════════════════════════════════
```

### Edge Case: No Unresolved Comments

```text
✓ All PR comments have been addressed!
  No further action needed.
```

### Error: Fix Implementation Fails

1. **Inform the user:**
   ```text
   ⚠️ Failed to implement fix: {error_message}
   ```

2. **Ask how to proceed:**
   ```text
   question: "How should I proceed?"
   header: "Error"
   options:
     - label: "Skip this comment"
       description: "Move to the next comment"
     - label: "Retry"
       description: "Try implementing the fix again"
     - label: "Stop"
       description: "End the review session"
   multiSelect: false
   ```

3. **Do NOT abort the entire workflow** - let the user decide

### Error: Commit or Push Fails

1. Inform the user of the failure and error message
2. For push failures, suggest the user push manually and continue to the
   next comment

### Error: GitHub API Fails (Reply Posting)

1. Inform the user but continue to next comment
2. Track failed replies for the summary

### Error: Comment Fetch Fails

```text
═══════════════════════════════════════════════════════════════════════
❌ Failed to Fetch PR Comments
═══════════════════════════════════════════════════════════════════════

Error: {error_message}

Possible causes:
  • GitHub authentication issue - try `gh auth status`
  • PR number doesn't exist
  • Network connectivity problem

═══════════════════════════════════════════════════════════════════════
```

### General Principle

**Never abort the entire workflow due to a single comment failure.** Always
give the user the option to skip and continue.

---

## Token Optimization

### Session-Based Optimizations

1. **Always check for existing session FIRST** before any API calls
2. **When resuming, NEVER re-fetch comments** if phase is
   `filtering` or `processing`
3. **Trust the session state** - don't re-verify fixed/skipped/responded
   comments

### Reduce Output Verbosity

1. **Compact comment display** where possible
2. **Skip unnecessary confirmations** - don't echo back what the user just
   selected
3. **Batch status updates** - update session file without narrating each
   field

### Minimize File Reads

1. **Use diff_hunk when available** - don't read file if diff_hunk has
   sufficient context
2. **Read only ±5 lines** around the target, not ±20
3. **Cache file content mentally** - if fixing multiple comments in the same
   file, remember what you read

### API Call Efficiency

1. **Fetch comments once** - store in session, never re-fetch unless starting
   fresh
2. **Combine jq operations** - extract all needed fields in one pass

### Quick Reference: Session Resume Flow

```text
1. Check for .fix-pr-session-{PR}.json
2. If exists → Read it → Check phase → Ask resume/fresh
3. If resume:
   - phase="fetching"    → Re-fetch (partial data unreliable)
   - phase="filtering"   → Use raw_comments, skip to Step 2
   - phase="processing"  → Use comments, skip to Step 3
4. DO NOT re-fetch API if phase is filtering/processing
```

### Session Checkpoint Summary

| Step | Phase        | What's Saved                               |
|------|--------------|--------------------------------------------|
| 1c   | `fetching`   | Initial session created (empty)            |
| 1e   | `filtering`  | `raw_comments` stored after fetch          |
| 2g   | `processing` | Filtered `comments` array ready            |
| 3b-f | `processing` | After each user action (fix/skip/defer)    |
| 4    | `complete`   | Session file deleted on success            |

**Key principle:** Save state BEFORE doing work, so if context is lost we can
resume without repeating completed work.

---

## Key Principles

1. **One comment at a time:** Present each comment individually, wait for
   user decision
2. **Separate commits:** Each fix gets its own commit with descriptive message
3. **No duplicate work:** Skip comments that have AI reply marker from
   previous runs
4. **User control:** User decides what to fix, what to skip, and what to
   reply to
5. **Session persistence:** Progress is saved after each action to
   `.fix-pr-session-{PR}.json`; if context is lost, resume by running the
   command again
6. **Checkpoint system:** Session file is created BEFORE fetching and updated
   at each phase transition to prevent data loss
7. **Graceful recovery:** Session `phase` field determines resume point - no
   re-fetching if raw_comments already saved
8. **Token efficiency:** Minimize API calls, file reads, and verbose output -
   especially on resume
