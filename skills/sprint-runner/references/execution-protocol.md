# Execution Protocol

6-phase build sequence. Follow every phase in order. Never skip.
Advanced protocols from `references/advanced-protocols.md` are integrated at their hook points below.

---

## Phase 1 — READ

Fully understand the sprint before touching any file.

- Read complete sprint definition in CLAUDE.md
- List every file to create or modify — write it out explicitly
- Identify dependencies from previous sprints — verify they exist
- Identify risks — name them before hitting them
- Read the project's build/lint/test commands from CLAUDE.md (never assume toolchain)

Sprint definition incomplete or ambiguous → **stop**, ask user, document answer in CLAUDE.md, then continue.

### → Pre-Flight Codebase Scan

Before implementing, scan the codebase to understand existing patterns. See `references/advanced-protocols.md` §1.

- Glob for files similar to what you're about to create
- Read 2-3 representative files to extract: naming, exports, error handling, DI, test patterns
- Note existing abstractions to reuse
- Check available libraries before adding new deps

---

## Phase 2 — ANNOUNCE

State the plan before writing code. Create tasks for tracking.

```
Executing Sprint N: [Name]

Codebase context:
- [Patterns discovered in pre-flight scan]
- [Existing abstractions to reuse]

Tasks:
1. [Task] → files: [list]
2. [Task] → files: [list]

Dependencies from previous sprints: [list or "none"]
Risks: [list]

Starting now.
```

**TaskCreate**: Create one task per deliverable. Use clear `activeForm` descriptions.

This is a plan check — the user stops you here, not after 200 lines of code.

### → Context Budget Check

Estimate sprint size. See `references/advanced-protocols.md` §2.

- Small (1-3 files) → proceed
- Medium (4-8 files) → proceed, monitor context
- Large (9-15 files) → warn user, suggest sub-sprint split
- Too large (15+ files) → **must split**, propose sub-sprints, get confirmation

---

## Phase 3 — IMPLEMENT

**TaskUpdate**: Mark current task `in_progress` before starting each deliverable.

Build in dependency order, adapting to the project's stack:

1. **Data layer** — Schema, models, types, migrations. Lock the data shape first.
2. **Core logic** — Services, domain logic, business rules. Pure functions, no framework deps.
3. **Interface layer** — Routes, controllers, CLI. Keep thin. Validate inputs here.
4. **Infrastructure** — Middleware, config, logging, env wiring.
5. **External integrations** — Third-party APIs last. Never integrate before local logic works.

Within each file: types → happy path → error handling → edge cases.

Don't skip steps to "come back later."

### → Pattern Matching (before each new file)

See `references/advanced-protocols.md` §3.

Before creating any new file:
1. Find the closest existing file of the same type
2. Mirror its structure, imports, exports, error handling, naming
3. Reuse existing utilities — extend, don't duplicate

**Rule**: New files must look like they were written by the same person who wrote the rest of the codebase.

---

## Phase 4 — VALIDATE

Run quality gates from `references/quality-gates.md` for this sprint type.

Use the project's commands from CLAUDE.md:

```bash
# Typecheck — command from CLAUDE.md (e.g., pnpm tsc --noEmit)
# Lint — command from CLAUDE.md (e.g., pnpm eslint src/ --max-warnings 0)
# Test — command from CLAUDE.md (e.g., pnpm test)
```

### Error Recovery

| Failure | Action |
|---|---|
| Typecheck errors | Fix all type errors. Never use `any` or `as` to silence them. |
| Lint warnings | Fix every warning. Do not disable rules without documenting why in CLAUDE.md. |
| Test failures | Fix failing tests. If test expectation is wrong, fix test AND document why. |
| Build failure | Read error output carefully. Fix root cause, not symptoms. |
| 3+ failed attempts on same issue | Stop. Ask user for guidance. Don't brute-force. |

Only proceed to Phase 5 when ALL checks pass. **TaskUpdate**: Mark task `completed` only after validation.

### → .env.example Sync

See `references/advanced-protocols.md` §6.

Scan all source files for env var references (`process.env.X`, `os.environ`, etc.). Every var must have a corresponding entry in `.env.example` with a descriptive comment. Flag missing or stale vars.

### → Cross-Sprint Regression Check

See `references/advanced-protocols.md` §4.

After this sprint's tests pass, run the **full** test suite. A sprint that passes its own tests but breaks previous ones is not done.

