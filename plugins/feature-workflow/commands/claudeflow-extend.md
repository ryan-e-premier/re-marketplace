---
description: Initialize extension files for customizing claudeflow commands
argument-hint: [start|plan|prep|build|docker|end|review]
---

Initialize claudeflow extensions: $ARGUMENTS

## What This Does

Creates the `.claude/claudeflow-extensions/` folder with extension files that let you customize claudeflow commands for your project.

## Arguments

- No argument: Creates all extension files
- `start` - Extension for `/feature-start`
- `plan` - Extension for `/feature-plan`
- `prep` - Extension for `/feature-prep`
- `build` - Extension for `/feature-build`
- `docker` - Extension for `/feature-docker`
- `end` - Extension for `/feature-end`
- `review` - Extension for `/feature-review`

Example: `/claudeflow-extend plan` creates only `feature-plan.md` extension

## Workflow

1. **Create extensions folder**
   - Create `.claude/claudeflow-extensions/` if it doesn't exist

2. **Generate extension files**
   - If argument provided: create only that extension
   - If no argument: create all extensions

3. **Show next steps**
   - Explain how to customize extensions
   - Point to documentation

## Extension File Template

Each extension file is created with this structure:

```markdown
# Extension: <command-name>

## Additional Template Sections
<!-- Add new sections to include in templates -->

## Modified Workflow
<!-- Add or modify workflow steps -->

## Project-Specific Instructions
<!-- Add instructions specific to your project -->
```

## Extension Files to Create

| Extension File | Extends | Common Customizations |
|----------------|---------|----------------------|
| `feature-start.md` | `/feature-start` | Additional requirements sections, project-specific questions |
| `feature-plan.md` | `/feature-plan` | Security review, compliance sections, custom template sections |
| `feature-prep.md` | `/feature-prep` | Additional setup steps, custom task templates |
| `feature-build.md` | `/feature-build` | Linting requirements, testing standards, code review checklist |
| `feature-docker.md` | `/feature-docker` | Project-specific services, custom seeding |
| `feature-end.md` | `/feature-end` | Pre-merge checks, notification steps |
| `feature-review.md` | `/feature-review` | Additional context sources, custom summary sections |

## Sample Extension Content

### feature-plan.md
```markdown
# Extension: feature-plan

## Additional Template Sections

Add these sections to the plan template:

### Security Review
- Authentication/authorization changes
- Data encryption requirements
- Input validation approach
- Compliance considerations (GDPR, HIPAA, SOC2)

### Performance Considerations
- Expected load
- Caching strategy
- Database optimization needs

## Modified Workflow

When creating the implementation plan:
1. If feature touches user data → add security review task
2. If feature requires DB changes → include migration rollback plan
3. If feature is customer-facing → include A/B testing consideration
```

### feature-build.md
```markdown
# Extension: feature-build

## Additional Workflow Steps

Before marking any task complete:
1. Run `npm run lint` and fix any errors
2. Run `npm run typecheck` and fix any errors
3. Ensure no console.log statements in production code

## Task Completion Requirements

A task is only complete when:
- Implementation is done
- Linting passes
- Type checking passes
- Unit tests for new code are written (if applicable)
```

### feature-end.md
```markdown
# Extension: feature-end

## Pre-Merge Checklist

Before committing, verify:
- [ ] All tests pass (`npm test`)
- [ ] No linting errors (`npm run lint`)
- [ ] No type errors (`npm run typecheck`)
- [ ] Documentation updated if API changed
- [ ] CHANGELOG.md updated

## Commit Message Format

Use conventional commits:
- feat: for new features
- fix: for bug fixes
- docs: for documentation
- refactor: for refactoring
- test: for tests
```

## Output

After running:
```
✓ Extensions initialized!

Created: .claude/claudeflow-extensions/
  - feature-start.md
  - feature-plan.md
  - feature-prep.md
  - feature-build.md
  - feature-docker.md
  - feature-end.md
  - feature-review.md

Next steps:
1. Edit extensions to add your project-specific customizations
2. Extensions are automatically applied when you run commands
3. Commit extensions to share with your team

Tip: Start with feature-plan.md and feature-build.md - these are
the most commonly customized.
```

## Important Notes

- Extensions are project-specific and should be committed to your repo
- Each command checks for its extension and incorporates the instructions
- Extensions add to base commands, they don't replace them
- Delete extension files you don't need to customize
