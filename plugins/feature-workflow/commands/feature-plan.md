---
description: Create implementation plan for a feature
argument-hint: [optional-feature-name]
---

Create implementation plan for: $ARGUMENTS

## Auto-Detection Logic

1. **Check for feature name argument**
   - If provided: use that feature
   - If not provided: look in `work/features/` for uncommitted folders

2. **Handle multiple features**
   - If exactly ONE uncommitted feature: use it automatically
   - If MULTIPLE uncommitted features: list them and ask which one
   - If NO uncommitted features: show error

3. **Validate feature exists**
   - Ensure `work/features/<feature-name>/` exists
   - Ensure `reqs.md` exists in the folder

## Workflow

1. **Read requirements**
   - Load `work/features/<feature-name>/reqs.md`
   - Review and understand the requirements

2. **Ask clarifying questions**
   - If anything is unclear, ask the user
   - Update `reqs.md` if needed
   - Wait for confirmation before planning

3. **Create implementation plan**
   - Create `plan.md` in the feature folder using template below
   - Break down the work into logical steps
   - Consider architecture, dependencies, and order of implementation
   - **Identify dev environment needs**: For any production infrastructure (auth providers, payment APIs, email/SMS services, external APIs), proactively propose a dev bypass strategy. Developers should never need real infrastructure to work locally.

4. **STOP for review**
   - Present the plan
   - Wait for user approval or feedback
   - Update as needed

## Plan Template (plan.md)

```markdown
# Implementation Plan: <Feature Name>

## Architecture Overview
High-level description of how this feature will be built:
- Component structure
- Data flow
- Integration points
- Technology choices

## Technical Approach

### Frontend Changes
- Components to create/modify
- State management approach
- UI/UX considerations

### Backend Changes (if applicable)
- API endpoints
- Database schema changes
- Business logic

### Infrastructure/Tooling
- New dependencies
- Configuration changes
- Environment variables

### Development Environment Strategy
For any feature requiring external services or complex infrastructure in production, propose dev-friendly alternatives:

- **Production dependencies**: External services/infrastructure needed (auth providers, payment APIs, SMS gateways, email services, etc.)
- **Dev bypass strategy**: How developers can work without real infrastructure
  - Environment flags (e.g., `SKIP_2FA=true`, `MOCK_PAYMENTS=true`)
  - Bypass codes (e.g., TOTP code `000000` always works in dev)
  - Local stubs or fake services
  - Sandbox/test modes from providers
- **Implementation approach**: How code detects dev vs prod and switches behavior

## Implementation Steps

### Phase 1: Foundation
1. **Step description**
   - What: Detailed explanation
   - Why: Reasoning
   - Files: List of files to create/modify
   - Estimated complexity: [Low/Medium/High]

2. **Step description**
   - What: Detailed explanation
   - Why: Reasoning
   - Files: List of files to create/modify
   - Estimated complexity: [Low/Medium/High]

### Phase 2: Core Implementation
3. **Step description**
   - What: Detailed explanation
   - Why: Reasoning
   - Files: List of files to create/modify
   - Estimated complexity: [Low/Medium/High]

### Phase 3: Integration & Polish
4. **Step description**
   - What: Detailed explanation
   - Why: Reasoning
   - Files: List of files to create/modify
   - Estimated complexity: [Low/Medium/High]

## Testing Strategy
- Unit tests needed
- Integration tests needed
- Manual testing checklist

## Risks & Considerations
- Potential challenges
- Alternative approaches considered
- Performance implications

## Rollout Plan
- Feature flags needed?
- Migration steps
- Rollback strategy
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-plan.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Important Notes
- Keep plan detailed but actionable
- Each step should be completable in a reasonable timeframe
- Consider dependencies between steps
- Next step: `/feature-prep` when plan is approved
