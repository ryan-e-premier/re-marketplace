---
description: Explain the feature development workflow
argument-hint: [optional-topic]
---

Explain feature development workflow: $ARGUMENTS

## Help Topics

If no argument provided, show overview. Otherwise show help for:
- `overview` - Complete workflow explanation
- `structure` - File structure and organization
- `commands` - All available commands
- `example` - Step-by-step example
- `parallel` - Working on multiple features
- `docker` - Isolated Docker environments per feature
- `templates` - Document templates
- `troubleshooting` - Common issues and solutions
- `migration` - Migrating from old workflow

---

## Overview (default)

### What is this workflow?

A streamlined SDLC for developing features in parallel using git worktrees and Claude Code.

**Key Benefits:**
- Plan multiple features simultaneously in main branch
- Build features in parallel in separate worktrees
- Switch between features easily with VS Code windows
- Maintain organized documentation for each feature
- Merge completed features back to main cleanly

### The 5-Step Workflow

**1. Start → 2. Plan → 3. Prep → 4. Build → 5. End**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   IN MAIN   │     │   IN MAIN   │     │   IN MAIN   │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ feature-    │ --> │ feature-    │ --> │ feature-    │
│ start       │     │ plan        │     │ prep        │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                │
                                       Opens VS Code
                                                │
┌─────────────┐     ┌─────────────┐     ┌──────▼──────┐
│  IN MAIN    │     │ IN WORKTREE │     │ IN WORKTREE │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ feature-    │ <-- │ feature-    │ <-- │ feature-    │
│ merge-cont. │     │ end         │     │ build       │
└─────────────┘     └─────────────┘     └─────────────┘
 (if conflicts)
```

### Quick Example

```bash
# In main
/feature-start "add user settings"
/feature-plan
/feature-prep

# (switch to new VS Code window)
/feature-docker start  # Optional: Start isolated environment
/feature-build
# Say "continue" after each task

# When done
/feature-docker down   # Optional: Cleanup Docker
/feature-end
```

**For more details, run:**
- `/feature-help commands` - See all commands
- `/feature-help example` - Detailed walkthrough
- `/feature-help structure` - Understand file organization

---

## File Structure (structure)

```
/your-project/                        (main branch)
├── work/
│   └── features/                     
│       ├── user-settings/            
│       │   ├── reqs.md              ← requirements
│       │   ├── plan.md              ← implementation plan
│       │   └── tasks.md             ← generated tasks (TSK1, TSK2...)
│       └── email-notifications/     
│           └── reqs.md              ← planning another feature
└── src/

/your-project.worktrees/              (parallel development)
├── user-settings/                    ← building feature 1
│   ├── work/
│   │   └── features/
│   │       └── user-settings/
│   │           ├── reqs.md
│   │           ├── plan.md
│   │           └── tasks.md
│   └── src/                         ← complete codebase
└── email-notifications/              ← building feature 2
    └── ...
