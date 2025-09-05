# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Development
```bash
# Install dependencies (uses pnpm)
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start

# Type checking
pnpm typecheck

# Linting
pnpm lint
pnpm lint:fix

# Format code
pnpm format

# Generate runtime config from config.json
pnpm gen:runtime

# Generate PWA manifest
pnpm gen:manifest
```

### Docker Operations
```bash
# Build optimized Docker image
docker build -t aqbjqtd/moontv:simplified .

# Run container (recommended for development)
docker run -d --name moontv -p 9000:3000 --env PASSWORD=123456 aqbjqtd/moontv:simplified

# View logs
docker logs moontv

# Stop and remove container
docker stop moontv && docker rm moontv
```

### Git Operations
```bash
# Quick rollback to stable version
git reset --hard v1.0-moontv-stable

# Check differences from stable version
git diff v1.0-moontv-stable..HEAD

# View stable version info
git show v1.0-moontv-stable
```

## Architecture Overview

### Core Architecture
This is a **frontend-only video streaming application** built with Next.js 14 that requires no backend database. The architecture is designed around:

1. **No Backend Database**: Uses IndexedDB + localStorage for data persistence
2. **Video Aggregation**: Aggregates content from multiple third-party sources via Apple CMS V10 APIs
3. **Client-Side Processing**: All logic runs in the browser, including video playback and data management
4. **Static Deployment**: Can be deployed as static files or in Docker containers

### Key Technical Components

#### Video Player (`src/app/play/page.tsx`)
- **Primary Component**: 2109 lines, the heart of the application
- **Video Engine**: HLS.js for m3u8 stream processing + ArtPlayer for UI
- **Multi-Source Support**: Automatic source switching with speed testing
- **Buffer Optimization**: Configurable buffer management for smooth seeking
- **Error Recovery**: Timeout-based recovery mechanisms for network/media errors

#### Data Layer (`src/lib/db.client.ts`)
- **Storage**: IndexedDB with localStorage fallback
- **Features**: Watch history, favorites, skip settings, search history
- **No Backend**: Completely client-side, no server required

#### Configuration System
- **Runtime Config**: `src/lib/runtime.ts` (auto-generated from `config.json`)
- **Environment Variables**: Docker environment support with runtime injection
- **API Sources**: Configurable third-party video sources in `config.json`

### Critical Performance Considerations

#### Video Playback Optimization
The video player includes several critical optimizations:
- **Buffer Configuration**: `maxBufferLength: 60s`, `backBufferLength: 90s` for smooth seeking
- **Error Recovery**: 1-second delay before recovery attempts to prevent cascading failures
- **Memory Management**: 60MB buffer limit with automatic cleanup
- **Low Latency Mode**: Enabled for real-time streaming

#### Build Optimization
- **Multi-Stage Docker Build**: Separate dependency, build, and runtime stages
- **BuildKit Support**: Parallel building with cache mounting
- **pnpm Caching**: Optimized package installation with frozen lockfile

### Version Management Strategy

#### Safety Net Approach
- **v1.0-moontv-stable**: Permanent safety anchor point (commit fb3fd2a)
- **Current Working Version**: Based on stable version with small optimizations
- **Quick Rollback**: Always able to return to known stable state

#### Decision Process
- Keep stable version unchanged as backup
- Make small, incremental improvements to working version
- Any significant issues trigger immediate rollback to stable version

## Development Guidelines

### Video Player Modifications
When working with `src/app/play/page.tsx`:
1. **Test Seeking**: Always test video progress bar dragging extensively
2. **Buffer Management**: Changes to buffer settings require real network testing
3. **Error Handling**: Ensure all error cases have recovery mechanisms
4. **Memory Leaks**: Check for proper cleanup of event listeners and timeouts

### Configuration Changes
- **config.json**: API source configuration, no rebuild required
- **Environment Variables**: Runtime configuration via Docker environment
- **Runtime Config**: Use `pnpm gen:runtime` after config changes

### Docker Development
- **Multi-Stage Build**: Dependencies → Build → Runtime stages
- **Non-Root User**: Security best practice with dedicated user
- **BuildKit**: Required for cache mounting and parallel builds
- **Port Mapping**: Development uses 9000→3000 mapping

### Performance Testing
- **Video Seeking**: Test frequent progress bar dragging
- **Source Switching**: Verify automatic failover between sources
- **Memory Usage**: Monitor browser memory during long playback sessions
- **Network Conditions**: Test with various network speeds

## Important Files and Patterns

### Core Application Files
- `src/app/play/page.tsx`: Main video player component (critical path)
- `src/lib/db.client.ts`: IndexedDB data layer
- `src/lib/runtime.ts`: Runtime configuration (auto-generated)
- `src/app/layout.tsx`: Root layout with runtime config injection
- `config.json`: API sources and application configuration

### Build and Deployment
- `Dockerfile`: Multi-stage build with optimization
- `.dockerignore`: Comprehensive build context optimization
- `start.js`: Production startup script
- `next.config.mjs`: Next.js configuration with standalone output

### Configuration Patterns
- **Runtime Injection**: Config serialized into `window.RUNTIME_CONFIG`
- **Environment Fallback**: Environment variables with config.json fallback
- **Type Safety**: Full TypeScript coverage with strict mode

## Testing and Quality Assurance

### Critical Test Scenarios
1. **Video Playback**: Start, pause, seek, full screen
2. **Source Switching**: Automatic failover when source fails
3. **Buffer Management**: Seek during buffering, network interruption
4. **Memory Management**: Long playback sessions, multiple videos
5. **Error Recovery**: Network errors, media errors, source failures

### Quality Checks
```bash
# TypeScript compilation
pnpm typecheck

# Linting with zero warnings
pnpm lint:strict

# Format check
pnpm format:check

# Build verification
pnpm build
```

## Deployment Notes

### Docker Deployment
- **Image Tag**: `aqbjqtd/moontv:simplified` (current optimized version)
- **Environment**: `PASSWORD=123456` for admin access
- **Port**: 9000 (mapped to 3000 internally)
- **User**: Non-root user for security

### Static Deployment
- **Platforms**: Vercel, Netlify (supports localStorage storage)
- **Environment Variables**: Set PASSWORD for admin access
- **Storage**: localStorage only (no Redis/D1 support on static platforms)

### Security Considerations
- **Password Protection**: Always set PASSWORD environment variable
- **Private Use**: Designed for personal use, not public deployment
- **No Sensitive Data**: All configuration is safe to commit except passwords