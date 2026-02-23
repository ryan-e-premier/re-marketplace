# pnpm-outdated

Color-coded summary of outdated pnpm packages with semantic version analysis.

## Command

```text
/stn:pnpm-outdated
```

Categorizes updates as:

- **DEPRECATED** — package marked deprecated (yellow)
- **SAFE** — minor or patch update (green)
- **MAJOR** — breaking change expected (red)

## Example Output

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

## Requirements

- pnpm