```

**Key Concepts:**

1. **Main branch = Planning HQ**
   - Create and refine features here
   - Multiple features can exist simultaneously
   - All uncommitted, safe to iterate

2. **Worktrees = Build zones**
   - Each feature gets its own worktree
   - Complete copy of codebase in isolated branch
   - Work on multiple features in parallel

3. **Feature folder = Single source of truth**
   - All docs for one feature live together
   - Moves from main to worktree during prep
   - Travels with the code when merged

4. **Gitignored files = Symlinked**
   - Git worktrees don't include gitignored files (`.claude/`, `.env`, etc.)
   - `/feature-prep` automatically symlinks these from main
   - All worktrees share the same commands and config
   - Changes to commands in main → instantly available in all worktrees

---

## Commands Reference (commands)

| Command | Location | Args | Purpose |
|---------|----------|------|---------|
| `/feature-start` | main | "description" | Create requirements for new feature |
| `/feature-plan` | main | [name] | Create implementation plan |
| `/feature-prep` | main or worktree | [name] | Generate tasks, create worktree, open VS Code (from main) OR refresh environment/symlinks (from worktree) |
| `/feature-build` | worktree | - | Implement tasks one by one |
| `/feature-docker` | worktree | [start\|stop\|logs\|down] | Manage isolated Docker environment |
| `/feature-end` | worktree | - | Commit, merge, cleanup |
| `/feature-merge-continue` | main | - | Complete merge after resolving conflicts |
| `/feature-review` | anywhere | [name] | Get quick status of the feature (summary, progress, etc) |
| `/claudeflow-extend` | anywhere | [start\|plan\|prep\|build\|docker\|end\|review] | Initialize extension files for customization |
| `/feature-help` | anywhere | [topic] | Show this help |

**Auto-detection:** Commands with `[name]` auto-detect if only one feature exists.

### Command Details

**`/feature-start "description"`**
- Creates `work/features/<kebab-case-name>/`
- Creates `reqs.md` with template
- Iterates with you to refine requirements
- ✓ Can plan multiple features at once

**`/feature-plan [feature-name]`**
- Reads requirements and asks clarifying questions
- Creates `plan.md` with implementation approach
- Stops for your review before proceeding
- ✓ Auto-detects if only one uncommitted feature

**`/feature-prep [feature-name]`**

*From main (full prep):*
- Generates `tasks.md` from plan (TSK1, TSK2, etc.)
- Creates git worktree at `../<project>.worktrees/<feature>/`
- Moves feature folder from main to worktree
- Sets up environment (symlinks `.claude/`, `.env`, etc.)
- Opens new VS Code window automatically
- ✓ Main branch stays clean

*From worktree (environment refresh):*
- Re-runs environment setup only (symlinks)
- Useful when you've added new items to your extension
- ✓ No worktree creation, just environment updates

**`/feature-build`**
- Works through tasks one by one (auto-detects feature)
- Marks each complete: `- [x] TSK1:`
- Pauses after each task for your review
- ✗ Never commits without permission

**`/feature-end`**
- Commits all changes in worktree
- Attempts merge to main
- If clean: deletes worktree, reports success
- If conflicts: shows files, waits for resolution
- ✓ Safe and automatic when possible

**`/feature-merge-continue`**
- Only used after conflict resolution
- Completes the merge
- Deletes worktree
- ✓ Run after resolving conflicts and staging files

**`/feature-review [name]`**
- Summarizes feature requirements, plan, and task status
- Shows current git state and uncommitted changes
- Use when starting a new session to continue work
- ✓ Faster than waiting for old session to compact

**`/claudeflow-extend [start|plan|prep|build|docker|end]`**
- Initializes `.claude/claudeflow-extensions/` folder
- Creates extension files for customizing commands
- Optional: specify command (e.g., `plan` not `feature-plan`)
- ✓ Commit extensions to share with team

---

## Complete Example (example)

### Scenario: Add Dark Mode

```bash
# ══════════════════════════════════════
# PHASE 1: PLANNING (in main VS Code)
# ══════════════════════════════════════

/feature-start "add dark mode toggle to settings"

# Claude creates work/features/dark-mode-toggle/reqs.md
# Claude: "I've created the requirements. Let's refine them..."
# You discuss: user stories, UI requirements, browser support
# Claude updates reqs.md as you iterate

/feature-plan

# Claude reads reqs.md
# Claude: "I have a few questions about the implementation..."
# You clarify: state management approach, theme storage
# Claude creates work/features/dark-mode-toggle/plan.md
# Claude: "Here's the implementation plan. Please review."
# You review and approve

/feature-prep

# Claude generates work/features/dark-mode-toggle/tasks.md:
#   - [ ] TSK1: Add theme context provider
#   - [ ] TSK2: Create toggle component
#   - [ ] TSK3: Implement theme switching logic
#   - [ ] TSK4: Add localStorage persistence
#   - [ ] TSK5: Update all components with theme
#   - [ ] TSK6: Write tests

# Claude creates ../project.worktrees/dark-mode-toggle/
# Claude moves feature folder to worktree
# Claude runs: code ../project.worktrees/dark-mode-toggle/
# New VS Code window opens!

# ══════════════════════════════════════
# PHASE 2: BUILDING (in new VS Code)
# ══════════════════════════════════════

/feature-build

# Claude: "Starting TSK1: Add theme context provider"
# Claude: "I'll create ThemeContext.tsx..."
# Claude creates file, marks task complete
# Claude: "TSK1 complete. Review the changes?"

# You: "continue"

# Claude: "Starting TSK2: Create toggle component"
# Claude creates ToggleSwitch.tsx using UI Skill
# Claude: "TSK2 complete. Would you like to see it?"

# You: "looks good, continue"

# Claude works through TSK3, TSK4, TSK5, TSK6...
# Each time: implement → mark complete → pause → continue

# ══════════════════════════════════════
# PHASE 3: COMPLETION (still in worktree)
# ══════════════════════════════════════

/feature-end

# Claude: "All 6 tasks complete! Ready to merge?"
# Claude shows file summary:
#   Created: ThemeContext.tsx, ToggleSwitch.tsx
#   Modified: App.tsx, index.css, 8 components
# You: "yes"

