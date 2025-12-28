# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoonTV is a Next.js 14-based video streaming aggregator that searches and plays content from multiple video sources. It supports multi-storage backends, user authentication, favorites, playback records, and TVBox integration.

## Development Commands

### Core Development

```bash
# Development server (generates manifest & runtime files automatically)
pnpm dev

# Production build
pnpm build

# Start production server
pnpm start

# Build for Cloudflare Pages
pnpm pages:build
```

### Code Quality

```bash
# Type checking
pnpm typecheck

# Linting
pnpm lint
pnpm lint:fix
pnpm lint:strict  # Zero warnings allowed

# Testing
pnpm test
pnpm test:watch
```

### Code Formatting

```bash
# Format code
pnpm format

# Check formatting
pnpm format:check
```

### Pre-commit Hooks

The project uses Husky with lint-staged. All TypeScript files are automatically linted and formatted on commit.

## Architecture Overview

### Storage Abstraction Layer

The project uses a storage abstraction pattern (`src/lib/types.ts` - `IStorage` interface) that supports multiple backends:

- **LocalStorage**: Browser storage (default for personal use)
- **Redis**: Self-hosted Redis instances
- **Upstash**: Cloud Redis service
- **Cloudflare D1**: Serverless SQLite database

Storage type is controlled by `NEXT_PUBLIC_STORAGE_TYPE` environment variable.

### Configuration System

The project has a sophisticated configuration system in `src/lib/config.ts`:

1. **File Configuration**: `config.json` for localstorage deployments
2. **Database Configuration**: Runtime config storage for other deployment types
3. **Environment Variable Overrides**: Production settings via environment variables

Configuration sources merge in precedence: Environment Variables > Database > File > Defaults.

### Key Architecture Patterns

#### Video Source Integration

- **Apple CMS V10 API**: Standard format for video sources
- **Source Configuration**: Dynamic video source management via admin panel
- **Custom Categories**: User-defined content categories with Douban integration
- **API Proxy Support**: Multiple proxy options for circumventing access restrictions

#### User Management & Access Control

- **Role-based Access**: owner, admin, user, banned roles
- **Group Management**: Source access control via user groups
- **TVBox Integration**: Optional API interface for external players
- **Authentication**: Session-based with configurable registration

#### Frontend Architecture

- **App Router**: Next.js 14 App Router pattern
- **Responsive Design**: Desktop sidebar + mobile bottom navigation
- **Component Library**: Reusable UI components with Tailwind CSS
- **State Management**: React hooks with local storage fallback

### Critical Files for Understanding

- `src/lib/config.ts`: Configuration loading and management logic
- `src/lib/db.ts`: Storage abstraction and database manager
- `src/lib/types.ts`: Core type definitions and interfaces
- `src/lib/admin.types.ts`: Admin configuration types
- `next.config.js`: Build configuration with PWA and image optimization
- `src/app/api/`: API routes following Next.js App Router pattern

### Build System

The project uses custom build scripts:

- `scripts/generate-manifest.js`: Generates PWA manifest
- `scripts/generate-runtime.js`: Generates runtime configuration

These are automatically executed during `pnpm dev` and `pnpm build`.

### Security Considerations

- **Deployment Security**: Always set PASSWORD environment variable for non-localstorage deployments
- **API Access**: TVBox interface can be password protected
- **Content Filtering**: Configurable adult content filtering
- **Input Validation**: Uses Zod schema validation where applicable

### Environment-Specific Behavior

#### Local Development

- Uses `public/config.json` for video sources
- Local storage for user data
- Full feature set available

#### Production Deployments

- Database storage required for multi-user functionality
- Configuration via admin panel or environment variables
- Optional features: user registration, TVBox API, group management

## Deployment Notes

The project supports multiple deployment targets with specific environment variables and requirements. Refer to README.md for detailed deployment instructions per platform.

## Development Guidelines

- Use TypeScript strict mode (already configured)
- Follow existing ESLint configuration with import sorting rules
- Test changes in both localStorage and database storage modes
- Ensure PWA functionality works across different deployment targets
- Test TVBox integration when modifying video source handling
