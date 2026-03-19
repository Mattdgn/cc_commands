# Advanced Protocols

Protocols that elevate sprint execution from "gets it done" to "staff-level engineering." Integrated into the 6-phase execution at specific hook points.

---

## 1. Pre-Flight Codebase Scan

**Hook point**: Phase 1 (READ), after reading sprint definition.

Before implementing anything, understand the codebase you're building into.

```
1. Glob for files similar to what you're about to create
   → e.g., building a new service? Find existing services: src/services/*.ts
2. Read 2-3 representative files to extract patterns:
   - Naming conventions (camelCase, kebab-case, PascalCase for files?)
   - Export style (named exports, default exports, barrel files?)
   - Error handling pattern (Result types, thrown errors, error classes?)
   - Dependency injection pattern (constructor, factory, context?)
   - Test file location and naming (co-located? __tests__/? .test.ts? .spec.ts?)
3. Note existing abstractions to reuse — don't rebuild what exists
4. Check package.json / pyproject.toml for available libraries before adding new ones
```

Output a brief "Codebase context" summary in the ANNOUNCE phase:

```
Codebase context:
- Existing pattern: services use factory functions with typed errors (Result<T, E>)
- Test pattern: co-located .test.ts files with vitest
- Available libs: zod (validation), drizzle (ORM), hono (server)
- Reusable: src/lib/errors.ts has AppError base class → extend it, don't create new one
```

**Rule**: Never create a pattern that contradicts an existing one. If you see the codebase uses Result types, don't throw errors. If tests are co-located, don't create a __tests__/ directory.

---

## 2. Context Budget Estimation

**Hook point**: Phase 2 (ANNOUNCE), before starting implementation.

Estimate whether the sprint fits in the current context window.

### Heuristic

| Sprint size | Indicators | Action |
|---|---|---|
| Small | 1-3 files, single layer (data OR logic OR routes) | Execute normally |
| Medium | 4-8 files, 2 layers | Execute normally, monitor context |
| Large | 9-15 files, 3+ layers | Warn user, suggest sub-sprint split |
| Too large | 15+ files, full-stack feature | **Must split.** Propose sub-sprints before starting. |

### Auto-split strategy

When a sprint is too large, propose splitting by layer:

```
Sprint N is large (estimated 18 files across 4 layers). Recommend splitting:

Sprint N.1 — Data layer: schema + migrations + types (5 files)
Sprint N.2 — Service layer: business logic + validators (6 files)
Sprint N.3 — API layer: routes + middleware + controllers (5 files)
Sprint N.4 — Integration: wire everything + env config (2 files)

Each sub-sprint commits independently. Proceed with N.1?
```

Always get user confirmation before splitting.

---

## 3. Codebase Pattern Matching

**Hook point**: Phase 3 (IMPLEMENT), before creating each new file.

Before writing any new file:

```
1. Find the closest existing file to what you're about to create
   → Creating src/services/payment.ts? Read src/services/auth.ts first.
   → Creating src/routes/orders.ts? Read src/routes/users.ts first.

2. Mirror its structure:
   - Same import ordering
   - Same export pattern
   - Same error handling approach
   - Same comment style (or lack thereof)
   - Same test structure if tests exist

3. Reuse existing utilities:
   - Existing validation schemas → extend, don't duplicate
   - Existing error types → extend, don't create parallel hierarchy
   - Existing middleware → compose, don't rewrite
   - Existing test helpers → import, don't copy
```

**Rule**: The new file should look like it was written by the same person who wrote the rest of the codebase.

---

## 4. Cross-Sprint Regression Check

**Hook point**: Phase 4 (VALIDATE), after current sprint's tests pass.

After Sprint N's quality gates pass, verify Sprint N didn't break previous work:

```bash
# Run the FULL test suite, not just Sprint N's tests
# Use the project's test command from CLAUDE.md

# If a previous sprint's test fails:
# 1. DO NOT modify the old test to make it pass
# 2. Read the failing test to understand what contract it enforces
# 3. Fix the Sprint N code that broke the contract
# 4. Re-run full suite until everything passes
```

| Scenario | Action |
|---|---|
| All previous tests pass | Proceed to commit |
| 1-2 previous tests fail | Fix regression in Sprint N's code, re-run |
| Many previous tests fail | Likely architectural conflict — stop, review with user |
| Previous test is genuinely outdated | Ask user before modifying — never silently "fix" old tests |

**Rule**: A sprint that passes its own tests but breaks previous ones is not done.

---

## 5. Post-Sprint Metrics

**Hook point**: Phase 6 (CLOSE), as part of the sprint report.

After committing, gather and report metrics:

```bash
# Files changed in this sprint
git diff --stat HEAD~1

# Lines added/removed
git diff --shortstat HEAD~1

# Total test count (adapt to project)
# e.g., grep -r "it(" src/ --include="*.test.ts" | wc -l

# Type coverage (if available)
# e.g., npx tsc --noEmit 2>&1 | tail -1
```

Add a Metrics section to SPRINT_STATUS.md:

```markdown
## Metrics — Sprint N
- Files changed: 8
- Lines: +342 / -28
- Tests: 12 added (total: 47)
- Type errors: 0
- Lint warnings: 0
```

Report to user alongside the sprint summary:

```
Sprint N complete.

Built: [summary]
Committed: abc1234

Metrics:
  8 files changed, +342/-28 lines
  12 tests added (47 total)
  0 type errors, 0 lint warnings

Next: Sprint N+1 — [name]
```

---

## 6. Auto .env.example Sync

**Hook point**: Phase 4 (VALIDATE), as part of quality gates.

Scan all source files for environment variable references and verify each has a corresponding entry in `.env.example`.

```bash
# Find all env var references (adapt patterns to project language)
# TypeScript/JavaScript:
grep -rn "process\.env\.\w\+" src/ --include="*.ts" --include="*.tsx" --include="*.js" \
  | grep -oP "process\.env\.\K\w+" | sort -u

# Python:
grep -rn "os\.environ\[.\w\+.\]|os\.getenv\(.\w\+.\)" src/ --include="*.py" \
  | grep -oP "(?:environ\[|getenv\()['\"]?\K\w+" | sort -u

# Compare against .env.example
# Every var found in code must exist in .env.example
```

| Result | Action |
|---|---|
| All vars in .env.example | Pass |
| Missing vars | Add them to .env.example with descriptive placeholder |
| Vars in .env.example not in code | Flag as potentially stale — ask user before removing |

Template for new .env.example entries:

```bash
# [Description of what this var does]
# Required: yes/no
# Example: the-format-or-example
NEW_VAR_NAME=
```

---

## 7. Sprint Retrospective

**Hook point**: Phase 6 (CLOSE), after metrics.

Write a brief retro in SPRINT_STATUS.md. This is institutional memory — the next session (or developer) reads this and knows what to expect.

```markdown
## Retro — Sprint N

### Smooth
- [What went well, what was straightforward]

### Friction
- [What was harder than expected, what took multiple attempts]
- [Any ambiguity in CLAUDE.md that needed clarification]

### Watch for next sprint
- [Dependencies or patterns to be careful about]
- [Technical debt introduced that needs addressing]
- [Decisions that might need revisiting]
```

Rules:
- Keep it honest. "Everything was fine" is never true.
- Be specific. "Auth was tricky" → "Token rotation required a custom middleware because Hono doesn't support it natively — see src/middleware/token-rotation.ts"
- If a CLAUDE.md decision was wrong, say so and suggest the update.
- If technical debt was introduced, name it explicitly so it doesn't become invisible.
