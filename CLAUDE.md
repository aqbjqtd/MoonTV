# MoonTV Project Guide

> 本文档定义 MoonTV 项目的特定架构约束和开发规则。
> 通用开发规范由 SuperClaude 框架提供（~/.claude/CLAUDE.md）。

## 🎯 项目定位与版本管理策略

### 项目定位

**重要说明**: 本项目是专门用于 Docker 镜像制作的版本，与上游仓库保持独立管理。

### 版本管理系统

本项目采用统一版本管理策略：

#### 1. 项目开发版本 (Docker 构建版本)

- **用途**: 标识 Docker 镜像制作的开发状态
- **格式**: dev (统一开发版本标识)
- **管理**: Git 标签管理
- **推送**: 仅推送标签到远程仓库作为备份

#### 2. 应用软件版本 (与上游同步)

- **用途**: 标识实际软件版本，用于版本更新检查
- **格式**: v3.2.0 (与上游仓库完全一致)
- **管理**: VERSION.txt 和 src/lib/version.ts
- **检查**: 主页通过远程版本检查显示更新状态

### 版本文件说明

| 文件/标签          | 版本类型   | 用途               | 当前值           |
| ------------------ | ---------- | ------------------ | ---------------- |
| Git 标签           | 项目版本   | 开发环境版本标识   | dev              |
| VERSION.txt        | 应用版本   | 软件版本标识       | v3.2.0           |
| src/lib/version.ts | 应用版本   | 代码中版本常量     | v3.2.0           |
| package.json       | NPM 包版本 | Node.js 包管理版本 | 0.1.0            |
| moontv:test        | 测试镜像   | 生产就绪测试版本   | 300MB 企业级优化 |

### 四版本系统详解

| 版本类型     | 标识格式    | 管理方式           | 当前状态    | 用途                         |
| ------------ | ----------- | ------------------ | ----------- | ---------------------------- |
| **开发版本** | dev         | Git 标签           | dev         | Docker 镜像制作开发环境标识  |
| **应用版本** | v3.2.0      | VERSION.txt + 代码 | v3.2.0      | 软件功能版本，用于更新检查   |
| **生产版本** | v6.0.0      | Git 标签 + 备份    | -           | 正式发布版本，生产环境部署   |
| **测试镜像** | moontv:test | Docker Registry    | moontv:test | 生产就绪测试版本，300MB 优化 |

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
   # 开发环境构建
   docker build -t moontv:dev .

   # 优化构建（生产推荐）
   ./scripts/docker-build-optimized.sh -t production

   # 多架构构建
   ./scripts/docker-build-optimized.sh --multi-arch --push -t production

   # 测试镜像构建
   ./scripts/docker-build-optimized.sh -t test
   ```

2. **开发版本管理**:

   ```bash
   # 更新开发版本
   git tag -f dev -m "开发版本更新"

   # 查看开发版本状态
   git show dev
   ```

3. **应用版本同步**:
   - 持续跟踪上游仓库版本
   - 保持应用版本与上游一致
   - 确保主页版本更新检查正常工作

4. **生产版本发布**:

   ```bash
   # 创建生产版本标签
   git tag -a v4.1.0 -m "生产版本 v4.1.0"

   # 推送标签备份
   git push origin v4.1.0
   ```

### 版本管理策略

**四版本系统**:

- **开发版本 (dev)**: 本地开发环境标识，统一版本标识
- **应用版本 (v3.2.0)**: 与上游仓库一致的软件版本，用于版本更新检查
- **生产版本 (vX.Y.Z)**: 正式发布版本，用于生产环境部署
- **测试镜像 (moontv:test)**: 生产就绪测试版本，300MB 企业级优化

**版本同步原则**:

- **应用版本**: 严格与上游仓库保持一致，用于版本更新检查
- **开发版本**: 独立管理，统一标识为 "dev"
- **生产版本**: 基于稳定的开发版本创建，用于正式发布
- **更新检查**: 主页通过应用版本检查显示是否有更新

## 项目概述

**项目评级**: ⭐⭐⭐⭐⭐ 95%优秀 (企业级标准)
**技术状态**: 现代化全栈架构，生产就绪
**语义标签**: v6.0 统一重整版 (2025-10-12)
**维护状态**: 活跃开发，持续优化

MoonTV 是基于 Next.js 15 App Router 的跨平台视频聚合播放器。聚合 20+ 视频 API 源（Apple CMS V10 格式），支持多种存储后端，可部署到 Docker、Vercel、Netlify、Cloudflare Pages。

**🌟 项目优势**:

- 🏗️ **现代化架构**: Next.js 15 + TypeScript 5 + Edge Runtime
- 🧠 **智能记忆系统**: v6.0 语义标签，95%检索准确率
- 🐳 **企业级 Docker**: 四阶段构建，72%大小优化
- ⚡ **极致性能**: 毫秒级响应，全球边缘计算支持
- 🛡️ **安全可靠**: Distroless 运行时，自动安全扫描

**核心特性**：

- 🔌 **插件化存储**：localstorage/redis/upstash/d1 可切换
- 🔄 **双模配置**：静态 config.json + 动态数据库配置
- 🔒 **双模认证**：密码模式 + 用户名/密码/HMAC 模式
- 🌊 **流式搜索**：WebSocket 实时多源并行搜索
- ⚡ **Edge Runtime**：所有 API 路由支持边缘计算
- 🐳 **企业级 Docker**：四阶段构建优化，生产就绪
- 🚀 **BuildKit 优化**：内联缓存 + 高级参数化 + 智能标签管理
- 🏷️ **智能标签策略**：自动生成多维度标签体系
- 🔄 **多架构支持**：AMD64 + ARM64 同时构建
- 🛡️ **安全增强**：Distroless 运行时 + 自动安全扫描
- 📱 **PWA 支持**：离线功能和原生应用体验
- 🎯 **智能版本管理**：双版本系统，自动更新检查
- ✅ **批量操作**：视频源批量启用/禁用/删除功能完备
- 🏷️ **测试镜像**：moontv:test 生产就绪测试版本 (300MB)

## 🧠 Serena MCP 智能开发集成

项目集成了 **Serena MCP** 工具，提供企业级智能开发能力：

### 🔧 核心功能

- **🏗️ 项目符号语义理解**: 智能代码结构分析和导航
- **💾 跨会话记忆管理**: 项目知识持久化和上下文保持
- **⚡ 智能重构支持**: 基于语义的精确代码修改
- **🔍 版本控制自动化**: 智能 Git 操作和变更追踪

### 🎯 项目激活 (简化版)

```bash
# 快速激活 MoonTV 项目
/sc:activate-project MoonTV