# Claude commits: "feat: add dark mode toggle"
# Claude merges to main (clean - no conflicts!)
# Claude deletes worktree
# Claude: "✓ Feature merged successfully!"

# ══════════════════════════════════════
# BACK TO MAIN
# ══════════════════════════════════════

# You're back in main VS Code window
# Feature is merged and worktree is gone
# Ready to start next feature!

/feature-start "add email notifications"
# ... and repeat!
```

---

## Working on Multiple Features (parallel)

You can plan and build multiple features simultaneously:

### Planning Multiple Features

```bash
# In main VS Code window
/feature-start "add dark mode"
/feature-start "add email notifications"
/feature-start "improve performance"

# Now you have (all uncommitted in main):
# work/features/dark-mode/reqs.md
# work/features/email-notifications/reqs.md  
# work/features/improve-performance/reqs.md

# Plan them all
/feature-plan dark-mode
/feature-plan email-notifications
/feature-plan improve-performance

# All 3 features are planned in main!
```

### Building Multiple Features

```bash
# Start building first feature
/feature-prep dark-mode
# → VS Code window 1 opens

# Back in main, start second feature
/feature-prep email-notifications
# → VS Code window 2 opens

# You now have 3 VS Code windows:
# 1. Main (still planning improve-performance)
# 2. dark-mode worktree (building)
# 3. email-notifications worktree (building)
```

### Switching Between Features

- Use VS Code's window switcher (Cmd/Ctrl+`)
- Each worktree is independent
- Work at your own pace on each
- `/feature-build` in any window continues that feature

### Merging Features

Features merge back to main independently:
- Feature A can merge while B is still in progress
- No conflicts if working on different files
- Merge conflicts handled individually

---

## Isolated Docker Environments (docker)

Each feature can run in its own isolated Docker environment for testing.

### Why Isolated Environments?

**Benefits:**
- Test features independently without conflicts
- Each feature gets its own database, cache, etc.
- Different features can run simultaneously on different ports
- Clean slate for testing (easy to reset)
- No interference between features

**Use Cases:**
- Backend API changes that need database testing
- Features that modify data schemas
- Integration testing in isolated environment
- Testing migrations or seeding data

### How It Works

**Port Assignment:**
Each feature gets unique ports calculated from feature name:
```bash
Main project (standard ports):
- App: 3000, DB: 5432, Redis: 6379

Feature "dark-mode" (overrides with unique ports):
- App: 3007, DB: 5439, Redis: 6386

Feature "email-notifications" (overrides with unique ports):
- App: 3023, DB: 5455, Redis: 6402
```

**Main runs normally:**
- Standard ports from `docker-compose.yml`
- No override needed
- `docker-compose up` in main → localhost:3000

**Worktrees override ports:**
- `/feature-docker start` creates override file
- Unique ports prevent conflicts
- Main and all worktrees can run simultaneously

**Automatic Setup:**
`/feature-docker start` creates:
- `docker-compose.override.yml` - Feature-specific port config
- `.env.docker` - Calculated ports
- Starts containers with unique ports

### Commands

```bash
# Start Docker environment for current feature
/feature-docker start
# Access at http://localhost:3007 (or your assigned port)

# Seed database from main (recommended!)
/feature-docker seed
# Copies data from main so you have realistic test data

# View logs
/feature-docker logs

# Check what's running
/feature-docker ps

# See assigned ports
/feature-docker ports

# Stop containers (keep data)
/feature-docker stop

# Restart containers
/feature-docker restart

# Stop and remove containers + data
/feature-docker down
```

### Workflow Integration

```bash
# In main
/feature-start "add user authentication"
/feature-plan
/feature-prep

# In worktree
/feature-docker start
# → Containers start on http://localhost:3031

/feature-docker seed
# → Database populated with main's data

/feature-build
# Build and test against http://localhost:3031 with realistic data

# When done testing
/feature-docker down
/feature-end
```

### Multiple Features Running

You can run Docker for multiple features simultaneously:

```bash
# Main project
cd ~/projects/myapp
docker-compose up
# → Running on localhost:3000

# Feature 1 worktree
/feature-docker start
# → Running on localhost:3007

# Feature 2 worktree
/feature-docker start
# → Running on localhost:3023

# All running independently! No conflicts!
```

Check all running environments:
```bash
docker ps
# Shows containers for main + all features
```

### Database Per Feature

Each feature gets its own isolated database:
- Independent schema
- Run migrations freely
- Test data doesn't conflict
- Easy to reset: `/feature-docker down` and restart

