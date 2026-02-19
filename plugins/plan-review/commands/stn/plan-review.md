# Plan Review - Interactive plan file review

Walk through a Claude Code plan file section by section, answering questions
and applying edits mid-review.

## Usage

```
/stn:plan-review [path]
```

- With a path: review that file directly
- Without a path: search both the local `.claude/plans/` directory (if
  present) and the global `~/.claude/plans/` directory

## Examples

- `/stn:plan-review` - List recent plans and pick one
- `/stn:plan-review ~/.claude/plans/my-feature.md` - Review a specific plan

---

## Workflow

### Phase 1: Load the plan file

1. **Resolve the file to review**

   - If an argument was given (file path), use it directly.

   - If no argument given:

     **a. Gather plans from both directories** — run ONE bash command
     that outputs a machine-readable list, e.g.:

     ```bash
     for f in $(ls -t .claude/plans/*.md 2>/dev/null); do
       echo "local|$f|$(date -r "$f" "+%Y-%m-%d")"
     done
     for f in $(ls -t ~/.claude/plans/*.md 2>/dev/null); do
       echo "global|$f|$(date -r "$f" "+%Y-%m-%d")"
     done
     ```

     **b. Output the grouped list as your own response text** (NOT
     inside a bash tool call — write it out as plain Claude output so
     it is always fully visible in the UI). Assign sequential numbers
     starting at 1 across both groups. Example format:

     ```
     Local plans  (.claude/plans/)
     ──────────────────────────────────────────
       1.  test-popup-review.md              2026-02-19

     Global plans  (~/.claude/plans/)
     ──────────────────────────────────────────
       2.  unified-snuggling-elephant.md     2026-02-19
       3.  hidden-gliding-garden.md          2026-02-16
       4.  zippy-prancing-patterson.md       2026-02-11
       5.  hashed-moseying-garden.md         2026-02-04
       6.  logical-growing-candy.md          2026-01-29
     ```

     Omit a section header entirely if that directory has no plans.

     **c. Ask:** "Which plan? (enter a number or filename)"
     Accept the user's reply as plain text. Resolve the number to its
     corresponding file from the list, or treat the reply as a filename
     (checking local dir first, then global dir, then as an absolute
     path).

   - Resolve the chosen filename to its full absolute path before
     proceeding.

   - Read the full file content with the Read tool.

### Phase 1.5: Offer popup review (tmux sessions only)

2. **Check for an active tmux session:**

   ```bash
   printenv TMUX 2>/dev/null | wc -c
   ```

   If output > 1, tmux is active.

3. **If tmux is active**, use `AskUserQuestion` to offer two modes:
   - **Popup mode** — one section at a time in a tmux popup with keyboard
     controls (Enter=next, p=prev, q=ask, e=change, d=done)
   - **Conversational mode** — sections shown here in chat, navigate
     by typing

   If tmux is **not** active, proceed directly with conversational mode.

### Phase 2: Analyze the plan structure

4. **Count `##` sections** (skipping those inside code fences):

   ```bash
   awk '
       /^```/ { in_code = !in_code }
       !in_code && /^## / { count++ }
       END { print count+0 }
   ' "$_plan_file"
   ```

5. **Collect section titles:**

   ```bash
   awk '
       /^```/ { in_code = !in_code }
       !in_code && /^## / { sub(/^## */, ""); print }
   ' "$_plan_file"
   ```

6. **Announce structure:**

   Display: `"This plan has N sections: [Section 1], [Section 2], …"`

   Then describe how to proceed based on the chosen mode.

### Phase 3a: Popup review loop (popup mode)

Track `current = 1`. For each section, run:

```bash
result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/plan-view.sh" \
    "$_plan_file" "$current")
```

Handle `result`:

- **`next`** → `current++`; if past the last section, go to Phase 4.
- **`prev`** → `current--`; clamp to 1.
- **`done`** → go to Phase 4 immediately.
- **`ask:<text>`** → answer the question `<text>` using full plan context,
  then use `AskUserQuestion` with two options — **"Back to review"**
  (reopens the popup for the same section) and **"Done"** (ends the
  review and goes to Phase 4) — so the user can read the answer at
  their own pace before continuing.
- **`change:<text>`** → propose the edit before/after, ask
  "Apply this change? (yes/no)" via `AskUserQuestion`. If yes, apply with
  the Edit tool and note what changed. Re-run `plan-view.sh` for the same
  section.

### Phase 3b: Conversational review loop (conversational mode)

For each section, output the separator and content as plain text (NOT
inside a code fence) so headings and formatting render properly:

---

**Section N of X · [Section Title]**

[section markdown content, output as-is]

---

Commands: [next] [done] [jump N] or ask a question / request a change

**Handle user input:**

- **"next"** or blank → advance; after the last section go to Phase 4.
- **"done"** → go to Phase 4.
- **"jump N"** → jump to section N (validate range, re-prompt if invalid).
- **Question** → answer using full plan context; re-display section and
  prompt.
- **Modification request** → propose before/after, use `AskUserQuestion`
  with "Apply" / "Skip" options. Apply with Edit tool if confirmed, show
  summary, re-display section and prompt.

### Phase 4: Wrap up

7. **Summarize changes**
   - If changes were made: list each as
     `- [Section title]: [one-line description]`
   - If no changes: say "No changes were made to the plan."

8. **Offer to open in nvim** (skip if popup mode was used)
   - Use `AskUserQuestion` with "Open in nvim" / "Done" options.
   - If nvim: ask about a new tmux pane
     (`tmux split-window -h -c "#{pane_current_path}"`) then provide
     `nvim [resolved-path]`.

## Important Notes

- **Read the full file before starting** — needed for accurate Q&A.
- **Never auto-apply edits** — always propose and confirm first.
- **Re-show the section after every interaction** in conversational mode.
- **Preserve formatting** — maintain existing markdown style and line
  length.
- **Jump validation** — explain valid range and re-prompt on out-of-range.
- **Graceful handling of empty plans directory** — if `~/.claude/plans/`
  doesn't exist or has no `.md` files, tell the user and exit.

---

Execute the plan review workflow following the steps above.
