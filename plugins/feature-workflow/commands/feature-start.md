---
description: Start a new feature by creating requirements document
argument-hint: [feature-description]
---

Start a new feature: $ARGUMENTS

## Workflow

1. **Generate feature name**
   - Convert description to kebab-case (e.g., "Create user profile settings" → "user-profile-settings")
   - Keep it short and descriptive

2. **Create feature directory**
   - Create `work/features/<feature-name>/` in current project
   - If `work/features/` doesn't exist, create it

3. **Create requirements document**
   - Create `reqs.md` using the template below
   - Fill in initial requirements based on the description

4. **Iterate with user**
   - Ask clarifying questions about requirements
   - Update `reqs.md` as needed
   - Continue until user approves or says to move on

## Requirements Template (reqs.md)

```markdown
# Feature: <Feature Name>

## Overview
Brief description of what this feature does and why it's needed.

## User Stories
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

## Functional Requirements
### Core Functionality
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

### User Interface
- [ ] UI requirement 1
- [ ] UI requirement 2

### Data Requirements
- [ ] Data requirement 1
- [ ] Data requirement 2

## Non-Functional Requirements
- **Performance:** [expectations]
- **Security:** [considerations]
- **Compatibility:** [requirements]

## Out of Scope
- What this feature explicitly does NOT include
- Future enhancements to consider later

## Open Questions
- [ ] Question 1?
- [ ] Question 2?

## Dependencies
- List any external dependencies or prerequisites
- Other features this depends on

## Success Criteria
- How we'll know this feature is complete and working
- Acceptance criteria
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-start.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Important Notes
- Keep uncommitted in main - this is your planning workspace
- Multiple features can be in progress simultaneously
- Next step: `/feature-plan` when requirements are solid
