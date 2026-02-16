# Feature Plan Extension

## Plan File Structure

When creating a plan, save each section as a separate file for easier review:

```text
work/features/<feature-name>/
├── reqs.md
├── plan/
│   ├── 01-architecture-overview.md
│   ├── 02-technical-approach.md
│   ├── 03-implementation-steps.md
│   ├── 04-testing-strategy.md
│   ├── 05-risks-considerations.md
│   ├── 06-dev-environment.md      (if applicable)
│   ├── 07-rollout-plan.md
│   └── _plan.md                   (assembled full plan)
└── tasks.md
```

### Section Files

Each section file should:

- Start with the H2 heading (e.g., `## Architecture Overview`)
- Contain only that section's content
- Follow markdown formatting rules from global CLAUDE.md

### Assembled Plan

After all sections are reviewed and approved, assemble them into `_plan.md`:

```bash
cat plan/01-*.md plan/02-*.md plan/03-*.md ... > plan/_plan.md
```

The underscore prefix indicates this is a generated file.

## Section-by-Section Review Workflow

After creating all section files, review each one using the tmux popup.

### Review Script

Use `~/.claude/hooks/section-review.sh`:

```bash
~/.claude/hooks/section-review.sh <section_file> "<section_name>"
```

**Returns:**

- `approve` - User accepted the section
- `changes:<feedback>` - User wants changes
- `cancel` - User cancelled

### Review Process

1. **Create the plan/ directory and section files**

2. **Review each section in order:**

   ```bash
   for section in plan/0*.md; do
       RESULT=$(~/.claude/hooks/section-review.sh "$section" "$(basename $section)")
       # Handle result...
   done
   ```

3. **Handle results:**
   - `approve` → Move to next section
   - `changes:<feedback>` → Update the section file, re-review
   - `cancel` → Stop and ask user how to proceed

4. **After all approved:**
   - Assemble `_plan.md` from section files
   - Announce: "Plan approved. Run `/feature-prep` when ready."

### Keybindings in Review Popup

| Key | Action |
|-----|--------|
| `Enter` | Accept section |
| `r` | Request changes (prompts for feedback) |
| `q` | Cancel review |

## Section Order and Naming

| # | Filename | Heading |
|---|----------|---------|
| 01 | `01-architecture-overview.md` | `## Architecture Overview` |
| 02 | `02-technical-approach.md` | `## Technical Approach` |
| 03 | `03-implementation-steps.md` | `## Implementation Steps` |
| 04 | `04-testing-strategy.md` | `## Testing Strategy` |
| 05 | `05-risks-considerations.md` | `## Risks & Considerations` |
| 06 | `06-dev-environment.md` | `## Development Environment Strategy` |
| 07 | `07-rollout-plan.md` | `## Rollout Plan` |

**Note:** Section 06 (dev-environment) is optional - only include if the feature
requires external services or infrastructure.

## Creating the Plan

When `/feature-plan` runs:

1. Read `reqs.md` and understand the requirements
2. Create `plan/` directory
3. Create each section file one at a time
4. After all sections created, begin the review process
5. Track approved sections - don't re-review approved ones on resume

## Important Notes

- Section files are the source of truth during review
- `_plan.md` is only assembled after all sections are approved
- If user needs changes, edit the section file directly
- Keep section files under 100 lines each when possible
