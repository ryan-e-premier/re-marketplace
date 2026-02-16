# Dev Utilities Plugin

Development utility scripts for package management, transcript formatting, and
diffview.

## Commands

### `/diffview`

Opens a diffview interface for reviewing code changes.

```bash
/diffview
```

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

- **DEPRECATED** - Package marked as deprecated (red)
- **MAJOR** - Breaking changes expected (yellow)
- **SAFE** - Minor or patch updates (green)

Example output:

```
📦 Package Update Summary

DEPRECATED (1):
  old-package: 1.0.0 → 2.0.0 (deprecated)

MAJOR (2):
  react: 17.0.2 → 18.2.0
  webpack: 4.46.0 → 5.88.0

SAFE (5):
  lodash: 4.17.20 → 4.17.21
  typescript: 4.9.0 → 4.9.5
  ...
```

## Scripts

The plugin includes utility scripts:

- `format-transcript.sh` - Formats conversation transcripts
- `open-context.sh` - Opens context in appropriate viewer
- `pnpm-outdated-summary.sh` - Analyzes pnpm package updates

## Requirements

- nvim (for `/transcript` and `/diffview`)
- pnpm (for `/pnpm-outdated`)

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