**Seeding from main:**
```bash
/feature-docker start
/feature-docker seed
# Copies all data from main's database
# Now you have realistic test data!
```

**Why seed?**
- Test features with existing users
- Work with realistic data volumes
- Avoid manual data entry
- Test integrations properly

**Running migrations:**
```bash
/feature-docker start

# Then run your project's migration command
```

**Fresh database:**
```bash
/feature-docker down
/feature-docker start
# Empty database, run migrations and optionally seed
```

### Configuration Requirements

**Main project needs `docker-compose.yml` with standard ports:**
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"  # Standard port for main
    volumes:
      - .:/app

  db:
    image: postgres:15
    ports:
      - "5432:5432"  # Standard port for main
```

**Main runs normally:**
```bash
# In main directory
docker-compose up
# → http://localhost:3000
```

**Worktree gets auto-generated override:**
```yaml
# docker-compose.override.yml (auto-created)
services:
  app:
    ports:
      - "3007:3000"  # Overrides main's port
  db:
    ports:
      - "5439:5432"  # Overrides main's port
```

**Worktree runs with unique ports:**
```bash
# In worktree
/feature-docker start
# → http://localhost:3007
```

### Resource Management

Docker can use significant resources with multiple features:

```bash
# See all running feature containers
docker stats

# Stop unused features
/feature-docker down
```

**Best Practices:**
- Stop Docker when not actively testing
- Use `down` to free resources completely
- Keep 2-3 features running max
- Clean up completed features

### Troubleshooting Docker

**Port already in use:**
System automatically tries next available port

**Containers won't start:**
```bash
/feature-docker logs
# Check for errors
```

**Can't connect to database:**
Wait 5-10 seconds for DB to initialize on first start

**Want to reset everything:**
```bash
/feature-docker down
/feature-docker start
# Fresh environment!
```

### Advanced: Custom Services

Add feature-specific services by editing `docker-compose.override.yml`:

```yaml
# Add Elasticsearch for search feature
services:
  elasticsearch:
    image: elasticsearch:8
    ports:
      - "9207:9200"  # Unique port
```

---

## Document Templates (templates)

### reqs.md - Requirements

Created by `/feature-start`, includes:
- **Overview:** What and why
- **User Stories:** As a [user], I want [action]...
- **Functional Requirements:** Core functionality, UI, data
- **Non-Functional Requirements:** Performance, security, accessibility
- **Out of Scope:** What's NOT included
- **Open Questions:** Things to clarify
- **Dependencies:** Prerequisites
- **Success Criteria:** How we know it's done

### plan.md - Implementation Plan

Created by `/feature-plan`, includes:
- **Architecture Overview:** High-level approach
- **Technical Approach:** Frontend, backend, infrastructure changes
- **Implementation Steps:** Phased breakdown with details per step
  - What needs to be done
  - Why this approach
  - Files to create/modify
  - Estimated complexity
- **Testing Strategy:** Unit, integration, manual tests
- **Risks & Considerations:** Challenges and alternatives
- **Rollout Plan:** Feature flags, migrations, rollback

### tasks.md - Task Checklist

Created by `/feature-prep` from plan, includes:
- **Implementation Tasks:** TSK1, TSK2, TSK3...
  - Brief description
  - What: Detailed explanation
  - Files: What to create/modify
  - Acceptance: How to verify complete
  - Notes: Important considerations
- **Testing Tasks:** TSK10+
- **Documentation Tasks:** TSK20+
- **Completion Checklist:** Final review items

**Task ID Format:** TSK followed by number (TSK1, TSK2...)

---

## Troubleshooting (troubleshooting)

### "Multiple features found"

**Problem:** Command needs explicit feature name when multiple exist

**Solution:**
```bash
# Instead of:
/feature-plan

# Use:
/feature-plan dark-mode
```

### "No plan found" in /feature-build

**Problem:** You're in the wrong VS Code window (probably main)

**Solution:**
- Check VS Code window title - should show worktree path
- Switch to the window that opened after `/feature-prep`
- If window closed, manually open: File → Open Folder → `../<project>.worktrees/<feature>/`

### Merge conflicts in /feature-end

**Problem:** Normal for active codebases with multiple developers

**Solution:**
```bash
# /feature-end will show:
# ⚠️ Conflicts in: src/App.tsx, src/config.ts

