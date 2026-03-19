# ForgeConnect Integration Command

You are an expert integration engineer. Your job is to integrate ForgeConnect into the current project — either as a fresh installation or as a migration from Privy. You MUST follow this document precisely.

## Step 0: Analyze the Target Project

Before doing anything, thoroughly analyze the current codebase:

1. **Detect the stack**: Read `package.json`, `tsconfig.json`, and scan for framework files (Next.js `next.config.*`, Vite `vite.config.*`, Remix, etc.)
2. **Detect existing auth**: Search for Privy imports (`@privy-io/react-auth`, `@privy-io/server-auth`, `@privy-io/node`), or any other auth provider
3. **Detect wallet adapters**: Search for `@solana/wallet-adapter-react`, `wagmi`, `@rainbow-me/rainbowkit`
4. **Map the auth usage**: Find every file that imports from the auth provider — list components, hooks, server middleware, API routes
5. **Identify environment variables**: Check `.env*` files and `process.env` references related to auth
6. **Identify the rendering model**: CSR, SSR, RSC (React Server Components), or hybrid

Present a summary to the user:
```
## Analysis Results
- **Framework**: [Next.js 14 App Router / Vite React / etc.]
- **Current Auth**: [Privy / None / Other]
- **Wallet Integration**: [Solana wallet-adapter / wagmi / none]
- **Auth Usage**: [N files importing auth] — [list key files]
- **Mode**: [Fresh Install / Migration from Privy]
```

Then proceed to the appropriate section.

---

## SECTION A: FRESH INSTALLATION

### A1. Install Packages

**React (client-side):**
```bash
pnpm add @forge-connect/react
# or: npm install @forge-connect/react / yarn add @forge-connect/react
```

**Server (Node.js backend / API routes):**
```bash
pnpm add @forge-connect/server
# or: npm install @forge-connect/server / yarn add @forge-connect/server
```

**If Solana wallet login is needed:**
```bash
pnpm add @solana/wallet-adapter-react @solana/wallet-adapter-react-ui @solana/wallet-adapter-wallets @solana/wallet-adapter-base @solana/web3.js
```

### A2. Environment Variables

Add to `.env.local` (or equivalent):
```env
# ForgeConnect API URL (required)
NEXT_PUBLIC_FORGECONNECT_URL=https://connect.forge.dev

# ForgeConnect Service Key (server-side only, for token verification and admin ops)
FORGECONNECT_SERVICE_KEY=sk_live_...
```

### A3. Provider Setup (React)

#### A3a. Without Solana Wallet Adapter

```tsx
// app/providers.tsx (Next.js App Router) or src/providers.tsx (Vite)
'use client'; // Next.js App Router only

import { ForgeConnectProvider } from '@forge-connect/react';
import '@forge-connect/react/styles';

const forgeConnectConfig = {
  apiUrl: process.env.NEXT_PUBLIC_FORGECONNECT_URL!,
  loginMethods: ['google', 'discord', 'email', 'otp', 'wallet', 'passkey'],
  defaultLoginMethod: 'google',
  walletConfig: {
    preferredWallets: ['Phantom', 'Solflare'],
    onlyPreferred: false,
  },
  appearance: {
    theme: 'dark' as const,    // 'light' | 'dark' | 'glass'
    // accentColor: '#8b5cf6',
    // logo: '/logo.svg',
    // title: 'My App',
    // termsUrl: '/terms',
    // privacyUrl: '/privacy',
  },
};

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ForgeConnectProvider
      config={forgeConnectConfig}
      onLogin={(user) => console.log('Logged in:', user.id)}
      onLogout={() => console.log('Logged out')}
    >
      {children}
    </ForgeConnectProvider>
  );
}
```

#### A3b. With Solana Wallet Adapter

