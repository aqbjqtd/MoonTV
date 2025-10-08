# MoonTV Project Guide

> 本文档定义 MoonTV 项目的特定架构约束和开发规则。
> 通用开发规范由 SuperClaude 框架提供（~/.claude/CLAUDE.md）。

## 🎯 项目定位与版本管理策略

### 项目定位

**重要说明**: 本项目是专门用于 Docker 镜像制作的版本，与上游仓库保持独立管理。

### 双版本系统

本项目采用双版本管理系统：

#### 1. 项目开发版本 (Docker 构建版本)
- **用途**: 标识 Docker 镜像制作的开发状态
- **格式**: v4.0.0, v4.1.0 等 (主版本递增)
- **管理**: Git 标签管理
- **推送**: 仅推送标签到远程仓库作为备份

#### 2. 应用软件版本 (与上游同步)
- **用途**: 标识实际软件版本，用于版本更新检查
- **格式**: v3.2.0 (与上游仓库完全一致)
- **管理**: VERSION.txt 和 src/lib/version.ts
- **检查**: 主页通过远程版本检查显示更新状态

### 版本文件说明

| 文件/标签 | 版本类型 | 用途 | 当前值 |
|----------|----------|------|--------|
| Git 标签 | 项目版本 | Docker 镜像版本标识 | v4.0.0 |
| VERSION.txt | 应用版本 | 软件版本标识 | v3.2.0 |
| src/lib/version.ts | 应用版本 | 代码中版本常量 | v3.2.0 |

### 推送策略

**代码管理**:
- ❌ **不推送代码到远程仓库** (保持与上游一致)
- ✅ 本地仓库管理所有开发内容

**标签管理**:
- ✅ **推送项目版本标签到远程仓库** (备份用)
- ✅ 推送所有历史标签作为完整备份

### 工作流程

1. **Docker 镜像制作**:
   ```bash
   # 使用项目版本标识镜像
   docker build -t moontv:v4.0.0 .
   ```

2. **项目版本更新**:
   ```bash
   # 创建新的项目版本标签
   git tag -a v4.1.0 -m "项目版本 v4.1.0"

   # 推送标签备份
   git push origin v4.1.0
   ```

3. **应用版本同步**:
   - 持续跟踪上游仓库版本
   - 保持应用版本与上游一致
   - 确保主页版本更新检查正常工作

### 版本同步原则

- **应用版本**: 严格与上游仓库保持一致
- **项目版本**: 独立管理，标识 Docker 构建改进
- **更新检查**: 主页通过应用版本检查显示是否有更新

## 项目概述

MoonTV 是基于 Next.js 14 App Router 的跨平台视频聚合播放器。聚合 20+ 视频 API 源（Apple CMS V10 格式），支持多种存储后端，可部署到 Docker、Vercel、Netlify、Cloudflare Pages。

**核心特性**：

- 🔌 **插件化存储**：localstorage/redis/upstash/d1 可切换
- 🔄 **双模配置**：静态 config.json + 动态数据库配置
- 🔒 **双模认证**：密码模式 + 用户名/密码/HMAC 模式
- 🌊 **流式搜索**：WebSocket 实时多源并行搜索
- ⚡ **Edge Runtime**：所有 API 路由支持边缘计算

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
