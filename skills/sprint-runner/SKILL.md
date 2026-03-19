---
name: sprint-runner
description: >
  Autonomous sprint execution engine for documentation-first projects.
  Reads CLAUDE.md sprint definitions + SPRINT_STATUS.md → implements → quality gates → commits → handoff.
  Trigger on: "Sprint N", "execute sprint N", "next sprint", "continue", "resume", "next",
  "start building", "run sprint", "execute all remaining sprints", "let's build", "implement",
  or any prompt in a project with sprint-based CLAUDE.md structure.
  Manages full lifecycle: context loading, ordered implementation, validation, commit, and
  session handoff so the next session picks up exactly where this one ended.
---

# Sprint Runner

Autonomous build engine. Reads your project's CLAUDE.md sprint definitions → implements → validates → commits → hands off.

## Boot Sequence

Before writing any code, always execute in order:

1. **Read `CLAUDE.md`** at project root — source of truth for stack, commands, and sprint definitions. No CLAUDE.md → stop, read `references/setup-guide.md` from this skill, and help user set up their project.
2. **Read `SPRINT_STATUS.md`** if it exists — what's done, in progress, and last session's handoff.
3. **Read architecture doc** referenced in CLAUDE.md (only sections relevant to current sprint).
4. **Determine target sprint** using selection table below.
5. **Read `references/execution-protocol.md`** from this skill — the 6-phase build sequence.
6. **Read `references/quality-gates.md`** from this skill — what "done" means.

## Sprint Selection

| User says | Action |
|---|---|
| "Sprint N" | Execute Sprint N from CLAUDE.md |
| "next" / "continue" / "next sprint" | SPRINT_STATUS.md → last completed → run N+1 |
| "resume" | SPRINT_STATUS.md Handoff section → continue from exact step |
| "execute all remaining" | Sequential, commit each, confirm between sprints |
| No SPRINT_STATUS.md | Assume Sprint 1 — confirm before running |
| No sprint definitions in CLAUDE.md | Stop. Read `references/setup-guide.md` and help user structure their project. |

## Task Tracking

Use Claude Code TaskCreate/TaskUpdate to give the user real-time visibility:

1. **At ANNOUNCE phase**: Create one task per sprint deliverable with `TaskCreate`. Set meaningful `activeForm` (e.g., "Implementing user auth service").
2. **At IMPLEMENT phase**: Mark current task `in_progress` with `TaskUpdate` before starting work on it.
3. **At VALIDATE phase**: Only mark task `completed` after its quality gates pass.
4. **On error/blocker**: Keep task `in_progress`, create a new blocking task describing the issue.

## Core Rules

- **CLAUDE.md is law.** Never deviate. If ambiguous → stop, ask, document answer in CLAUDE.md.
- **Stack-agnostic.** Read build/lint/test commands from CLAUDE.md — never assume a specific toolchain.
- **Type safety always.** Use the project's type system fully. No escape hatches.
- **No debug artifacts.** Remove all console.log/print/debugger before commit.
- **Secrets in env only.** Document every new env var in `.env.example`.
- **Validate at boundaries.** All external inputs validated before reaching business logic.
- **Typed errors.** Every error case handled explicitly. No silent failures, no bare strings.
- **Safe git staging.** Never `git add -A`. Stage specific files by name. Review diff before commit.
- **Safe deletion.** Use `trash` instead of `rm -rf`. Never use `rm`.
- **Match the codebase.** Scan existing patterns before writing. New code must look like it belongs.
- **Don't break what works.** Run the full test suite, not just the current sprint's tests.

## References

- **`references/execution-protocol.md`** — 6-phase build sequence with advanced protocol hooks at each phase (pre-flight scan, context budget, pattern matching, regression check, metrics, retro)
- **`references/quality-gates.md`** — Universal gates, per-sprint-type checklists, security audit, error recovery, .env.example sync
- **`references/advanced-protocols.md`** — 7 staff-level protocols: pre-flight codebase scan, context budget estimation, codebase pattern matching, cross-sprint regression, post-sprint metrics, .env.example sync, sprint retrospective
- **`references/setup-guide.md`** — How to prepare a codebase for sprint-runner: CLAUDE.md structure, architecture doc, .env.example, linter/typecheck setup, sprint definition examples
