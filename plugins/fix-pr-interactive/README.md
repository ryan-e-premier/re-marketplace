# fix-pr-interactive

Interactively review and address GitHub PR feedback one comment at a time.
Each comment is presented with full context — you decide whether to fix it,
respond to it, or skip it.

## Command

```text
/stn:fix-pr-interactive [PR_NUMBER]
```

- `/stn:fix-pr-interactive` — Lists your open PRs and asks which to work on
- `/stn:fix-pr-interactive 366` — Addresses feedback for PR #366

## Features

- **One comment at a time** — Each comment is shown with full code context
  and diff hunk before you decide
- **Duplicate detection** — Groups identical or near-identical comments so
  you handle them together
- **Session persistence** — Progress is saved to a local JSON file; if
  context is lost mid-session, re-run the command to resume
- **Already-processed detection** — Skips comments that already have an AI
  reply from a previous run
- **Deferred file** — Save comments to a `.pr-{PR_NUMBER}-deferred.md` file
  for later review
- **Commit per fix** — Each code fix gets its own commit and push so the
  reviewer sees incremental progress
- **GitHub reply posting** — Optionally posts a reply to each comment via
  the GitHub API after fixing or answering

## Requirements

- `gh` (GitHub CLI) authenticated with your account
- `jq` for JSON processing

## How It Works

### Phase 1: Fetch

Fetches all inline review comments and PR-level comments using the GitHub
API with pagination (`--paginate`). Saves raw results to a session file
immediately.

### Phase 2: Filter

Filters out:

- Comments already resolved via GitHub's resolution feature
- Comments that already have an AI reply (`🤖 *Claude Code*:` prefix)

Groups duplicate/similar comments together.

### Phase 3: Interactive Loop

For each actionable comment:

1. Displays the comment with surrounding code context
2. Asks: Fix / Respond / Defer / Skip
3. If fixing: makes the edit, commits, and pushes
4. Optionally posts a GitHub reply with the `🤖 *Claude Code*:` prefix

### Phase 4: Summary

Shows a compact summary:

```text
✅ PR #366 Review Complete
Fixed: 3 | Responded: 1 | Deferred: 2 | Skipped: 0
(Filtered: 5 resolved, 2 already processed)
Commits: abc123 add null check, def456 rename variable
📌 2 comment(s) saved to .pr-366-deferred.md
```

## Session Files

Two files are written to the repo root (add both to `.gitignore`):

- `.fix-pr-session-{PR_NUMBER}.json` — Live session state (deleted on
  completion)
- `.pr-{PR_NUMBER}-deferred.md` — Deferred comments (kept for manual review)

## Agent Discovery

When posting GitHub replies, the command first scans `.claude/agents/` in
your workspace for any agent that handles GitHub/PR interactions (matching
keywords like `git`, `github`, `pr`, or `gh api` in the agent name or
description). If one is found, it delegates to that agent via the Task tool.

If no suitable agent exists, it falls back to posting replies directly using
`gh api` — no extra setup required.
