# Sprint Runner — Setup Guide

Comment préparer ta codebase pour que le sprint-runner tourne de manière optimale.

---

## Checklist rapide

```
[ ] 1. Git repo initialisé
[ ] 2. CLAUDE.md à la racine avec stack + commands + sprints
[ ] 3. Architecture doc (optionnel mais recommandé)
[ ] 4. .env.example avec les vars existantes
[ ] 5. .gitignore propre
[ ] 6. Linter + typecheck configurés et fonctionnels
[ ] 7. Au moins un test qui passe (même vide)
```

---

## 1. CLAUDE.md — Le fichier le plus important

C'est la source de vérité. Le sprint-runner lit ce fichier en premier et ne fait **rien** sans lui.

### Structure minimum

```markdown
# [Nom du Projet]

## Stack
- [Framework] + [Language] + [UI lib] + [CSS]
- [Backend framework]
- [Database]
- [ORM]

## Commands
- Install: `pnpm install`
- Dev: `pnpm dev`
- Build: `pnpm build`
- Typecheck: `pnpm tsc --noEmit`
- Lint: `pnpm eslint src/ --max-warnings 0`
- Test: `pnpm test`
- Format: `pnpm prettier --write .`

## Architecture
- Voir `docs/architecture.md` pour le détail complet
- [OU décrire l'architecture directement ici si elle est simple]

## Sprints

### Sprint 1 — [Nom descriptif]
- [ ] Tâche 1 : description claire de ce qui doit être construit
- [ ] Tâche 2 : description claire
- [ ] Tâche 3 : description claire

### Sprint 2 — [Nom descriptif]
- [ ] Tâche 1
- [ ] Tâche 2

### Sprint 3 — [Nom descriptif]
- [ ] Tâche 1
- [ ] Tâche 2
```

### Exemple concret (projet Next.js + Hono)

```markdown
# ForgePay

## Stack
- Next.js 15 + TypeScript + Tailwind + shadcn/ui
- Hono server (API)
- PostgreSQL + Drizzle ORM
- Redis (sessions, rate limiting)

## Commands
- Install: `pnpm install`
- Dev: `pnpm dev`
- Build: `pnpm build`
- Typecheck: `pnpm tsc --noEmit`
- Lint: `pnpm eslint src/ --max-warnings 0`
- Test: `pnpm vitest run`
- DB migrate: `pnpm drizzle-kit push`
- DB generate: `pnpm drizzle-kit generate`

## Project Structure
src/
├── app/              # Next.js pages (App Router)
├── components/       # React components
│   ├── ui/           # shadcn/ui base components
│   └── features/     # Feature-specific components
├── server/
│   ├── routes/       # Hono API routes
│   ├── services/     # Business logic (pure functions)
│   ├── models/       # Drizzle schemas
│   └── middleware/    # Auth, rate limiting, validation
├── lib/              # Shared utilities, types, errors
└── config/           # Env config, constants

## Architecture
- Voir `docs/architecture.md`
- Pattern: services purs → routes thin → middleware composable
- Errors: Result<T, E> pattern avec src/lib/errors.ts
- Validation: Zod schemas co-localisés avec les routes

## Conventions
- Fichiers: kebab-case (user-service.ts)
- Exports: named exports, pas de default
- Tests: co-localisés (user-service.test.ts à côté de user-service.ts)
- Env vars: SCREAMING_SNAKE_CASE, documentées dans .env.example

## Sprints

### Sprint 1 — Foundation
- [ ] Setup Drizzle + schéma users (id, email, password_hash, created_at, updated_at)
- [ ] Setup Hono server avec health check route
- [ ] Config .env.example avec DATABASE_URL, REDIS_URL, JWT_SECRET
- [ ] Middleware: error handler global avec typed errors

### Sprint 2 — Auth
- [ ] Service auth: register, login, logout, refresh token
- [ ] Routes: POST /auth/register, POST /auth/login, POST /auth/logout, POST /auth/refresh
- [ ] Middleware: auth guard (vérifie JWT, injecte user dans context)
- [ ] Rate limiting sur les routes auth (10 req/min)
- [ ] Tests: auth service + auth routes

### Sprint 3 — Payments
- [ ] Schéma: transactions table (double-entry ledger)
- [ ] Service: create transaction, get balance, list transactions
- [ ] Routes: POST /transactions, GET /transactions, GET /balance
- [ ] Intégration Stripe Connect (onboarding flow)
- [ ] Webhook handler pour Stripe events

### Sprint 4 — Frontend
- [ ] Layout: sidebar + header + main content
- [ ] Pages: login, register, dashboard, transactions
- [ ] Components: transaction list, balance card, payment form
- [ ] Auth state: redirect si pas connecté, refresh token auto
```