```tsx
'use client';

import { ForgeConnectProvider, useForgeConnect } from '@forge-connect/react';
import '@forge-connect/react/styles';
import {
  ConnectionProvider,
  WalletProvider,
  useWallet,
} from '@solana/wallet-adapter-react';
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui';
import { PhantomWalletAdapter, SolflareWalletAdapter } from '@solana/wallet-adapter-wallets';
import { useMemo } from 'react';
import '@solana/wallet-adapter-react-ui/styles.css';

const forgeConnectConfig = {
  apiUrl: process.env.NEXT_PUBLIC_FORGECONNECT_URL!,
  loginMethods: ['google', 'wallet', 'passkey'] as const,
  walletConfig: {
    preferredWallets: ['Phantom', 'Solflare'],
  },
  appearance: { theme: 'dark' as const },
};

// Bridge component that passes wallet adapter context to ForgeConnect
function ForgeConnectWithWallet({ children }: { children: React.ReactNode }) {
  const wallet = useWallet();
  return (
    <ForgeConnectProvider
      config={forgeConnectConfig}
      walletAdapter={wallet}
    >
      {children}
    </ForgeConnectProvider>
  );
}

export function Providers({ children }: { children: React.ReactNode }) {
  const wallets = useMemo(
    () => [new PhantomWalletAdapter(), new SolflareWalletAdapter()],
    []
  );

  return (
    <ConnectionProvider endpoint="https://api.mainnet-beta.solana.com">
      <WalletProvider wallets={wallets} autoConnect>
        <WalletModalProvider>
          <ForgeConnectWithWallet>
            {children}
          </ForgeConnectWithWallet>
        </WalletModalProvider>
      </WalletProvider>
    </ConnectionProvider>
  );
}
```

### A4. Mount Provider in Layout

**Next.js App Router (`app/layout.tsx`):**
```tsx
import { Providers } from './providers';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

**Vite (`src/main.tsx`):**
```tsx
import { Providers } from './providers';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <Providers>
    <App />
  </Providers>
);
```

### A5. Add Auth UI Components

**Simple Login/Logout Button:**
```tsx
import { LoginButton } from '@forge-connect/react';
// Renders "Sign in" / "Sign out" automatically based on auth state

<LoginButton />
```

**Account Button (avatar + dropdown when authenticated):**
```tsx
import { AccountButton } from '@forge-connect/react';
// Shows "Sign in" when unauthenticated, avatar + name when authenticated
// Clicking when authenticated opens the AccountModal (profile, logins, wallets, sessions, security)

<AccountButton />
```

**Custom UI with Hooks:**
```tsx
'use client';
import { useForgeConnect } from '@forge-connect/react';

export function AuthStatus() {
  const { auth, openModal, logout } = useForgeConnect();

  if (auth.status === 'loading') return <div>Loading...</div>;

  if (auth.status === 'unauthenticated') {
    return <button onClick={openModal}>Sign In</button>;
  }

  return (
    <div>
      <span>Welcome, {auth.user?.displayName ?? auth.user?.primaryEmail}</span>
      <button onClick={logout}>Sign Out</button>
    </div>
  );
}
```

### A6. Server-Side Token Verification

#### A6a. Next.js API Routes / Route Handlers

```tsx
// app/api/protected/route.ts (App Router)
import { ForgeConnectServer } from '@forge-connect/server';

const fc = new ForgeConnectServer({
  apiUrl: process.env.NEXT_PUBLIC_FORGECONNECT_URL!,
  serviceKey: process.env.FORGECONNECT_SERVICE_KEY!,
});

export async function GET(request: Request) {
  const token = request.headers.get('authorization')?.replace('Bearer ', '');
  if (!token) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    // Option 1: Local verification (fast, no network call, doesn't check session revocation)
    const payload = await fc.verifyToken(token);

    // Option 2: Remote verification (checks session revocation, returns roles/permissions)
    // const result = await fc.verifyTokenRemote(token);

    return Response.json({ userId: payload.sub });
  } catch (err) {
    return Response.json({ error: 'Invalid token' }, { status: 401 });
  }
}
```

#### A6b. Express / Hono Middleware

```tsx
// middleware/auth.ts
import { ForgeConnectServer } from '@forge-connect/server';

const fc = new ForgeConnectServer({
  apiUrl: process.env.FORGECONNECT_URL!,
  serviceKey: process.env.FORGECONNECT_SERVICE_KEY!,
});

