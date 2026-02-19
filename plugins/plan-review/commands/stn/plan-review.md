# Plan Review - Interactive plan file review

Walk through a Claude Code plan file section by section, answering questions
and applying edits mid-review.

## Usage

```
/stn:plan-review [path]
```

- With a path: review that file directly
- Without a path: list plans from `~/.claude/plans/` and prompt for selection

## Examples

- `/stn:plan-review` - List recent plans and pick one
- `/stn:plan-review ~/.claude/plans/my-feature.md` - Review a specific plan

---

## Workflow

### Phase 1: Load the plan file

1. **Resolve the file to review**
   - If an argument was given (file path), use it directly
   - If no argument given:
     - List all `.md` files in `~/.claude/plans/` sorted by modification
       time, newest first, using:
       `ls -t ~/.claude/plans/*.md 2>/dev/null`
     - Display them as a numbered list, e.g.:
       ```
       1. hidden-gliding-garden.md  (modified: 2026-02-18)
       2. zippy-prancing-patterson.md  (modified: 2026-02-17)
       ```
     - Ask: "Which plan would you like to review? (enter a number or
       filename)"
     - Accept either the number or the filename as input
   - Read the full file content with the Read tool

### Phase 2: Analyze and announce structure

2. **Scan the file for `##` headings**
   - Each `##` heading is a primary section
   - If a section has more than 80 lines or more than 5 `###` sub-headings,
     split it at those `###` headings (each `###` becomes its own chunk)
   - Also split at bold numbered-section labels matching the pattern
     `**[Word] [digit]` (e.g. `**Phase 1 –`, `**Step 2 –`, `**Part 3 –`);
     each such label becomes its own chunk when the section is long
   - Build the ordered section list with titles

3. **Announce the structure before starting**
   - Display: `"This plan has N sections: [Section 1], [Section 2], …"`
   - Then say: `"Starting review. Say 'next' (or press Enter) to advance,
     'done' to finish, 'jump N' to skip to a section, or ask a question /
     request a change at any prompt."`

### Phase 3: Interactive review loop

For each section, display it in this format — output the separator lines
and section content as plain text (NOT inside a code fence) so Claude
Code's markdown renderer formats headings, bold, lists, and inline code
properly:

---

**Section N of X · [Section Title]**

[section markdown content, output as-is without wrapping in code fences]

---

Commands: [next] [done] [jump N] or ask a question / request a change

**Handle user input at each prompt:**

- **"next"** or blank input → advance to the next section; after the last
  section, proceed to Phase 4
- **"done"** → exit the loop immediately and go to Phase 4
- **"jump N"** → jump to section N (validate N is in range; if not, say so
  and re-show the current prompt)
- **Question** (anything that reads as a question or request for explanation):
  - Answer it using full awareness of the entire plan content
  - After answering, re-display the current section header and prompt so the
    user can continue
- **Modification request** (anything that reads as a request to change the
  plan):
  - Propose the specific edit in a clear before/after format
  - Ask: "Apply this change? (yes/no)"
  - If confirmed: apply the edit with the Edit tool, then show a brief
    summary of what changed (e.g., "Changed: replaced X with Y in section
    Z")
  - If declined: acknowledge and continue
  - Re-display the current section header and prompt

### Phase 4: Wrap up

4. **Summarize changes**
   - If changes were made: display a brief changelog listing each edit
     - Format: `- [Section title]: [one-line description of what changed]`
   - If no changes were made: say "No changes were made to the plan."

5. **Offer to open in nvim**
   - Say: "Would you like to open the plan in nvim?"
   - If yes: ask the user if they want to open a new tmux pane first using:
     `tmux split-window -h -c "#{pane_current_path}"`
     Then provide the command: `nvim [resolved-path]`
   - If no: close out gracefully

## Important Notes

- **Read the full file before starting** — you need the entire plan in context
  to answer questions accurately
- **Never auto-apply edits** — always propose and confirm first
- **Re-show the section prompt after every interaction** — questions and
  modifications don't advance the section
- **Preserve formatting** — when editing, maintain the existing markdown style,
  heading levels, and line length conventions of the file
- **Jump validation** — if the user says "jump 0" or a number out of range,
  explain valid range and re-prompt
- **Graceful handling of empty plans directory** — if `~/.claude/plans/`
  doesn't exist or has no `.md` files, tell the user and exit

---

Execute the plan review workflow following the steps above.
