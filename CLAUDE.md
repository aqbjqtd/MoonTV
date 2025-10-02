# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoonTV is a modern video streaming aggregator built with Next.js 14, supporting multi-source search, online playback, user management, and flexible deployment options. **Project maturity score: 8.6/10 (Excellent)**

**Version**: v3.1.1 | **Package Manager**: pnpm 10.14.0 | **TypeScript**: Strict mode enabled

## Essential Development Commands

```bash
# Development
pnpm dev                    # Start development server on 0.0.0.0:3000
pnpm build                  # Build for production
pnpm start                  # Start production server

# Pre-build Scripts (Required)
pnpm gen:manifest           # Generate PWA manifest file
pnpm gen:runtime            # Generate runtime configuration

# Code Quality
pnpm lint                   # Run ESLint
pnpm lint:fix              # Fix linting issues and format code
pnpm lint:strict           # Strict linting with zero warnings
pnpm typecheck             # Run TypeScript type checking
pnpm format                # Format code with Prettier
pnpm format:check          # Check code formatting

# Testing
pnpm test                   # Run Jest tests
pnpm test:watch            # Run tests in watch mode

# Platform-specific Builds
pnpm pages:build           # Build for Cloudflare Pages

# Docker (Optimized)
DOCKER_BUILDKIT=1 docker build -f Dockerfile.optimal -t moontv:test .
docker run -p 3000:3000 --env PASSWORD=your_password moontv:test
```

## Project Architecture

### Core Storage Abstraction

MoonTV uses a multi-backend storage abstraction layer defined in `src/lib/db.ts`:

- **LocalStorage**: Browser-based storage (default)
- **Redis**: Self-hosted Redis instances
- **Upstash Redis**: Cloud-native Redis service
- **Cloudflare D1**: Edge SQL database

The storage type is determined by `NEXT_PUBLIC_STORAGE_TYPE` environment variable. All database operations go through the `DbManager` class which provides a unified API regardless of backend.

### Configuration System

The project has a sophisticated configuration system (`src/lib/config.ts`):

- **File-based config**: `config.json` for localstorage deployments
- **Database config**: Runtime configuration for non-localstorage deployments
- **Environment variables**: Override and fallback values
- **Dynamic merging**: File config merges with database config, with precedence rules

### Authentication Architecture

Multi-layered authentication system (`src/middleware.ts`, `src/lib/auth.ts`):

- **LocalStorage mode**: Simple password verification
- **Database modes**: HMAC signature verification with anti-replay protection
- **User roles**: owner/admin/user hierarchy
- **Middleware protection**: Route-level authentication with selective bypassing

### API Route Structure

All API routes use Edge Runtime and follow consistent patterns:

- **Search API**: Multi-source aggregation with streaming responses
- **Admin APIs**: Protected management endpoints under `/api/admin/`
- **TVBox API**: External service integration with configurable access
- **Douban integration**: Proxy and caching for Chinese movie database

### Video Player Architecture

Dual-player system:

- **Primary**: ArtPlayer + HLS.js for streaming video
- **Secondary**: VidStack React components
- **Source management**: Dynamic source switching with quality detection
- **Wake Lock**: Prevents screen sleep during playback
- **Ad skipping**: Experimental automatic commercial skipping

### Component Organization

- **Layout components**: `PageLayout`, `TopNav`, `Sidebar`, `MobileBottomNav`
- **Video components**: `VideoCard`, `EpisodeSelector`, `SourceSelector`
- **User components**: `UserMenu`, `ThemeProvider`, `VersionPanel`
- **Search components**: `SearchSuggestions`, `FilterOptions`, `FailedSourcesDisplay`
- **Interactive components**: Drag & drop functionality using `@dnd-kit/*`
- **Animation components**: Motion components using `framer-motion`

### Technology Stack Details

- **Core Framework**: Next.js 14.2.30 with App Router
- **Language**: TypeScript 4.9.5 (strict mode)
- **Styling**: Tailwind CSS 3.4.17 with dark mode support
- **UI Components**: Headless UI, Heroicons, Lucide React
- **Video Players**: ArtPlayer 5.2.5 + HLS.js 1.6.6 (primary), VidStack React 1.12.13 (secondary)
- **Drag & Drop**: @dnd-kit/core 6.3.1 series for advanced interactions
- **Animations**: Framer Motion 12.18.1 for smooth transitions
- **State Management**: React hooks + custom Context (no external state library)
- **PWA**: next-pwa 5.6.0 for offline capabilities and desktop installation

