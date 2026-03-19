# Claude Code Config

Ma configuration Claude Code personnelle. À copier dans `~/.claude/`.

## Contenu

### `settings.json`
Configuration globale :
- **Permissions** — allow/deny granulaires (pas de `rm`, pas de lecture `.env`, etc.)
- **Hooks** — beep + focus Zed sur Notification/PermissionRequest/Stop, sprint auto-save sur PreCompact
- **Status line** — barre custom mono minimal (voir `status-line.sh`)
- **Plugins** — swift-lsp, vercel-plugin
- **Spinner** — messages custom humoristiques
- **Langue** — français

### `CLAUDE.md`
Instructions globales : stack (Next.js/TS/Tailwind/shadcn/Hono), standards (strict TS, max 70 lignes), pnpm only, pas de rm.

### `status-line.sh`
Status line mono minimal : dossier, branche git, modèle, coût, tokens, barre de contexte, durée.

### `commands/`
Slash commands personnalisées :
- `/security-audit` — audit sécu complet → `SECURITY_AUDIT.md`
- `/optimize-perf` — audit perf complet → `PERFORMANCE_AUDIT.md`
- `/qa-report-and-ghac` — audit QA + tests + CI/CD → `QA_REPORT.md`
- `/inte-forge-connect` — intégration ForgeConnect

### `skills/`
Skills installées :
- `find-skills` — découverte de skills
- `frontend-design` — design frontend distinctif et production-grade
- `next-best-practices` — conventions Next.js (RSC, data patterns, metadata, etc.)
- `shadcn-ui` — patterns shadcn/ui complets
- `skill-creator` — guide de création de skills
- `solana-dev` — playbook Solana end-to-end
- `sprint-runner` — exécution autonome de sprints documentation-first
- `vercel-react-best-practices` — optimisation React/Next.js Vercel Engineering

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
