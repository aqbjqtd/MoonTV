# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoonTV is a cross-platform video aggregation player built with Next.js 14 App Router. It aggregates content from 20+ video API sources (Apple CMS V10 format), supports multiple storage backends, and can be deployed to Docker, Vercel, Netlify, or Cloudflare Pages.

## Development Commands

```bash
# Development
pnpm dev              # Start dev server with manifest/runtime generation (0.0.0.0:3000)
pnpm build            # Production build with manifest/runtime generation
pnpm start            # Start production server

# Code Quality
pnpm lint             # Run ESLint on src/
pnpm lint:fix         # Auto-fix ESLint + Prettier
pnpm typecheck        # TypeScript type checking (no emit)
pnpm format           # Format all files with Prettier

# Testing
pnpm test             # Run all tests
pnpm test:watch       # Watch mode for development

# Utilities
pnpm gen:manifest     # Generate PWA manifest.json
pnpm gen:runtime      # Generate runtime config from config.json

# Cloudflare Pages
pnpm pages:build      # Build for Cloudflare Pages deployment
```

## Architecture Overview

### Storage Abstraction Layer (Critical)

The application uses a **pluggable storage system** via the `IStorage` interface. Storage type is determined by `NEXT_PUBLIC_STORAGE_TYPE` environment variable:

**Storage Implementations:**
- `localstorage` (default): Browser-based, no server persistence
- `redis`: Native Redis (Docker only) - `src/lib/redis.db.ts`
- `upstash`: HTTP-based Redis (Serverless) - `src/lib/upstash.db.ts`
- `d1`: Cloudflare D1 SQLite - `src/lib/d1.db.ts`

**Key Files:**
- `src/lib/types.ts` - IStorage interface definition
- `src/lib/db.ts` - Storage factory and DbManager wrapper
- `src/lib/db.client.ts` - Client-side storage abstraction

**Important:** When adding features that persist data (favorites, play records, search history), always use `DbManager` methods, never access storage implementations directly.

### Configuration System

Dual-mode configuration based on storage type:

**localstorage mode:**
- Static config from `config.json` (editable, read at startup)
- Environment variables for site settings

**Database modes (redis/upstash/d1):**
- Dynamic config stored in database (`AdminConfig` type)
- Managed via `/admin` interface
- Config merges `config.json` sources with DB customizations
- `src/lib/config.ts` handles the complex merge logic

**Key concept:** `config.json` defines baseline API sources and categories. In DB mode, these merge with user customizations stored in `AdminConfig.SourceConfig` and `AdminConfig.CustomCategories`.

### Authentication & Middleware

**Two auth modes** based on storage type:

**localstorage mode:**
- Password-only auth (no username)
- Password stored in cookie, validated in middleware
- Controlled by `PASSWORD` environment variable

**Database modes:**
- Username/password with HMAC signature
- Signature validated in middleware (`src/middleware.ts`)
- Role-based access: `owner` (USERNAME env var) → `admin` → `user`

**Protected routes** (configured in `src/middleware.ts` config.matcher):
- `/admin/*` and `/api/admin/*` require admin/owner role
- `/api/favorites`, `/api/playrecords`, `/api/searchhistory` require login

### Video Search Architecture

Multi-source parallel search with streaming support:

**Standard Search (`/api/search`):**
- Parallel requests to all enabled API sources
- Results aggregated and deduplicated by title
- Caching via storage layer

**Streaming Search (`/api/search/ws`):**
- WebSocket-based progressive results
- Uses `searchFromApiStream` from `src/lib/downstream.ts`
- Each source streams results as they arrive
- Client receives real-time updates

**Core search flow:**
1. `src/lib/config.ts` - `getAvailableApiSites()` returns enabled sources
2. `src/lib/downstream.ts` - `searchFromApiStream()` handles parallel fetching
3. Results mapped to `SearchResult` interface via `mapItemToResult()`
4. Episode parsing with `parseEpisodes()` for m3u8 URLs

### Runtime Configuration Injection

**Critical pattern:** Server-side config injected into client at build time:

1. `scripts/generate-runtime.js` - Reads `config.json` and generates `src/lib/runtime.ts`
2. `src/app/layout.tsx` - Injects `window.RUNTIME_CONFIG` for client access
3. Client components read from `window.RUNTIME_CONFIG` instead of env vars