# 1. Open conflicted files
# 2. Look for <<<<<<< markers
# 3. Resolve conflicts manually
# 4. Save files
# 5. Stage: git add <filename>
# 6. Complete merge:
/feature-merge-continue
```

### VS Code window doesn't open

**Problem:** `code` command not in PATH

**Solution:**
- Manually open: File → Open Folder
- Navigate to: `../<project-name>.worktrees/<feature-name>/`
- Or add VS Code to PATH: VS Code → Command Palette → "Install 'code' command"

### Lost changes after /feature-prep

**Problem:** Feature folder moved from main to worktree

**Solution:**
- Not lost! They're in the worktree
- Check: `../<project>.worktrees/<feature>/work/features/<feature>/`
- This is intentional - main stays clean for planning

### Can't find previous features

**Problem:** Looking in wrong location

**Solution:**
```bash
# In main - see features being planned:
ls work/features/

# See active worktrees:
ls ../<project-name>.worktrees/

# Check git worktrees:
git worktree list
```

### Commands not available in worktree

**Problem:** `.claude/` directory is gitignored and not in worktree

**Solution:**
- `/feature-prep` should automatically symlink `.claude/` from main
- If missing, manually create symlink from worktree:
  ```bash
  cd ../<project>.worktrees/<feature>/
  ln -s ../../<project>/.claude .claude
  ```
- Restart Claude Code extension to pick up commands

### Environment variables missing

**Problem:** `.env` files are gitignored and not in worktree

**Solution:**
- `/feature-prep` should symlink `.env` files
- Or manually copy/symlink from main:
  ```bash
  ln -s ../../<project>/.env .env
  ```

### Need to add new symlinks to existing worktree

**Problem:** Discovered you need additional symlinks (e.g., a new config file) after worktree was created

**Solution:**
1. Update your `/feature-prep` extension in `.claude/claudeflow-extensions/feature-prep.md`
2. Run `/feature-prep` from within the worktree
3. It will detect the worktree context and only run environment setup
4. Restart Claude Code extension if commands were updated

---

## Migrating from Old Commands (migration)

If you have existing `/plan` and `/build` commands:

### Old Workflow
```bash
/plan "add feature"
# → creates work/plans/add-feature.md

/build add-feature  
# → creates worktree, starts building
```

### New Workflow
```bash
/feature-start "add feature"
# → creates work/features/add-feature/reqs.md

/feature-plan
# → creates work/features/add-feature/plan.md

/feature-prep
# → generates work/features/add-feature/tasks.md
# → creates worktree
# → opens VS Code

/feature-build
# → task-by-task implementation

/feature-end
# → merge and cleanup
```

### Migration Steps

1. **Organize existing work**
   ```bash
   # Create new structure
   mkdir -p work/features/<feature-name>
   
   # Move existing plan
   mv work/plans/<feature>.md work/features/<feature>/plan.md
   
   # Create requirements (if needed)
   # Add reqs.md manually or run /feature-start
   ```

2. **Update your workflow**
   - Delete old `/plan` and `/build` commands
   - Use new `/feature-*` commands going forward

3. **Benefits of new workflow**
   - Organized feature folders
   - Requirements + plan + tasks together
   - Auto-detection reduces typing
   - Better support for multiple features
   - Cleaner merge process

### What's Different?

| Old | New | Why |
|-----|-----|-----|
| Single plan file | Feature folder (reqs + plan + tasks) | Better organization |
| `/build` creates worktree | `/feature-prep` creates worktree | Separate concerns |
| `/build` implements | `/feature-build` implements | Clear naming |
| Manual merge | `/feature-end` handles it | Safer, automated |
| No requirements phase | `/feature-start` for requirements | Better planning |
| Ad-hoc structure | Standardized structure | Consistency |

---

## Additional Help

**For specific command details:**
Run the command without arguments to see inline help

**Quick reference:**
- Start new feature: `/feature-start "description"`
- When stuck: `/feature-help troubleshooting`
- See all commands: `/feature-help commands`
- See example: `/feature-help example`

**Tips:**
- Commands auto-detect when unambiguous
- Pause points built into workflow
- Work on multiple features in parallel
- Main branch stays clean for planning
- Worktrees are independent workspaces
- Gitignored files (`.claude/`, `.env`) are symlinked from main
- Update commands in main → instantly available in all worktrees

---

## Key Principles

1. **Organized:** Everything for a feature lives together
2. **Parallel:** Work on multiple features simultaneously
3. **Incremental:** Build and review task by task
4. **Clean:** Main branch stays clean and organized
5. **Flexible:** Auto-detection when unambiguous, explicit when needed
6. **Safe:** Pause points, review steps, conflict handling

## Extensions
Check for `.claude/claudeflow-extensions/feature-help.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.
