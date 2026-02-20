# Dev Utilities Plugin

Development utility scripts for package management, transcript formatting,
diffview, and Workday timecard automation.

## Commands

### `/diffview`

Opens a side-by-side diff in a new tmux window using Neovim's DiffviewOpen
plugin.

```bash
/diffview [base]
```

- `base` (optional): The ref to compare against. Defaults to `origin/main`.

Examples:

- `/diffview` - Compare current HEAD against `origin/main`
- `/diffview origin/develop` - Compare against `origin/develop`
- `/diffview HEAD~5` - Compare last 5 commits

### `/transcript`

Opens the current conversation transcript in nvim for review and reference.

```bash
/transcript
```

The transcript is formatted and opened in a vim buffer, allowing you to:

- Search through conversation history
- Copy code snippets or commands
- Reference previous context
- Review Claude's reasoning

### `/pnpm-outdated`

Color-coded summary of outdated pnpm packages with semantic version analysis.

```bash
/pnpm-outdated
```

Analyzes your `pnpm outdated` results and categorizes updates:

- **DEPRECATED** - Package marked as deprecated (yellow)
- **SAFE** - Minor or patch updates (green)
- **MAJOR** - Breaking changes expected (red)

Example output:

```text
═══════════════════════════════════════════════════════
  AVAILABLE PACKAGE UPDATES
═══════════════════════════════════════════════════════

⚠ DEPRECATED (1): old-package
✓ SAFE (3): lodash, typescript, zod
⬆ MAJOR (2): react, webpack

═══════════════════════════════════════════════════════
Summary: 1 deprecated │ 3 safe │ 2 major
═══════════════════════════════════════════════════════
```

### `/stn:timecard`

Automate filling out your Workday timecard with browser automation.

```bash
/stn:timecard
```

Interactive workflow that:

1. Asks which week to fill (this week or last week)
2. Asks for Admin hours breakdown per day
3. Calculates Development hours (8 - Admin per day)
4. Shows preview and asks for confirmation
5. Automates browser to fill timecard in Workday

**Important:** The command saves your timecard but does not submit it for
approval. You must still submit through Workday's review process.

**Time Types:**

- **Admin Reg** - Administrative time
- **Development** - Development work (Clinical Decision Support Platform)

Total hours must equal 40 per week (Mon-Fri, 8 hours per day).

## Scripts

The plugin includes utility scripts:

- `format-transcript.sh` - Formats conversation transcripts
- `open-context.sh` - Opens context in appropriate viewer
- `pnpm-outdated-summary.sh` - Analyzes pnpm package updates

## Requirements

- nvim (for `/transcript` and `/diffview`)
- pnpm (for `/pnpm-outdated`)
- Chrome browser with Claude in Chrome extension (for `/stn:timecard`)

## Usage Tips

### Transcript Review

Use `/transcript` when you need to:

- Review what was discussed earlier
- Find a specific command or code snippet
- Understand Claude's reasoning process
- Export conversation for documentation

### Package Updates

Use `/pnpm-outdated` before:

- Planning package updates
- Reviewing dependency health
- Identifying breaking changes
- Prioritizing safe updates

The color-coded output helps you quickly identify which updates are safe to
apply immediately (green) vs which need careful testing (yellow) or
alternatives (red).

### Best Practices

1. Run `/pnpm-outdated` regularly to stay informed
2. Update SAFE packages first
3. Review breaking changes for MAJOR updates
4. Replace DEPRECATED packages promptly
5. Use `/transcript` to review complex discussions

## License

MIT
