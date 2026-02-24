# Plan Review - Interactive plan file review

Walk through a Claude Code plan file section by section, answering questions
and applying edits mid-review.

## Usage

```
/re:plan-review [path]
```

- With a path: review that file directly
- Without a path: search both the local `.claude/plans/` directory (if
  present) and the global `~/.claude/plans/` directory

## Examples

- `/re:plan-review` - List recent plans and pick one
- `/re:plan-review ~/.claude/plans/my-feature.md` - Review a specific plan

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

3. **If tmux is active**, use `AskUserQuestion` to offer three modes:
   - **Popup editor** — one section at a time in a tmux popup; will ask
     which editor next
   - **VS Code** — open the full plan in VS Code; Claude waits for you
     to return
   - **Conversational** — sections shown here in chat, navigate by
     selection menu

   If tmux is **not** active, use `AskUserQuestion` to offer:
   - **VS Code** — open the full plan in VS Code; Claude waits for you
     to return
   - **Conversational** — sections shown here in chat

4. **If Popup editor was chosen**, use a second `AskUserQuestion` to ask
   which terminal editor:
   - **nvim** — Neovim
   - **vim** — Vim
   - **nano** — nano

### Phase 2: Analyze the plan structure

5. **Count `##` sections** (skipping those inside code fences):

   ```bash
   awk '
       /^```/ { in_code = !in_code }
       !in_code && /^## / { count++ }
       END { print count+0 }
   ' "$_plan_file"
   ```

6. **Collect section titles:**

   ```bash
   awk '
       /^```/ { in_code = !in_code }
       !in_code && /^## / { sub(/^## */, ""); print }
   ' "$_plan_file"
   ```

7. **Announce structure:**

   Display: `"This plan has N sections: [Section 1], [Section 2], …"`

   Then describe how to proceed based on the chosen mode.

### Phase 3a: Editor popup loop (nvim / vim / nano)

Track `current = 1` and `editor = {chosen editor from Phase 1.5}`. For
each section, run:

```bash
result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/plan-view.sh" \
    "$_plan_file" "$current" "$editor" "$_section_count")
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
- **`change:<text>`** → propose the edit before/after, use
  `AskUserQuestion` with "Apply" / "Skip" options. If applied, use the
  Edit tool and note what changed. Re-run `plan-view.sh` for the same
  section.

### Phase 3b: Conversational review loop (conversational mode)

For each section, output the separator and content as plain text (NOT
inside a code fence) so headings and formatting render properly:

---

**Section N of X · [Section Title]**

[section markdown content, output as-is]

---

Then use `AskUserQuestion` with these four options:

1. **Next** — advance to the next section
2. **Done** — finish the review and go to Phase 4
3. **Jump to section…** — follow up with a second `AskUserQuestion`
   asking "Jump to which section? (1–N)"; validate range and jump
4. **Ask / request a change** — follow up with a plain text prompt;
   if it reads as a question, answer using full plan context; if it
   reads as a change request, propose the edit before/after and use
   `AskUserQuestion` with "Apply" / "Skip" options; apply with the Edit
   tool if confirmed and show a brief summary

After each interaction (3 or 4), re-display the section content and
re-show the four options. After the last section, if the user selects
**Next**, proceed to Phase 4.

### Phase 3c: VS Code mode

Open the plan file in VS Code:

```bash
code "$_plan_file"
```

Then use `AskUserQuestion` to notify the user and pause. Header:
`"[filename] is open in VS Code — come back when you're done."` Options:

- **Done reviewing** — re-read the file with the Read tool to detect any
  changes, then go to Phase 4
- **Review sections now** — re-read the file, then run the full Phase 3b
  conversational loop before going to Phase 4
- **Re-open in VS Code** — run `code "$_plan_file"` again and re-show
  these same three options

### Phase 4: Wrap up

8. **Summarize changes**
   - If changes were made: list each as
     `- [Section title]: [one-line description]`
   - If no changes: say "No changes were made to the plan."

9. **Offer to open in an editor** (skip if popup or VS Code mode was used)
   - Use `AskUserQuestion` with "nvim" / "vim" / "VS Code" / "Done"
     options.
   - If nvim or vim: ask about a new tmux pane
     (`tmux split-window -h -c "#{pane_current_path}"`) then provide
     `{editor} [resolved-path]`.
   - If VS Code: run `code "$_plan_file"`.

## Important Notes

- **Read the full file before starting** — needed for accurate Q&A.
- **Never auto-apply edits** — always propose and confirm first.
- **Re-display section + re-show options** after every Q&A or change
  interaction in conversational mode.
- **Preserve formatting** — maintain existing markdown style and line
  length.
- **Jump validation** — if the entered section number is out of range,
  say so and re-show the `AskUserQuestion` options.
- **Graceful handling of empty plans directory** — if `~/.claude/plans/`
  doesn't exist or has no `.md` files, tell the user and exit.

---

Execute the plan review workflow following the steps above.