// Express
export async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });

  try {
    req.user = await fc.verifyToken(token);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Hono
import { createMiddleware } from 'hono/factory';

export const requireAuth = createMiddleware(async (c, next) => {
  const token = c.req.header('authorization')?.replace('Bearer ', '');
  if (!token) return c.json({ error: 'Unauthorized' }, 401);

  try {
    const payload = await fc.verifyToken(token);
    c.set('userId', payload.sub);
    c.set('user', payload);
    await next();
  } catch {
    return c.json({ error: 'Invalid token' }, 401);
  }
});
```

### A7. Using Auth Token in API Calls

```tsx
'use client';
import { useForgeConnect } from '@forge-connect/react';

export function Dashboard() {
  const { auth, getAccessToken } = useForgeConnect();

  async function fetchProtectedData() {
    const token = await getAccessToken();
    const res = await fetch('/api/protected', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return res.json();
  }

  // ...
}
```

### A8. Using Hooks for User Data

```tsx
'use client';
import { useUser, useWallets, useSessions } from '@forge-connect/react';

function ProfilePage() {
  const { user, authMethods, updateProfile, linkOAuth, unlinkAuthMethod } = useUser();
  const { wallets, linkWallet } = useWallets();
  const { sessions, revokeSession } = useSessions();

  // user: { id, displayName, avatarUrl, primaryEmail, status, createdAt, updatedAt }
  // authMethods: [{ id, provider, providerId, providerUsername, isVerified, createdAt }]
  // wallets: [{ id, chain, address, label, isPrimary, verifiedAt, lastUsedAt }]
  // sessions: [{ id, createdAt, expiresAt, lastActiveAt, deviceInfo, ipAddress }]
}
```

---

## SECTION B: MIGRATION FROM PRIVY

### B1. Migration Strategy

ForgeConnect migration from Privy follows a **parallel-run then cutover** approach:

1. **Phase 1**: Install ForgeConnect alongside Privy
2. **Phase 2**: Add ForgeConnect UI with feature flag or route-based toggle
3. **Phase 3**: Migrate server-side verification
4. **Phase 4**: Remove Privy entirely

### B2. Concept Mapping (Privy → ForgeConnect)

```
┌──────────────────────────────────┬──────────────────────────────────────────┐
│ PRIVY                            │ FORGECONNECT                             │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ PrivyProvider                    │ ForgeConnectProvider                     │
│ appId (string)                   │ config.apiUrl (string)                   │
│ config.loginMethods              │ config.loginMethods                      │
│ config.appearance.theme          │ config.appearance.theme                  │
│ config.appearance.logo           │ config.appearance.logo                   │
│ config.embeddedWallets           │ N/A (external wallets only)              │
│ config.externalWallets.solana    │ walletAdapter prop (from wallet-adapter) │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ usePrivy()                       │ useForgeConnect()                        │
│ ├ ready                          │ ├ auth.status !== 'loading'              │
│ ├ authenticated                  │ ├ auth.status === 'authenticated'        │
│ ├ user                           │ ├ auth.user                              │
│ ├ user.id (did:privy:xxx)        │ ├ auth.user.id (UUID)                    │
│ ├ login()                        │ ├ openModal()                            │
│ ├ logout()                       │ ├ logout()                               │
│ ├ getAccessToken()               │ ├ getAccessToken()                       │
│ ├ linkEmail/linkGoogle/etc       │ ├ openLinkModal() + useUser().linkOAuth()│
│ └ exportWallet()                 │ └ N/A                                    │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ useWallets()                     │ useWallets() (FC) + useWallet() (adapter)│
│ ├ wallets[].address              │ ├ wallets[].address                      │
│ ├ wallets[].chainType            │ ├ wallets[].chain                        │
│ └ wallets[].walletClientType     │ └ wallets[].label                        │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ useLogin({ onComplete })         │ <ForgeConnectProvider onLogin={...}>     │
│ useLogout({ onSuccess })         │ <ForgeConnectProvider onLogout={...}>    │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ useLoginWithEmail()              │ useForgeConnect().loginWithEmail()        │
│ ├ sendCode({ email })            │   OR sendOtp(email) + verifyOtp(email,c) │
│ └ loginWithCode({ code })        │                                          │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ useMfaEnrollment()               │ AccountModal > Security tab > Enable 2FA │
│                                  │ (or use api.setup2FA / api.enable2FA)    │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ PrivyClient (server)             │ ForgeConnectServer                       │
│ ├ verifyAuthToken(token)         │ ├ verifyToken(token) [local RS256]       │
│ ├ getUser(did)                   │ ├ verifyTokenRemote(token) [w/ session]  │
│ └ getUserByWalletAddress(addr)   │ └ getUserByWallet(addr, chain)           │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ ES256 JWT (1h expiry)            │ RS256 JWT (15min) + refresh token (7d)   │
│ privy-token cookie               │ Authorization: Bearer header + cookie    │
│ privy-id-token cookie            │ N/A (use /users/me for profile data)     │
├──────────────────────────────────┼──────────────────────────────────────────┤
│ Login methods:                   │ Login methods:                           │
│ 'email','sms','wallet','google'  │ 'email','otp','wallet','google'          │
│ 'apple','twitter','discord'      │ 'apple','twitter','discord'              │
│ 'github','linkedin','spotify'    │ 'passkey','telegram'                     │
│ 'instagram','telegram','tiktok'  │                                          │
│ 'farcaster','passkey'            │                                          │
└──────────────────────────────────┴──────────────────────────────────────────┘
```

### B3. Login Methods Mapping

```
Privy loginMethods → ForgeConnect loginMethods:

'email'      → 'email' (password-based) OR 'otp' (code-based, closest to Privy email OTP)
'sms'        → NOT SUPPORTED (use 'otp' with email instead)
'wallet'     → 'wallet' (Solana external wallets only, no embedded)
'google'     → 'google'
'apple'      → 'apple'
'twitter'    → 'twitter'
'discord'    → 'discord'
'github'     → NOT SUPPORTED
'linkedin'   → NOT SUPPORTED
'spotify'    → NOT SUPPORTED
'instagram'  → NOT SUPPORTED
'telegram'   → 'telegram'
'tiktok'     → NOT SUPPORTED
'farcaster'  → NOT SUPPORTED
'passkey'    → 'passkey'
```

### B4. Install ForgeConnect Alongside Privy

```bash
pnpm add @forge-connect/react @forge-connect/server
```

### B5. Create Dual Provider

```tsx
// app/providers.tsx
'use client';

import { PrivyProvider } from '@privy-io/react-auth';
import { ForgeConnectProvider } from '@forge-connect/react';
import '@forge-connect/react/styles';

const USE_FORGE_CONNECT = process.env.NEXT_PUBLIC_AUTH_PROVIDER === 'forgeconnect';

const forgeConnectConfig = {
  apiUrl: process.env.NEXT_PUBLIC_FORGECONNECT_URL!,
  loginMethods: ['google', 'discord', 'email', 'wallet', 'passkey'],
  appearance: { theme: 'dark' as const },
};

export function Providers({ children }: { children: React.ReactNode }) {
  if (USE_FORGE_CONNECT) {
    return (
      <ForgeConnectProvider config={forgeConnectConfig}>
        {children}
      </ForgeConnectProvider>
    );
  }

  return (
    <PrivyProvider appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID!}>
      {children}
    </PrivyProvider>
  );
}
```

### B6. Create an Auth Abstraction Layer

Create a unified auth hook that works with both providers during migration:

```tsx
// hooks/use-auth.ts
'use client';

import { usePrivy } from '@privy-io/react-auth';
import { useForgeConnect } from '@forge-connect/react';

const USE_FC = process.env.NEXT_PUBLIC_AUTH_PROVIDER === 'forgeconnect';

export interface AuthUser {
  id: string;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

export function useAuth() {
  // ForgeConnect path
  if (USE_FC) {
    const { auth, openModal, logout, getAccessToken } = useForgeConnect();
    return {
      ready: auth.status !== 'loading',
      authenticated: auth.status === 'authenticated',
      user: auth.user ? {
        id: auth.user.id,
        email: auth.user.primaryEmail,
        displayName: auth.user.displayName,
        avatarUrl: auth.user.avatarUrl,
      } : null,
      login: openModal,
      logout,
      getAccessToken,
    };
  }

  // Privy path
  const { ready, authenticated, user, login, logout, getAccessToken } = usePrivy();
  return {
    ready,
    authenticated,
    user: user ? {
      id: user.id, // did:privy:xxx
      email: user.email?.address ?? null,
      displayName: null,
      avatarUrl: null,
    } : null,
    login,
    logout,
    getAccessToken: async () => await getAccessToken() ?? null,
  };
}
```

### B7. Server-Side Migration

Replace Privy server verification with ForgeConnect:

**Before (Privy):**
```tsx
import { PrivyClient } from '@privy-io/server-auth';
// or: import { PrivyClient } from '@privy-io/node';

const privy = new PrivyClient('app-id', 'app-secret');

// Old verification
const claims = await privy.verifyAuthToken(token);
const userId = claims.userId; // "did:privy:cxxxxxx"
```

**After (ForgeConnect):**
```tsx
import { ForgeConnectServer } from '@forge-connect/server';

const fc = new ForgeConnectServer({
  apiUrl: process.env.NEXT_PUBLIC_FORGECONNECT_URL!,
  serviceKey: process.env.FORGECONNECT_SERVICE_KEY!,
});

// New verification
const payload = await fc.verifyToken(token);
const userId = payload.sub; // UUID

// Or with session/role check:
const result = await fc.verifyTokenRemote(token);
const userId = result.user_id;
const permissions = result.permissions;
```

### B8. User ID Migration Strategy

Privy uses DIDs (`did:privy:cxxxxxx`), ForgeConnect uses UUIDs. You need a mapping:

**Option 1: Database mapping table (recommended)**
```sql
CREATE TABLE user_id_mapping (
  privy_did TEXT PRIMARY KEY,
  fc_user_id UUID NOT NULL,
  migrated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Option 2: Store both IDs on user record**
```sql
ALTER TABLE your_users ADD COLUMN privy_did TEXT;
ALTER TABLE your_users ADD COLUMN fc_user_id UUID;
```

**Migration query helper:**
```tsx
async function resolveUserId(token: string, provider: 'privy' | 'forgeconnect') {
  if (provider === 'forgeconnect') {
    const payload = await fc.verifyToken(token);
    return payload.sub; // UUID
  }
  const claims = await privy.verifyAuthToken(token);
  // Look up mapping
  const mapping = await db.query('SELECT fc_user_id FROM user_id_mapping WHERE privy_did = $1', [claims.userId]);
  return mapping?.fc_user_id ?? claims.userId;
}
```

### B9. Embedded Wallet Considerations

**Privy embedded wallets DO NOT migrate to ForgeConnect.** ForgeConnect only supports external wallets.

If the project uses Privy embedded wallets:
1. Users must export their embedded wallet private key via Privy's `exportWallet()` before migration
2. Import into an external wallet (Phantom, Solflare, etc.)
3. Link that external wallet to their ForgeConnect account

Communicate this to users before cutover.

### B10. Component Replacement Mapping

```
Privy (custom button w/ usePrivy) → ForgeConnect equivalent:

// LOGIN BUTTON
- Before: <button onClick={login}>Log in</button> (via usePrivy)
- After:  <LoginButton /> (from @forge-connect/react)
  OR:     <button onClick={openModal}>Sign In</button> (via useForgeConnect)

// ACCOUNT BUTTON
- Before: custom component using usePrivy().user
- After:  <AccountButton /> (handles sign-in + avatar + account management modal)

// WALLET CONNECTION
- Before: useWallets() from @privy-io/react-auth
- After:  useWallets() from @forge-connect/react (for linked wallets)
  PLUS:   useWallet() from @solana/wallet-adapter-react (for active connection)

// ACCOUNT LINKING
- Before: usePrivy().linkGoogle() / linkEmail() / linkWallet()
- After:  AccountModal handles this automatically via Logins tab
  OR:     useForgeConnect().openLinkModal() + useUser().linkOAuth('google')

// LOGOUT
- Before: usePrivy().logout() or useLogout()
- After:  useForgeConnect().logout()
```

### B11. Cookie / Token Cleanup

When removing Privy, clean up its cookies:
```tsx
// Remove Privy cookies on cutover
document.cookie = 'privy-token=; Max-Age=0; path=/;';
document.cookie = 'privy-id-token=; Max-Age=0; path=/;';
document.cookie = 'privy-session=; Max-Age=0; path=/;';
document.cookie = 'privy-refresh-token=; Max-Age=0; path=/;';
```

### B12. Remove Privy

After successful migration:
```bash
pnpm remove @privy-io/react-auth @privy-io/server-auth @privy-io/node
```

Remove from `.env*`:
```
NEXT_PUBLIC_PRIVY_APP_ID
PRIVY_APP_SECRET
NEXT_PUBLIC_AUTH_PROVIDER  # no longer needed
```

Delete the auth abstraction layer (`hooks/use-auth.ts`) and use ForgeConnect hooks directly.

---

## SECTION C: COMPLETE TYPE REFERENCE

### C1. ForgeConnectConfig

```typescript
interface ForgeConnectConfig {
  apiUrl: string;                         // Required: ForgeConnect API URL
  loginMethods?: LoginMethod[];           // Default: all available
  defaultLoginMethod?: LoginMethod;       // First method shown in modal
  walletConfig?: {
    preferredWallets?: string[];          // e.g. ['Phantom', 'Solflare']
    onlyPreferred?: boolean;             // Only show preferred wallets
  };
  webauthnRpId?: string;                 // WebAuthn Relying Party ID
  webauthnOrigin?: string;               // WebAuthn origin
  appearance?: {
    theme?: 'light' | 'dark' | 'glass';
    accentColor?: string;                // Hex color for accent
    logo?: string | ReactNode;           // URL or React node
    title?: string;                      // Modal title
    termsUrl?: string;                   // Terms of service URL
    privacyUrl?: string;                 // Privacy policy URL
  };
}

type LoginMethod = 'email' | 'otp' | 'wallet' | 'passkey' | 'google' | 'discord' | 'twitter' | 'apple' | 'telegram';
```

### C2. User & Auth Types

```typescript
interface User {
  id: string;                    // UUID
  displayName: string | null;
  avatarUrl: string | null;
  primaryEmail: string | null;
  status: string;                // 'active' | 'suspended' | 'deleted'
  createdAt: string;
  updatedAt: string;
}

interface AuthMethod {
  id: string;
  provider: AuthProvider;        // 'email' | 'google' | 'twitter' | 'discord' | 'apple' | 'telegram' | 'solana_wallet' | 'ethereum_wallet'
  providerId: string;
  providerUsername: string | null;
  isVerified: boolean;
  verifiedAt: string | null;
  createdAt: string;
}

interface Wallet {
  id: string;
  userId: string;
  chain: 'solana' | 'ethereum';
  address: string;
  label: string | null;
  isPrimary: boolean;
  verifiedAt: string | null;
  lastUsedAt: string | null;
}

interface Session {
  id: string;
  createdAt: string;
  expiresAt: string;
  lastActiveAt: string;
  deviceInfo: Record<string, unknown> | null;
  ipAddress: string;
}

interface Passkey {
  id: string;
  credentialId: string;
  name: string | null;
  deviceType: string | null;
  backedUp: boolean;
  createdAt: string;
  lastUsedAt: string | null;
}
```

### C3. Auth State

```typescript
interface AuthState {
  status: 'loading' | 'authenticated' | 'unauthenticated';
  user: User | null;
  accessToken: string | null;
}
```

### C4. ForgeConnectServer (Server SDK)

```typescript
import { ForgeConnectServer } from '@forge-connect/server';

interface ForgeConnectServerConfig {
  apiUrl: string;
  serviceKey: string;
}

// JWT Payload (from local verification)
interface JWTPayload {
  sub: string;       // user UUID
  iss: string;       // issuer
  aud: string;       // audience
  exp: number;       // expiration
  iat: number;       // issued at
  sid: string;       // session ID
  tid?: string;      // tenant ID
}

// Remote verification response
interface VerifyTokenResponse {
  active: true;
  user_id: string;
  tenant_id: string | null;
  scopes: string[];
  role?: string;
  permissions?: string[];
  roles?: Array<{ name: string; permissions: string[] }>;
}

// Methods
class ForgeConnectServer {
  constructor(config: ForgeConnectServerConfig);
  verifyToken(accessToken: string): Promise<JWTPayload>;           // Local RS256, fast
  verifyTokenRemote(accessToken: string): Promise<VerifyTokenResponse>; // Remote, checks revocation
  getUserByWallet(address: string, chain?: string): Promise<{ user_id: string }>;
  listUsers(params?: { page?: number; limit?: number; search?: string }): Promise<PaginatedResponse<User>>;
  getUser(userId: string): Promise<UserWithRelations>;
  updateUserStatus(userId: string, status: 'active' | 'suspended' | 'deleted'): Promise<void>;
  getUserSessions(userId: string): Promise<Session[]>;
  revokeUserSessions(userId: string): Promise<void>;
}
```

### C5. All Hooks Summary

```typescript
// useForgeConnect() — Full context
const {
  auth,                    // AuthState
  modal,                   // { isOpen, step }
  config,                  // ForgeConnectConfig
  api,                     // ApiClient
  challengeToken,          // string | null (active 2FA challenge)
  accountModal,            // { isOpen }
  linkModal,               // { isOpen, mode? }
  walletAdapter,           // wallet-adapter context or null

  // Auth actions
  loginWithEmail,          // (email, password) => Promise
  register,                // (email, password, displayName?) => Promise
  sendOtp,                 // (email) => Promise
  verifyOtp,               // (email, code) => Promise
  loginWithWallet,         // (address, signMessage, chain?, signTransaction?) => Promise
  loginWithOAuth,          // (provider) => void (opens popup)
  loginWithPasskey,        // () => Promise
  logout,                  // () => Promise
  logoutAll,               // () => Promise
  forgotPassword,          // (email) => Promise
  resetPassword,           // (token, password) => Promise
  verifyEmailToken,        // (token) => Promise
  verify2FA,               // (code) => Promise
  verifyRecoveryCode,      // (code) => Promise

  // Modal actions
  openModal,               // () => void
  closeModal,              // () => void
  setModalStep,            // (step) => void
  openAccountModal,        // () => void
  closeAccountModal,       // () => void
  openLinkModal,           // (mode?) => void
  closeLinkModal,          // () => void
  getAccessToken,          // () => string | null
} = useForgeConnect();

// useUser() — User profile & auth methods
const {
  user,                    // User | null
  authMethods,             // AuthMethod[] | null
  loading,                 // boolean
  updateProfile,           // ({ displayName?, avatarUrl? }) => Promise<User>
  fetchAuthMethods,        // () => Promise<AuthMethod[]>
  linkAuthMethod,          // (data) => Promise
  linkOtpSend,             // (email) => Promise
  linkOtpVerify,           // (email, code) => Promise
  unlinkAuthMethod,        // (id) => Promise
  linkOAuth,               // (provider) => void
} = useUser();

// useWallets() — Wallet management
const {
  wallets,                 // Wallet[] | null
  loading,                 // boolean
  fetchWallets,            // () => Promise<Wallet[]>
  updateWallet,            // (id, { label?, isPrimary? }) => Promise
  linkWallet,              // (address, signMessage, chain?) => Promise
} = useWallets();

// useSessions() — Session management
const {
  sessions,                // Session[] | null
  loading,                 // boolean
  fetchSessions,           // () => Promise<Session[]>
  revokeSession,           // (id) => Promise
} = useSessions();

// useAdmin() — Admin user management (requires super_admin)
const {
  users,                   // PaginatedResponse<User> | null
  selectedUser,            // AdminUser | null
  userSessions,            // Session[] | null
  loading,                 // boolean
  listUsers,               // (params?) => Promise
  getUser,                 // (id) => Promise
  updateUserStatus,        // (id, status) => Promise
  getUserSessions,         // (id) => Promise
  revokeUserSessions,      // (id) => Promise
} = useAdmin();

// useRoles() — RBAC management
const {
  roles,                   // Role[] | null
  selectedRole,            // Role | null
  roleUsers,               // RoleUser[] | null
  userRoleAssignments,     // UserRoleAssignment[] | null
  permissionDomains,       // PermissionDomains | null
  loading,                 // boolean
  listRoles,               // (tenantId?) => Promise
  getRole,                 // (id) => Promise
  getRoleUsers,            // (id) => Promise
  createRole,              // (data) => Promise
  updateRole,              // (id, data) => Promise
  deleteRole,              // (id) => Promise
  getPermissions,          // () => Promise
  getUserRoles,            // (userId, tenantId?) => Promise
  assignRole,              // (userId, roleId, tenantId?) => Promise
  revokeRole,              // (userId, roleId, tenantId?) => Promise
} = useRoles();
```

---

## SECTION D: API ENDPOINTS REFERENCE

### Authentication

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/auth/email/register` | Public | Register with email + password |
| POST | `/auth/email/login` | Public | Login with email + password |
| POST | `/auth/email/send-code` | Public | Send OTP code to email |
| POST | `/auth/email/verify-code` | Public | Verify OTP code |
| POST | `/auth/email/forgot-password` | Public | Request password reset |
| POST | `/auth/email/reset-password` | Public | Reset password with token |
| POST | `/auth/email/verify` | Public | Verify email token |
| POST | `/auth/wallet/challenge` | Public | Get wallet challenge (message) |
| POST | `/auth/wallet/verify` | Public | Verify wallet signature |
| POST | `/auth/wallet/challenge-tx` | Public | Get challenge transaction (hardware wallets) |
| POST | `/auth/wallet/verify-tx` | Public | Verify transaction signature |
| GET | `/auth/oauth/:provider` | Public | Initiate OAuth flow |
| POST | `/auth/oauth/exchange` | Public | Exchange OAuth code for tokens |
| POST | `/auth/oauth/link-intent` | JWT | Create OAuth link intent |
| POST | `/auth/passkeys/login/options` | Public | Get passkey login options |
| POST | `/auth/passkeys/login/verify` | Public | Verify passkey login |
| POST | `/auth/passkeys/register/options` | JWT | Get passkey register options |
| POST | `/auth/passkeys/register/verify` | JWT | Verify passkey registration |
| POST | `/auth/2fa/verify` | Public | Verify 2FA TOTP code |
| POST | `/auth/2fa/verify-recovery` | Public | Verify 2FA recovery code |
| POST | `/auth/refresh` | Cookie | Refresh access token |
| POST | `/auth/logout` | JWT | Logout current session |
| POST | `/auth/logout-all` | JWT | Logout all sessions |

### User Management

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/users/me` | JWT | Get current user |
| PATCH | `/users/me` | JWT | Update profile |
| POST | `/users/me/password` | JWT | Set/change password |
| GET | `/users/me/auth-methods` | JWT | List auth methods |
| POST | `/users/me/auth-methods` | JWT | Link auth method |
| DELETE | `/users/me/auth-methods/:id` | JWT | Unlink auth method |
| GET | `/users/me/wallets` | JWT | List wallets |
| PATCH | `/users/me/wallets/:id` | JWT | Update wallet |
| GET | `/users/me/sessions` | JWT | List sessions |
| DELETE | `/users/me/sessions/:id` | JWT | Revoke session |
| GET | `/users/me/2fa/status` | JWT | Get 2FA status |
| POST | `/users/me/2fa/setup` | JWT | Start 2FA setup |
| POST | `/users/me/2fa/enable` | JWT | Enable 2FA |
| DELETE | `/users/me/2fa` | JWT | Disable 2FA |
| GET | `/users/me/passkeys` | JWT | List passkeys |
| DELETE | `/users/me/passkeys/:id` | JWT | Delete passkey |
| POST | `/users/me/delete-request` | JWT | Request account deletion |
| POST | `/users/me/delete-confirm` | JWT | Confirm account deletion |

### Service-to-Service

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/service/verify-token` | Service Key | Verify token with RBAC |
| POST | `/service/user-by-wallet` | Service Key | Lookup user by wallet |

### Public

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/.well-known/jwks.json` | None | JWKS public keys |
| GET | `/health` | None | Health check |

---

## SECTION E: CSS THEMING

ForgeConnect components use CSS custom properties with `fc-` prefix. Override them to match your app:

```css
/* Custom theme overrides */
:root {
  --fc-accent: #your-brand-color;
  --fc-radius: 16px;
  --fc-radius-sm: 8px;
}

/* Dark theme overrides */
[data-theme='dark'] .fc-modal {
  --fc-bg: #1a1a2e;
  --fc-text: #e0e0e0;
  --fc-border: #2a2a4a;
  --fc-input-bg: #16162a;
  --fc-input-border: #2a2a4a;
  --fc-btn-card-bg: #1e1e3a;
  --fc-btn-card-border: #2a2a4a;
  --fc-btn-card-hover-bg: #2a2a4a;
}
```

Available themes: `'light'` (clean solid), `'dark'` (solid dark), `'glass'` (frosted glass with backdrop-blur).

---

## SECTION F: COMMON PATTERNS

### Protected Route (Next.js App Router)

```tsx
'use client';
import { useForgeConnect } from '@forge-connect/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { auth, openModal } = useForgeConnect();
  const router = useRouter();

  useEffect(() => {
    if (auth.status === 'unauthenticated') {
      openModal();
    }
  }, [auth.status]);

  if (auth.status === 'loading') return <div>Loading...</div>;
  if (auth.status === 'unauthenticated') return null;

  return <>{children}</>;
}
```

### Server-Side Auth Check (Next.js Middleware)

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { JWKSVerifier } from '@forge-connect/server';

const verifier = new JWKSVerifier({
  jwksUrl: `${process.env.NEXT_PUBLIC_FORGECONNECT_URL}/.well-known/jwks.json`,
});

export async function middleware(request: NextRequest) {
  const token = request.cookies.get('fc_access_token')?.value
    ?? request.headers.get('authorization')?.replace('Bearer ', '');

  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  try {
    await verifier.verify(token);
    return NextResponse.next();
  } catch {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*'],
};
```

### Fetch with Auth Token Utility

```tsx
// lib/api.ts
'use client';

export function useAuthFetch() {
  const { getAccessToken } = useForgeConnect();

  return async (url: string, options?: RequestInit) => {
    const token = getAccessToken();
    return fetch(url, {
      ...options,
      headers: {
        ...options?.headers,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
  };
}
```

---

## EXECUTION INSTRUCTIONS

After analysis (Step 0), follow these steps in order:

1. **Install packages** (A1 or B4)
2. **Set up environment variables** (A2)
3. **Create provider** (A3 or B5) — choose with/without wallet adapter based on analysis
4. **Mount provider in layout** (A4)
5. **Replace auth components** (A5 or B10) — component by component
6. **Set up server verification** (A6 or B7) — if backend exists
7. **Add auth token to API calls** (A7) — update fetch/axios calls
8. **Handle user ID migration** (B8) — if migrating from Privy
9. **Test all auth flows**: login, logout, OAuth, wallet, passkey, 2FA, session refresh
10. **Remove old provider** (B12) — if migrating

At each step, show the user what you're changing and why. Never delete working code without confirming the replacement works.