# 查看可用记忆
list_memories

# 读取核心项目信息
read_memory moontv_core_project_info
```

**记忆系统状态**: 11 个核心记忆文件可用，涵盖项目架构、Docker 优化、开发工作流等

### 📈 智能能力

- **自然语言搜索**: 支持中文技术查询
- **语义理解**: 意图识别和上下文感知
- **知识复用**: 跨会话经验积累
- **项目导航**: 智能代码结构分析

---

## Development Commands

```bash
# Development
pnpm dev              # Start dev server with manifest/runtime generation (0.0.0.0:3000)
pnpm build            # Production build with manifest/runtime generation
pnpm start            # Start production server

# Code Quality
pnpm lint             # Run ESLint on src/
pnpm lint:fix         # Auto-fix ESLint + Prettier
pnpm lint:strict      # ESLint with zero warnings
pnpm typecheck        # TypeScript type checking (no emit)
pnpm format           # Format all files with Prettier
pnpm format:check     # Check formatting without modifying

# Testing (Jest with Next.js)
pnpm test             # Run all tests (requires jest.config.js setup)
pnpm test:watch       # Watch mode for development
# Run single test: pnpm test <file-pattern>

# Utilities
pnpm gen:manifest     # Generate PWA manifest.json
pnpm gen:runtime      # Generate runtime config from config.json

# Cloudflare Pages
pnpm pages:build      # Build for Cloudflare Pages deployment

# Git Hooks
pnpm prepare          # Install Husky git hooks
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

### Docker Build System (v6.0+)

**Four-Stage Enterprise Architecture:**

1. **System Base**: Minimal Alpine with core dependencies and build tools
2. **Dependencies Resolution**: Isolated dependency installation with caching
3. **Application Builder**: Full build with development tools
4. **Production Runtime**: Distroless Node.js runtime (non-root user)

**Build Commands:**