## Environment-Specific Behavior

### Docker vs Development

- **Docker**: Uses `DOCKER_ENV=true`, forces Node.js runtime, reads config from filesystem
- **Development**: Uses Edge Runtime, config from build-time generation
- **Build-time vs Runtime**: Configuration loading differs significantly between environments

### Docker Optimization (Production Ready)

- **Optimal Dockerfile**: `Dockerfile.optimal` (5-stage build architecture)
- **Final Image Size**: 349MB (39.6% smaller than standard)
- **Build Command**: `DOCKER_BUILDKIT=1 docker build -f Dockerfile.optimal -t moontv:test .`
- **Key Features**:
  - BuildKit advanced caching for faster builds
  - Non-root user execution (nextjs:nodejs)
  - Dumb-init process management
  - Comprehensive health checks
  - Aggressive dependency cleanup for minimal attack surface
- **Performance**: <1s startup time, 38-85MiB memory usage

### Storage Backend Implications

- **LocalStorage**: All data stored client-side, limited user management
- **Database backends**: Server-side storage, multi-user support, admin panel at `/admin`
- **API differences**: Some features only available with specific storage types

## Development Guidelines

### Code Conventions

- **TypeScript**: Strict mode enabled, interfaces preferred over types
- **ESLint Rules**: No unused variables/imports, simple import sorting, React JSX rules
- **Prettier**: Single quotes, 2-space indentation, semicolons, arrow functions with parentheses
- **File Naming**: Components (PascalCase), utilities (kebab-case), constants (UPPER_SNAKE_CASE)
- **Git Workflow**: Husky pre-commit hooks, CommitLint conventional commits, lint-staged

### Development Best Practices

- **Storage Abstraction**: Always use `DbManager` class, never direct storage backend access
- **Configuration Management**: Use `getConfig()` for runtime values, respect environment variable precedence
- **API Development**: Edge Runtime for all routes, consistent error handling, streaming responses where appropriate
- **Authentication**: HMAC signature verification for database modes, middleware-based route protection
- **Component Design**: Function components + hooks, props interfaces with `{ComponentName}Props` naming

### Testing Strategy

- **Unit Tests**: Jest + Testing Library, focus on utility functions and React components
- **Integration Tests**: User registration/login, search and playback flows, data synchronization
- **Coverage Goals**: 100% for utilities, key interactions for components, normal/exception cases for APIs
- **Test Placement**: Alongside source files or in `__tests__` directories

### Performance Optimization

- **Frontend**: Next.js Image optimization, component lazy loading, bundle size optimization, PWA caching
- **Backend**: API response caching, database query optimization, concurrent request handling, Edge Runtime utilization
- **Build Optimization**: Use `Dockerfile.optimal` for production, BuildKit caching, dependency layering

### Security Best Practices

- **Authentication**: Always verify user identity, HMAC signatures for database modes, anti-replay protection
- **API Security**: Input validation, SQL injection prevention, XSS protection, CSRF protection
- **Data Protection**: Sensitive data encryption, secure key management, encrypted data transmission
- **Runtime Security**: Non-root Docker execution, minimal attack surface, health checks

### Deployment Configurations

- **Vercel** (Recommended): Zero-config deployment, Edge Runtime compatible, automatic builds
- **Docker** (Production Ready): Optimized 5-stage build, 349MB final image, BuildKit caching
- **Cloudflare Pages**: D1 database integration, edge computing deployment
- **Netlify**: Static build with serverless functions
- **Environment Variables**: `PASSWORD` (required), `NEXT_PUBLIC_STORAGE_TYPE`, `USERNAME`, database URLs

### Common Development Patterns

- **API Routes**: All use Edge Runtime with consistent error handling and response formats
- **Component Props**: TypeScript interfaces for type safety, proper prop validation
- **Database Operations**: Use DbManager abstraction layer, respect storage backend differences
- **Configuration Access**: `getConfig()` function for runtime values, environment-aware configuration loading
- **Error Handling**: Unified error responses, proper logging, user-friendly error messages

### Troubleshooting Guide

- **Configuration Issues**: Check environment variables and storage backend compatibility
- **Authentication Failures**: Verify password and HMAC signature logic
- **Playback Problems**: Check video sources and network connectivity
- **Database Connection**: Validate connection strings and user permissions
- **Docker Issues**: Ensure BuildKit enabled, check multi-stage build logs
