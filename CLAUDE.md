# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Development Commands

```bash
# Development
pnpm dev                    # Start development server on 0.0.0.0:3000
pnpm build                  # Build for production
pnpm start                  # Start production server

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

# Docker
docker build -t moontv .   # Build Docker image
docker run -p 3000:3000 --env PASSWORD=your_password moontv
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

## Environment-Specific Behavior

### Docker vs Development
- **Docker**: Uses `DOCKER_ENV=true`, forces Node.js runtime, reads config from filesystem
- **Development**: Uses Edge Runtime, config from build-time generation
- **Build-time vs Runtime**: Configuration loading differs significantly between environments

### Storage Backend Implications
- **LocalStorage**: All data stored client-side, limited user management
- **Database backends**: Server-side storage, multi-user support, admin panel at `/admin`
- **API differences**: Some features only available with specific storage types

## Development Notes

### Code Conventions
- Uses TypeScript strict mode
- Tailwind CSS for styling with dark mode support
- React hooks for state management (no external state library)
- ESLint + Prettier with pre-commit hooks via Husky

### Testing Strategy
- Jest + Testing Library configuration in `jest.config.js`
- Tests should be placed alongside source files or in `__tests__` directories
- Focus on testing utility functions and React components

### Deployment Configurations
The project supports multiple deployment targets with different configurations:
- **Vercel**: Zero-config deployment, Edge Runtime compatible
- **Netlify**: Static build with serverless functions
- **Cloudflare Pages**: D1 database integration, Pages build output
- **Docker**: Multi-stage build, non-root user, standalone output

### Security Considerations
- HMAC-based authentication for database deployments
- Middleware-based route protection
- Environment variable-based configuration
- CORS proxy support for external API calls

### Common Development Patterns
- **API routes**: All use Edge Runtime with consistent error handling
- **Component props**: Use TypeScript interfaces for type safety
- **Database operations**: Use the DbManager abstraction layer
- **Configuration**: Access via `getConfig()` function for runtime values