- Previous tests pass → proceed
- 1-2 failures → fix in current sprint code, re-run
- Many failures → likely architectural conflict, stop and review with user
- Old test genuinely outdated → ask user before modifying

---

## Phase 5 — COMMIT

```bash
# 1. Stage specific files — NEVER use git add -A or git add .
git add src/models/user.ts src/services/auth.ts ...

# 2. Review staged changes
git diff --cached --stat

# 3. Secret scan
git diff --cached | grep -iE "(password|secret|api.?key|token|private.?key|credentials)" \
  | grep -vE "(hash|placeholder|example|_test|schema|type|interface|\.env\.example)"

# 4. Commit with conventional message
git commit -m "feat(scope): Sprint N — short description

- What was built
- What was built

Refs: CLAUDE.md Sprint N"
```

Commit types: `feat` / `fix` / `chore` / `refactor` / `wip` (partial only)

**Never commit if any validation step failed.** A partial sprint is better than a broken commit.

### Rollback

If a commit introduces a regression discovered before moving on:

```bash
# Inspect what went wrong
git log --oneline -5
git diff HEAD~1

# Revert cleanly — never use reset --hard
git revert HEAD --no-edit
```

Then fix the issue and create a new commit. Never amend published commits.

---

## Phase 6 — CLOSE

### → Post-Sprint Metrics

See `references/advanced-protocols.md` §5.

Gather metrics before reporting:

```bash
git diff --stat HEAD~1
git diff --shortstat HEAD~1
```

Add Metrics section to SPRINT_STATUS.md.

### → Sprint Retrospective

See `references/advanced-protocols.md` §7.

Write a brief retro in SPRINT_STATUS.md:
- **Smooth**: what went well
- **Friction**: what was harder than expected
- **Watch**: what the next sprint should be careful about

### Update & Report

1. **Update SPRINT_STATUS.md**:
   - Mark sprint `[x]` complete with date
   - Add Metrics section
   - Add Retro section
   - Log deviations in Decisions Made
   - Update CLAUDE.md if decisions changed the architecture

2. **Report to user**:
   ```
   Sprint N complete.

   Built: [summary]
   Committed: [short hash]

   Metrics:
     X files changed, +Y/-Z lines
     N tests added (M total)
     0 type errors, 0 lint warnings

   Retro:
     Smooth: [brief]
     Friction: [brief]
     Watch: [brief]

   Next: Sprint N+1 — [name]
   Say "next sprint" to continue.
   ```

---

## Mid-Sprint Interruption

When context is getting full or user stops mid-sprint:

```bash
# Commit partial work — stage specific files only
git add [specific files]
git commit -m "wip(scope): Sprint N partial — [what's done]"
```

Write the Handoff section in SPRINT_STATUS.md:

```markdown
## Handoff (session ended mid-sprint)
Last action: [exact last step completed]
Next action: [exact next step + file + function name]
Blocker: [decision needed, or "none"]
Files modified: [list]
Tasks remaining: [list of incomplete TaskCreate items]
Codebase context: [patterns discovered in pre-flight, so next session doesn't re-scan]
```

Tell user: *"Session saved. Say 'resume Sprint N' in a new session to continue."*

---

## SPRINT_STATUS.md Template

Create at project root after Sprint 1. Update after every sprint and session.

```markdown
# Sprint Status — [Project Name]

## Completed
- [x] Sprint 1 — Name (YYYY-MM-DD)

## In Progress
- [ ] Sprint 2 — Name (started: YYYY-MM-DD)

## Pending
- [ ] Sprint 3 — Name
- [ ] Sprint 4 — Name

## Metrics — Sprint N
- Files changed: X
- Lines: +Y / -Z
- Tests: N added (M total)
- Type errors: 0
- Lint warnings: 0

## Retro — Sprint N
### Smooth
- [what went well]
### Friction
- [what was harder than expected]
### Watch for next sprint
- [dependencies, debt, decisions to revisit]

## Decisions Made
- Sprint 1: Changed X to Y because [reason] — CLAUDE.md updated

## Handoff (session ended mid-sprint)
Last action: [exact description]
Next action: [exact next step + file + function]
Blocker: [decision needed, or "none"]
Files modified: [list]
Tasks remaining: [list]
Codebase context: [patterns from pre-flight scan]
```