### Ce qui rend un bon CLAUDE.md

| Bien | Pas bien |
|---|---|
| `Typecheck: pnpm tsc --noEmit` | Pas de section Commands |
| `Sprint 2 — Auth` avec tâches détaillées | `Sprint 2 — faire le backend` |
| Structure de dossiers expliquée | Aucune indication d'où mettre les fichiers |
| Conventions nommées | Chaque fichier a un style différent |
| Architecture doc référencée | "on verra au fur et à mesure" |

### Pièges à éviter

- **Tâches trop vagues** : "Faire l'API" → le runner ne sait pas quels endpoints créer
- **Pas de commands** : le runner doit deviner comment build/lint/test → il va hardcoder des trucs
- **Sprint trop gros** : 20+ tâches dans un sprint → le context va exploser, il va devoir split
- **Pas de conventions** : le runner va inventer les siennes, et elles seront incohérentes avec ton code existant

---

## 2. Architecture Doc (optionnel mais recommandé)

Pour les projets non-triviaux, un doc dédié évite de surcharger CLAUDE.md.

### Où le mettre

```
docs/architecture.md
```

Référencé dans CLAUDE.md : `Voir docs/architecture.md`

### Ce qu'il doit contenir

```markdown
# Architecture — [Projet]

## Vue d'ensemble
[Diagramme ASCII ou description du flow principal]

## Data Model
[Relations entre les tables/models principaux]

## API Design
[Liste des endpoints avec méthode + path + description courte]

## Auth Flow
[Comment l'authentification fonctionne de bout en bout]

## External Services
[Quels services tiers, comment ils sont intégrés, quels env vars]

## Decisions
[Choix architecturaux et pourquoi — ex: "Pourquoi Hono au lieu d'Express"]
```

Le sprint-runner lit **seulement les sections pertinentes** au sprint en cours — pas besoin de tout détailler dès le départ. Tu peux l'enrichir au fur et à mesure.

---

## 3. .env.example

Doit exister dès le Sprint 1. Le runner le vérifie à chaque commit.

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# Redis
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET=your-secret-here
# Required: yes
# Format: random string, min 32 chars

# Stripe (Sprint 3)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Règles :
- Jamais de vraies valeurs — uniquement des placeholders
- Un commentaire par var : ce que c'est, format attendu
- Groupées par domaine
- Ajoutées au moment où le code les utilise, pas avant

---

## 4. .gitignore

Le minimum pour que le runner ne stage pas de fichiers dangereux :

```gitignore
# Env
.env
.env.local
.env.*.local

# Dependencies
node_modules/
.pnpm-store/

# Build
.next/
dist/
out/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
id_rsa*
credentials.json
```

---

## 5. Linter + Typecheck

Le runner refuse de commit si le lint ou le typecheck fail. Configure-les **avant** de lancer le premier sprint.

### TypeScript

```json
// tsconfig.json — strict mode obligatoire
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### ESLint

```bash
pnpm add -D eslint @eslint/js typescript-eslint
```

Vérifie que `pnpm eslint src/` tourne sans crash avant de lancer un sprint.

### Vérification

```bash
# Ces 3 commandes doivent passer AVANT le premier sprint
pnpm tsc --noEmit        # 0 errors
pnpm eslint src/          # 0 errors, 0 warnings
pnpm test                 # suite vide OK, mais doit pas crash
```

---

## 6. Premier test

Le runner lance les tests à chaque sprint. Si le test runner crash au lieu de retourner "0 tests", ça bloque tout.

```bash
# Vérifie que le test runner est installé et fonctionne
pnpm test
# Doit retourner "0 tests passed" ou équivalent, PAS une erreur
```

Si tu utilises vitest :
```bash
pnpm add -D vitest
```

```json
// package.json
{
  "scripts": {
    "test": "vitest run"
  }
}
```

---

## 7. Structure de dossiers initiale

Tu n'as pas besoin de tout créer — le runner le fera. Mais les dossiers racine doivent exister :

```bash
mkdir -p src docs
touch docs/architecture.md
```

Le runner créera les sous-dossiers (`src/services/`, `src/routes/`, etc.) quand il en aura besoin, en suivant la structure définie dans CLAUDE.md.

---

## Résumé — prêt à lancer

```
mon-projet/
├── CLAUDE.md                 ← Stack + Commands + Sprints
├── docs/
│   └── architecture.md       ← Architecture détaillée
├── .env.example              ← Toutes les vars avec placeholders
├── .gitignore                ← .env, node_modules, etc.
├── tsconfig.json             ← strict: true
├── package.json              ← scripts: build, lint, test
└── src/                      ← Dossier source (peut être vide)
```

Ensuite :

```
claude
> "Execute Sprint 1"
```

Le runner fait le reste.