**Why:** Allows dynamic config updates without rebuild (Docker), consistent client/server config, Serverless-friendly.

### Edge Runtime

All API routes use `export const runtime = 'edge'` for:
- Fast cold starts (<100ms)
- Global distribution
- Cloudflare Workers / Vercel Edge compatibility

**Limitation:** No Node.js fs/path in edge runtime (use conditional imports for Docker env).

## Key Development Patterns

### Adding a New API Endpoint

1. Create route file in `src/app/api/[name]/route.ts`
2. Add `export const runtime = 'edge'`
3. For auth-required endpoints, add to middleware matcher
4. Use `DbManager` for data persistence
5. Use `getConfig()` for configuration access

### Adding a Storage Feature

1. Add method to `IStorage` interface in `src/lib/types.ts`
2. Implement in all storage backends (redis.db.ts, upstash.db.ts, d1.db.ts)
3. Add convenience method to `DbManager` in `src/lib/db.ts`
4. Client-side: use client abstraction in `src/lib/db.client.ts`

### Modifying Config Schema

1. Update `AdminConfig` type in `src/lib/admin.types.ts`
2. Update merge logic in `src/lib/config.ts` → `getConfig()`
3. Update admin UI in `src/app/admin/page.tsx`
4. For localstorage mode: update `config.json` structure

### Adding a Video Source

**localstorage mode:** Edit `config.json` directly

**Database modes:** Use admin interface at `/admin` or:
1. Access `AdminConfig.SourceConfig` array
2. Add object: `{ key, name, api, detail?, from: 'custom', disabled: false }`
3. Save via `DbManager.saveAdminConfig()`

## Environment Variables

**Required:**
- `PASSWORD` - Auth password (all modes)

**Storage Selection:**
- `NEXT_PUBLIC_STORAGE_TYPE` - `localstorage` | `redis` | `upstash` | `d1`

**Storage-specific:**
- `REDIS_URL` - For redis mode
- `UPSTASH_URL`, `UPSTASH_TOKEN` - For upstash mode
- Cloudflare D1 binding via `process.env.DB` (Pages only)

**Site Config (optional, DB modes override):**
- `NEXT_PUBLIC_SITE_NAME` - Site display name
- `USERNAME` - Owner account (non-localstorage)
- `NEXT_PUBLIC_ENABLE_REGISTER` - Allow public registration
- `NEXT_PUBLIC_SEARCH_MAX_PAGE` - Max pages per source search

**Deployment-specific:**
- `DOCKER_ENV=true` - Enables dynamic config.json loading
- `NODE_ENV=production` - Production mode

## Testing Notes

- Run single test: `pnpm test <file-pattern>`
- Mock storage: Import mocked `getStorage` in tests
- Router mocking: Use `next-router-mock` for navigation tests

## Deployment-Specific Behaviors

**Docker:**
- Reads `config.json` dynamically at runtime (`DOCKER_ENV=true`)
- Supports all storage backends
- Standalone output mode

**Vercel/Netlify:**
- Static `config.json` compiled into bundle
- Best with `upstash` storage
- Edge runtime

**Cloudflare Pages:**
- Build with `pnpm pages:build`
- Output to `.vercel/output/static`
- Requires `nodejs_compat` flag
- Use `d1` storage with D1 database binding

## Critical Code Locations

- **Storage factory:** `src/lib/db.ts` → `getStorage()`
- **Config merge logic:** `src/lib/config.ts` → `getConfig()`
- **Auth validation:** `src/middleware.ts`
- **Search orchestration:** `src/lib/downstream.ts`
- **API route pattern:** `src/app/api/*/route.ts`
- **Type definitions:** `src/lib/types.ts`, `src/lib/admin.types.ts`

## Common Pitfalls

1. **Storage abstraction bypass:** Never import storage implementations directly, always use `DbManager`
2. **Config.json in DB mode:** Changes to `config.json` require restart or admin config reset
3. **Edge runtime limits:** Cannot use Node.js fs/path directly (use conditional imports)
4. **Middleware auth skip:** Update `shouldSkipAuth()` when adding public routes
5. **localstorage vs DB mode:** Features behave differently (static vs dynamic config)
