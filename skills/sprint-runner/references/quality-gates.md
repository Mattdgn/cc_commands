# Quality Gates

What "done" means. Run the relevant checklist before every commit.

---

## Universal Gates — every sprint, every commit

```
[ ] Build/typecheck passes (use project's command from CLAUDE.md)
[ ] Lint passes with zero warnings (not just zero errors)
[ ] No debug output in production code (console.log, print, debugger, pp, dump)
[ ] No hardcoded secrets or API keys in staged files
[ ] All new env vars documented in .env.example
[ ] SPRINT_STATUS.md updated
[ ] git diff --cached reviewed — only intended files staged
[ ] Staged specific files (never git add -A)
[ ] Secret scan passed (see below)
```

### Secret Scan

```bash
# Stage 1: Pattern scan on staged changes
git diff --cached | grep -iE \
  "(password|secret|api.?key|token|private.?key|credentials|bearer|auth_token|client_secret)" \
  | grep -vE "(hash|placeholder|example|_test|schema|type|interface|\.env\.example|process\.env|import)"

# Stage 2: File check — none of these should be staged
git diff --cached --name-only | grep -iE "(\.env$|\.env\.|\.pem$|\.key$|id_rsa|credentials)"
```

If anything is flagged → unstage the file, investigate, fix before committing.

---

## Data Layer Sprint

Schema, models, migrations, database setup.

```
[ ] All tables/models: id (PK), created_at, updated_at where relevant
[ ] Unique constraints on business-unique fields
[ ] Indexes on foreign keys and common query fields
[ ] Migration runs clean on fresh database
[ ] Migration is reversible — or documented as irreversible
[ ] No business logic in schema files
[ ] Monetary values: integers (cents, lamports) — never floats
[ ] Enums in schema, not magic strings
[ ] Append-only tables (audit, ledger): no UPDATE/DELETE at ORM level
```

---

## Auth / Identity Sprint

```
[ ] Passwords: bcrypt or argon2, cost >= 12, never logged, never in responses
[ ] Tokens: SHA-256 hashed before storage, raw value returned once only
[ ] JWT: asymmetric key (RS256/ES256) — not HS256 shared secret
[ ] Access token TTL: 15-60 min max
[ ] Refresh token: rotated on every use, old token invalidated
[ ] Refresh token reuse → revoke ALL user sessions
[ ] Rate limiting on all auth endpoints
[ ] Verification codes: stored with TTL, single-use, deleted after use
[ ] Audit log: login success/fail, logout, password change, session revoke
[ ] httpOnly + secure + sameSite=strict on session cookies
[ ] CSRF protection on cookie-based flows
```

---

## API / Routes Sprint

```
[ ] All inputs validated at entry point before reaching services
[ ] Validation schema per request body (Zod, Pydantic, Joi, etc.)
[ ] Auth middleware on all protected routes
[ ] Authorization per action — not just "is authenticated"
[ ] Error responses: consistent format, no stack traces, no internals leaked
[ ] All list endpoints paginated
[ ] Correct HTTP status codes (201/400/401/403/404/409)
[ ] Rate limiting on public/expensive endpoints
[ ] Request logging: method, path, status, duration — not body (PII risk)
```

---

## Business Logic / Services Sprint

```
[ ] Services are pure — no HTTP, no framework, no CLI deps
[ ] Every function has explicit input and return types
[ ] Error cases return typed errors — no raw strings
[ ] No direct DB access outside service layer
[ ] Side effects (email, webhook, events) are explicit, not hidden
[ ] State transitions validated — no illegal jumps
[ ] Financial calculations: integer arithmetic only
[ ] Immutable records: no UPDATE path in code
```

---

## Integration Sprint

```
[ ] All credentials in env vars
[ ] Webhook signatures verified (HMAC, Stripe-Signature, etc.)
[ ] Idempotency: duplicate events handled without double-processing
[ ] Retry with exponential backoff on outbound calls
[ ] Timeout set on every outbound HTTP request
[ ] Third-party errors: logged with context, returned as typed error
[ ] Third-party down: graceful degradation (queue, fallback, or clear error)
[ ] Webhook delivery log: every outbound webhook recorded
```

---

## Frontend / UI Sprint

```
[ ] No secrets or API keys in client-side code
[ ] User inputs sanitized — no raw innerHTML with user data
[ ] Auth state enforced — unauthed users can't reach protected pages
[ ] Loading states on every async action
[ ] Error states on every async action
[ ] Forms: client AND server validation — never one without the other
[ ] No console.log in production build
```

---

## Error Recovery Strategy

When a quality gate fails:

| Failure | Strategy |
|---|---|
| 1-2 type errors | Fix directly, re-run typecheck |
| Many type errors | Likely architectural issue — re-read sprint requirements, check if data layer matches |
| Lint warnings | Fix each warning. If a rule is genuinely wrong for this project, disable it in config (not inline) and document in CLAUDE.md |
| Test failures | Read test output carefully. Fix code, not tests — unless test expectation is proven wrong |
| Secret detected | Unstage file immediately. Move secret to .env. Update .env.example. |
| Build failure | Read full error output. Fix root cause. Don't add workarounds. |
| 3+ failed attempts | **Stop.** Ask user. Don't loop. |

---

## Security Audit — before milestone releases

```bash
# Debug output (adapt grep patterns to project language)
grep -rn "console\.log\|debugger" src/ --include="*.ts" --include="*.tsx" --include="*.js"

# Hardcoded secrets
grep -rn "password\s*=\s*['\"]" src/
grep -rn "api_key\s*=\s*['\"]" src/

# Unresolved debt
grep -rn "TODO\|FIXME\|HACK\|XXX" src/
```

Manual checks:
```
[ ] Auth middleware tested: missing token → 401, tampered → 401
[ ] Rate limits tested: exceed → correct rejection
[ ] CORS: explicit allowlist, no wildcard * in production
[ ] .env in .gitignore, .env.example up to date
[ ] Dependency audit: no high/critical vulnerabilities
```

---

## Definition of Done

A sprint is **complete** when:

1. Universal gates pass
2. Sprint-type gates pass
3. `git log --oneline -1` shows the sprint commit
4. `SPRINT_STATUS.md` shows sprint as `[x]` with date
5. All TaskCreate items marked `completed`

Security gates don't carry over. Fix them in this sprint.
