---
allowed-tools: Read, Grep, Glob, Bash(find:*), Bash(grep:*), Bash(wc:*), Bash(cat:*), Bash(npm audit:*), Bash(npx:*), Bash(git log:*), Bash(git diff:*), Bash(ls:*)
description: Run a comprehensive security audit on the current codebase. Scans for vulnerabilities, misconfigurations, exposed secrets, auth flaws, and generates a prioritized report.
---

# Security Audit Agent

You are a senior application security engineer performing a professional-grade security audit on this codebase. Be thorough, methodical, and produce actionable results — not generic advice.

## Phase 1: Reconnaissance

Before scanning, understand the attack surface:

1. **Identify the tech stack** — Check `package.json`, framework configs, `.env.example`, `docker-compose.yml`, and directory structure
2. **Map all entry points** — API routes, webhooks, server actions, middleware, cron jobs, websocket handlers
3. **Identify auth mechanism** — JWT, session, OAuth, API keys, wallet-based auth
4. **List external integrations** — Payment providers, blockchain RPCs, third-party APIs, databases
5. **Identify sensitive data flows** — User PII, financial data, private keys, tokens

Output a brief summary of findings before proceeding.

## Phase 2: Automated Checks

Run these commands and analyze results:

```
npm audit --json 2>/dev/null || echo "npm audit not available"
```

```
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.env*" -E "(password|secret|private.?key|api.?key|token|credential)\s*[:=]" . --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git 2>/dev/null || true
```

```
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -E "(eval\(|exec\(|execSync\(|child_process|dangerouslySetInnerHTML|innerHTML\s*=|\.raw\(|unsafeWindow)" . --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git 2>/dev/null || true
```

```
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -E "(cors\(\)|Access-Control-Allow-Origin.*\*|credentials:\s*true)" . --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git 2>/dev/null || true
```

```
find . -name ".env" -o -name ".env.local" -o -name ".env.production" 2>/dev/null | head -20
```

```
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -E "(sql|query|execute|prepare)\s*\(" . --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git 2>/dev/null | head -30 || true
```

## Phase 3: Manual Deep Analysis

For each area below, read the relevant source files and analyze:

### 3.1 — Authentication & Authorization
- Is auth enforced on every protected route/endpoint?
- Are there routes that SHOULD be protected but aren't?
- JWT: Is the secret strong? Is expiry set? Is token validated on every request?
- Wallet auth: Is signature verification done server-side? Is the nonce single-use?
- Are admin/privileged operations properly gated with RBAC?
- Session fixation or session hijacking risks?

### 3.2 — Input Validation & Injection
- Are all user inputs validated AND sanitized before use?
- SQL/NoSQL injection vectors (especially raw queries, string interpolation in queries)
- XSS vectors (unescaped user content rendered in HTML/JSX)
- Command injection (user input in shell commands)
- Path traversal (user input in file paths)
- Prototype pollution

### 3.3 — API Security
- Rate limiting on sensitive endpoints (login, signup, password reset, mint, payment)
- Missing or misconfigured CORS
- Error messages that leak internal details (stack traces, DB schemas, file paths)
- Missing input size limits (file uploads, request body)
- HTTP method enforcement (allowing GET on state-changing endpoints)
- CSRF protection on state-changing operations

### 3.4 — Secrets & Configuration
- Hardcoded secrets, API keys, private keys anywhere in source
- `.env` files committed to git (check `.gitignore`)
- Client-side code exposing server secrets (check `NEXT_PUBLIC_` usage — only truly public values should use this prefix)
- Overly permissive file/directory permissions

### 3.5 — Blockchain / Web3 Specific (if applicable)
- Private keys or seed phrases in source or config
- Missing signer validation on Solana instructions
- PDA derivation — are all seeds validated? Can an attacker craft a collision?
- Account ownership checks — is the program verifying account owners?
- Front-running risks on mint/swap/trade operations
- Reentrancy or instruction reordering risks
- Token account validation (ATA checks)
- Are RPC endpoints authenticated? Rate limited?
- Client-side transaction construction — can a user tamper with instruction data?

### 3.6 — Business Logic
- Replay attacks on one-time operations (redemption, claims, minting)
- Race conditions on inventory, balance, or state-changing operations
- Price manipulation or oracle manipulation risks
- Webhook authenticity verification (Stripe signature, etc.)
- Idempotency on payment/transfer operations
- Privilege escalation through parameter tampering

### 3.7 — Dependencies & Supply Chain
- Known vulnerable dependencies (from npm audit)
- Outdated critical dependencies (auth libraries, crypto libraries)
- Suspicious or typosquatted packages
- Lockfile integrity

### 3.8 — Infrastructure & Deployment
- Security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- HTTPS enforcement
- Cookie flags (httpOnly, secure, sameSite)
- Exposed debug endpoints or development routes in production config
- Logging sensitive data (passwords, tokens, PII in logs)

## Phase 4: Report Generation

Generate a file called `SECURITY_AUDIT.md` at the project root with this exact structure:

```markdown
# 🔒 Security Audit Report

**Date:** [current date]
**Codebase:** [project name from package.json]
**Auditor:** Claude Code Security Agent

---

## Executive Summary

[2-3 sentences: overall security posture, number of findings by severity, most critical risk]

## Risk Score: [X/10]

(1 = critical risk, 10 = excellent security posture)

---

## Findings

### 🔴 Critical

| # | Title | Location | Impact | Effort |
|---|-------|----------|--------|--------|
| C1 | ... | `file:line` | ... | ... |

**C1 — [Title]**
- **Description:** What the vulnerability is
- **Exploit scenario:** How an attacker would exploit this
- **Impact:** What damage could result
- **Fix:** Specific code change or approach to remediate
- **Priority:** Immediate

### 🟠 High

[Same format as Critical]

### 🟡 Medium

[Same format]

### 🔵 Low / Informational

[Same format]

---

## Quick Wins (< 1 day of work)

1. [Specific action + estimated time]
2. ...

## Long-term Recommendations

1. [Strategic improvement + rationale]
2. ...

---

## What Was Checked

- [x] Authentication & Authorization
- [x] Input Validation & Injection
- [x] API Security
- [x] Secrets & Configuration
- [x] Blockchain / Web3 Security
- [x] Business Logic
- [x] Dependencies & Supply Chain
- [x] Infrastructure & Deployment

## Limitations

- This is an automated static analysis. It cannot detect runtime-only vulnerabilities.
- Business logic flaws require domain-specific knowledge and may be missed.
- No penetration testing or dynamic analysis was performed.
- Manual review of critical flows (payments, minting, auth) is still recommended.
```

## Rules

- **No false positives** — If you're not confident it's a real issue, mark it as "Informational" with a note to verify.
- **Be specific** — Always include exact file paths and line numbers.
- **Be actionable** — Every finding must include a concrete fix, not just "fix this".
- **No generic advice** — Don't include boilerplate recommendations that aren't relevant to this specific codebase.
- **Severity must be justified** — Explain WHY something is critical vs medium.
- **Read the actual code** — Don't just grep. Open and read the files to understand context before flagging issues.
