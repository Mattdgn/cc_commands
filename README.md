# Claude Code Config

My personal Claude Code configuration. Copy to `~/.claude/`.

## Contents

### `settings.json`
Global configuration:
- **Permissions** — granular allow/deny (no `rm`, no `.env` reads, etc.)
- **Hooks** — beep + focus Zed on Notification/PermissionRequest/Stop, sprint auto-save on PreCompact
- **Status line** — custom mono minimal bar (see `status-line.sh`)
- **Plugins** — swift-lsp, vercel-plugin
- **Spinner** — custom humorous messages
- **Language** — french

### `CLAUDE.md`
Global instructions: stack (Next.js/TS/Tailwind/shadcn/Hono), standards (strict TS, max 70 lines), pnpm only, no rm.

### `status-line.sh`
Mono minimal status line: directory, git branch, model, cost, tokens, context bar, duration.

### `commands/`
Custom slash commands:
- `/security-audit` — full security audit → `SECURITY_AUDIT.md`
- `/optimize-perf` — full performance audit → `PERFORMANCE_AUDIT.md`
- `/qa-report-and-ghac` — QA audit + tests + CI/CD → `QA_REPORT.md`
- `/inte-forge-connect` — ForgeConnect integration

### `skills/`
Installed skills:
- `find-skills` — skill discovery
- `frontend-design` — distinctive, production-grade frontend design
- `next-best-practices` — Next.js conventions (RSC, data patterns, metadata, etc.)
- `shadcn-ui` — complete shadcn/ui patterns
- `skill-creator` — skill creation guide
- `solana-dev` — end-to-end Solana playbook
- `sprint-runner` — autonomous documentation-first sprint execution
- `vercel-react-best-practices` — React/Next.js optimization by Vercel Engineering

## Setup

```bash
git clone <repo> ~/config_cc
cp ~/config_cc/settings.json ~/.claude/settings.json
cp ~/config_cc/status-line.sh ~/.claude/status-line.sh
cp ~/config_cc/CLAUDE.md ~/.claude/CLAUDE.md
cp ~/config_cc/commands/*.md ~/.claude/commands/
cp -R ~/config_cc/skills/* ~/.claude/skills/
chmod +x ~/.claude/status-line.sh
```
