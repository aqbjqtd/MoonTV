# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MoonTV** is a video aggregation platform built with Next.js 14 that provides multi-source video streaming, search, and user management capabilities. It's a fork of the original LunaTV project.

## Development Commands

```bash
# Development
pnpm dev                    # Start development server (includes manifest/runtime generation)
pnpm build                  # Build for production
pnpm start                  # Start production server
pnpm pages:build            # Build for Cloudflare Pages

# Code Quality
pnpm lint                   # Run ESLint
pnpm lint:fix               # Fix linting issues and format
pnpm lint:strict            # Strict linting (no warnings allowed)
pnpm typecheck              # Run TypeScript type checking
pnpm format                 # Format code with Prettier
pnpm format:check           # Check code formatting

# Testing
pnpm test                   # Run Jest tests
pnpm test:watch             # Run tests in watch mode

# Build-time Generation
pnpm gen:manifest           # Generate PWA manifest
pnpm gen:runtime            # Generate runtime configuration
```

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript 4.x
- **Styling**: Tailwind CSS 3
- **Package Manager**: pnpm (v10.14.0)
- **Video Player**: ArtPlayer 5.2.5 + HLS.js 1.6.6
- **Storage**: Multiple backends (localStorage, Redis, Upstash Redis, Cloudflare D1)
- **PWA**: next-pwa 5.6.0

## Architecture Overview

### Storage Abstraction Layer

The system uses a storage abstraction pattern with `IStorage` interface defining contracts for all storage operations. Implementations include:

- LocalStorage (browser-based)
- Redis (self-hosted)
- Upstash Redis (cloud-based)
- Cloudflare D1 (serverless SQLite)

Storage selection is dynamic based on `NEXT_PUBLIC_STORAGE_TYPE` environment variable.

### Multi-Environment Configuration

- **Local Storage Mode**: Uses `config.json` file for static configuration
- **Remote Storage Modes**: Uses runtime configuration via database with admin panel at `/admin`
- **Environment Variables**: Extensive configuration via env vars for different deployment targets

### API Architecture

- **Apple CMS Integration**: Standard VOD API format support for video sources
- **Multi-source Aggregation**: Combines results from 20+ video sources
- **Caching System**: Configurable cache times via `cache_time` setting
- **Douban Integration**: Movie metadata and ratings with multiple proxy options

### Key Directories Structure

#### `/src/app/` (Next.js App Router)

- `layout.tsx`: Root layout with theme provider and global configuration
- `page.tsx`: Main homepage with video browsing
- `admin/`: Admin panel for configuration management (remote storage only)
- `api/`: API routes including:
  - `search/`: Search APIs (single and batch with streaming)
  - `tvbox/`: TVBox integration endpoints
  - `douban/`: Douban movie data integration
  - `admin/`: Admin management APIs
- `search/`, `play/`, `login/`, `douban/`: Feature pages

#### `/src/lib/` (Core Logic)

- `config.ts`: Configuration management (28KB) - handles both file-based and runtime config
- `db.client.ts`: Client-side database operations (47KB) - localStorage-based operations
- `*.db.ts`: Storage implementations (`d1.db.ts`, `redis.db.ts`, `upstash.db.ts`)
- `auth.ts`: Authentication logic with cookie-based sessions
- `types.ts`: TypeScript type definitions
- `utils.ts`: Utility functions

#### `/src/components/` (React Components)

Key components include `VideoCard.tsx`, `UserMenu.tsx`, `EpisodeSelector.tsx`, `MultiLevelSelector.tsx`, and others for video browsing and playback.

## Configuration System

### Environment Variables

Key variables that affect behavior:

- `NEXT_PUBLIC_STORAGE_TYPE`: Storage backend selection (localstorage/redis/d1/upstash)
- `PASSWORD`: Required security setting for all deployments
- `USERNAME`: Admin username (for non-localstorage deployments)
- `NEXT_PUBLIC_ENABLE_REGISTER`: User registration control
- TVBox integration settings and Douban proxy configurations

### Video Source Configuration

- `config.json`: For localstorage mode, contains video sources and custom categories
- Admin panel: For remote storage modes, provides web-based configuration
- Supports Apple CMS V10 API format for video sources
- Custom categories for content organization (e.g., "华语", "欧美", "韩国", "日本")

## Deployment Considerations

### Supported Platforms

- **Vercel**: Recommended for ease of deployment
- **Docker**: Complete containerization with multi-stage builds
- **Netlify**: Alternative static hosting
- **Cloudflare Pages**: Edge deployment with D1 database support

### Docker Configuration

- Multi-stage build optimized for production
- Node.js 20 Alpine runtime
- Non-root user for security
- Standalone output for efficient container size

### Security Requirements

- **Password Protection**: Required for all deployments (PASSWORD env var)
- **User Registration**: Can be disabled via NEXT_PUBLIC_ENABLE_REGISTER=false
- **Admin Panel**: `/admin` route for configuration management (remote storage only)

## Special Development Notes

### Build-time Generation

- `pnpm gen:manifest`: Generates PWA manifest from runtime config
- `pnpm gen:runtime`: Generates runtime configuration file
- Both run automatically during dev and build processes

### Client/Server Separation

- `db.client.ts`: Client-side operations using localStorage
- Server-side storage implementations for database backends
- Clear separation to avoid bundling Node.js modules in client code

### Video Features

- HLS streaming with adaptive bitrate
- Progress tracking and resume playback
- Skip intro/outro functionality
- Multi-episode content support
- TVBox API compatibility for external player integration

### PWA Capabilities

- Service worker for offline caching
- App manifest for installable experience
- Mobile-optimized responsive design