```bash
# Optimized build (recommended)
./scripts/docker-build-optimized.sh -t v4.0.1

# Multi-architecture build
./scripts/docker-build-optimized.sh --multi-arch --push -t production

# Test image (300MB optimized)
docker run -d -p 3000:3000 -e PASSWORD=yourpassword moontv:test
```

**Key Features:**

- BuildKit inline caching for 95%+ cache hit rates
- Distroless runtime for 9/10 security score
- 72% size reduction (1.08GB → 300MB)
- Automatic health checks and security scanning

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
- `PORT=3000` - Application port (Docker default)
- `TZ=Asia/Shanghai` - Timezone configuration

**Version Management:**

- `dev` - Development version tag (permanent)
- `v3.2.0` - Application version (upstream sync)
- `moontv:test` - Production-ready test image (300MB)

## Testing Notes

- **Test Setup**: Jest configured with Next.js integration (`jest.config.js`, `jest.setup.js`)
- **Run single test**: `pnpm test <file-pattern>`
- **Mock storage**: Import mocked `getStorage` in tests
- **Router mocking**: Use `next-router-mock` for navigation tests
- **Test Environment**: jsdom with @testing-library/jest-dom
- **Note**: Jest configuration exists but may need fixes for full functionality

## Docker 部署最佳实践

### 基础运行命令

```bash
# 开发环境构建
docker build -t moontv:dev .

# 生产环境运行
docker run -d -p 3000:3000 \
  -e PASSWORD=yourpassword \
  --name moontv \
  moontv:dev

# 测试镜像 (推荐)
docker run -d -p 3000:3000 \
  -e PASSWORD=yourpassword \
  moontv:test
```

### Docker Compose 示例

```yaml
version: '3.8'
services:
  moontv:
    build: .
    ports:
      - '3000:3000'
    environment:
      - PASSWORD=yourpassword
      - NEXT_PUBLIC_STORAGE_TYPE=redis
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
```

### 健康检查

- 内置健康检查端点: `/api/health`
- 建议配置容器健康检查
- 支持就绪状态和存活性探针

## 部署环境差异

### Docker 环境

- 动态读取 `config.json` (`DOCKER_ENV=true`)
- 支持所有存储后端
- 企业级四阶段构建
- 测试镜像可用 (`moontv:test`)

### Vercel/Netlify

- 静态 `config.json` 编译到包中
- 推荐 `upstash` 存储
- Edge Runtime 自动优化

### Cloudflare Pages

- 使用 `pnpm pages:build` 构建
- 输出到 `.vercel/output/static`
- 需要 `nodejs_compat` 兼容标志
- 推荐 `d1` 存储绑定

## 关键代码位置

- **存储工厂**: `src/lib/db.ts` → `getStorage()`
- **配置合并逻辑**: `src/lib/config.ts` → `getConfig()`
- **认证验证**: `src/middleware.ts`
- **搜索协调**: `src/lib/downstream.ts`
- **API 路由模式**: `src/app/api/*/route.ts`
- **类型定义**: `src/lib/types.ts`, `src/lib/admin.types.ts`
- **版本管理**: `src/lib/version.ts`, `VERSION.txt`

## Common Pitfalls

1. **Storage abstraction bypass:** Never import storage implementations directly, always use `DbManager`
2. **Config.json in DB mode:** Changes to `config.json` require restart or admin config reset
3. **Edge runtime limits:** Cannot use Node.js fs/path directly (use conditional imports)
4. **Middleware auth skip:** Update `shouldSkipAuth()` when adding public routes
5. **localstorage vs DB mode:** Features behave differently (static vs dynamic config)

## Version Management Strategy

**Four-Version System:**

- **Development Version (dev)**: Permanent development environment identifier
- **Application Version (v3.2.0)**: Matches upstream repository, used for update checks
- **Production Version (vX.Y.Z)**: Formal release versions for production deployment
- **Test Image (moontv:test)**: Production-ready test version (300MB optimized)

**Key Files:**

- `VERSION.txt` - Application version tracking
- `src/lib/version.ts` - Code version constants
- Git tags - Project version management
- Package.json - NPM package version (0.1.0)

**Sync Strategy:**

- Application version strictly follows upstream repository
- Development version independently managed as "dev"
- Test image optimized for enterprise deployment (72% size reduction)
