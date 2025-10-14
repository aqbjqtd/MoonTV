# MoonTV 技术栈配置详解 v6.0 (2025-10-12)

> **技术评级**: 现代化全栈架构 (企业级)  
> **语义标签版本**: v6.0 统一重整版  
> **最后更新**: 2025 年 10 月 12 日  
> **信息状态**: 精炼整合版本

## 🏷️ 语义标签分类

### 核心标签

```yaml
主要技术栈标签:
  - technology_stack:frontend:nextjs_15
  - technology_stack:frontend:react_18
  - technology_stack:frontend:typescript_5
  - technology_stack:frontend:tailwind_css_3
  - technology_stack:frontend:app_router
  - technology_stack:frontend:server_components
  - technology_stack:frontend:client_components
  - technology_stack:frontend:streaming_ssr

后端技术标签:
  - technology_stack:backend:nodejs_20
  - technology_stack:backend:edge_runtime
  - technology_stack:backend:api_routes
  - technology_stack:backend:websocket_communication
  - technology_stack:backend:streaming_processing
  - technology_stack:backend:middleware_system
  - technology_stack:backend:authentication_jwt
  - technology_stack:backend:rate_limiting

开发工具标签:
  - technology_stack:tools:pnpm_package_manager
  - technology_stack:tools:swc_compiler
  - technology_stack:tools:eslint_linter
  - technology_stack:tools:prettier_formatter
  - technology_stack:tools:jest_testing
  - technology_stack:tools:typescript_strict
  - technology_stack:tools:git_version_control
  - technology_stack:tools:docker_containerization
```

### 质量与优化标签

```yaml
质量保证标签:
  - development_workflow:quality:code_standards
  - development_workflow:quality:type_safety
  - development_workflow:quality:linting_rules
  - development_workflow:quality:formatting_standards
  - testing_quality:types:unit_testing
  - testing_quality:tools:jest_framework
  - quality:technical:enterprise_grade
  - quality:technical:production_ready

性能优化标签:
  - performance_optimization:frontend:code_splitting
  - performance_optimization:frontend:lazy_loading
  - performance_optimization:frontend:image_optimization
  - performance_optimization:frontend:bundle_optimization
  - performance_optimization:frontend:caching_strategies
  - performance_optimization:frontend:render_optimization
  - performance_optimization:build:build_time_optimization
  - performance_optimization:build:incremental_builds
```

### 架构与部署标签

```yaml
架构设计标签:
  - project_architecture:core:nextjs_app_router
  - project_architecture:core:component_hierarchy
  - project_architecture:core:state_management
  - project_architecture:design:modular_design
  - project_architecture:design:scalable_patterns

部署相关标签:
  - deployment_operations:platforms:vercel
  - deployment_operations:platforms:netlify
  - deployment_operations:platforms:cloudflare_pages
  - deployment_operations:containerization:docker_multi_stage
  - deployment_operations:operations:ci_cd_pipeline
  - deployment_operations:operations:automated_testing
```

## 📋 技术栈版本矩阵

### 前端技术栈 (现代化)

```json
{
  "core_framework": {
    "next": "15.0.3",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "typescript": "5.6.3"
  },
  "ui_framework": {
    "tailwindcss": "3.4.14",
    "autoprefixer": "10.4.20",
    "postcss": "8.4.47"
  },
  "package_manager": {
    "pnpm": "10.14.0",
    "node": "20.18.0"
  }
}
```

### 开发工具链 (企业级)

- **编译器**: SWC (Rust) + Turbopack (Next.js 内置)
- **代码质量**: ESLint 8.57.1 + Prettier 3.3.3
- **类型检查**: TypeScript 5.6.3 严格模式
- **构建优化**: 增量构建 + 代码分割

### 运行时环境 (高性能)

- **服务端**: Node.js 20.18.0 LTS + Edge Runtime (V8)
- **浏览器兼容**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **容器化**: Docker + BuildKit + Multi-architecture

## 🏗️ Next.js 15 App Router 架构

### 目录结构优化

```
src/
├── app/                    # App Router (核心)
│   ├── (auth)/            # 路由分组
│   ├── admin/             # 管理界面
│   ├── api/               # API路由
│   │   ├── admin/         # 管理API
│   │   ├── search/        # 搜索API
│   │   ├── favorites/     # 收藏API
│   │   └── health/        # 健康检查
│   ├── globals.css        # 全局样式
│   ├── layout.tsx         # 根布局
│   └── page.tsx           # 首页
├── components/            # 组件库
│   ├── ui/               # UI组件
│   ├── forms/            # 表单组件
│   └── layout/           # 布局组件
├── lib/                  # 核心库
│   ├── types.ts          # 类型定义
│   ├── db.ts             # 存储抽象
│   ├── config.ts         # 配置管理
│   └── downstream.ts     # 数据获取
└── scripts/              # 构建脚本
```

### 关键特性配置

- **Server Components**: 默认支持，性能优化
- **Streaming SSR**: 增量渲染，提升首屏速度
- **嵌套布局**: 复杂页面布局管理
- **并行路由**: 独立路由并行渲染
- **Edge Runtime**: 全 API 路由边缘计算支持

## ⚙️ 配置文件详解

### TypeScript 配置 (严格模式)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "ES6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"]
    }
  }
}
```

### Next.js 配置 (性能优化)

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    optimizePackageImports: ['lucide-react'],
  },
  images: {
    domains: [],
  },
  compress: true,
  poweredByHeader: false,
  generateEtags: true,
  httpAgentOptions: {
    keepAlive: true,
  },
};
```

### Tailwind CSS 配置 (原子化)

```javascript
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: 'hsl(var(--primary))',
        secondary: 'hsl(var(--secondary))',
      },
      fontFamily: {
        sans: ['var(--font-inter)'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/typography')],
};
```

## 🔧 环境配置体系

### 开发环境 (.env.local)

```bash
# 基础配置
NODE_ENV=development
PORT=3000
TZ=Asia/Shanghai

# 认证配置
PASSWORD=yourpassword
USERNAME=admin

# 存储配置
NEXT_PUBLIC_STORAGE_TYPE=localstorage

# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_ENABLE_REGISTER=true
NEXT_PUBLIC_SEARCH_MAX_PAGE=5
```

### 生产环境 (Docker)

```bash
# 生产模式
NODE_ENV=production
PORT=3000
TZ=Asia/Shanghai

# 存储选择
NEXT_PUBLIC_STORAGE_TYPE=redis
REDIS_URL=redis://redis:6379

# 安全配置
PASSWORD=yourproductionpassword
USERNAME=admin

# 监控配置
NEXT_PUBLIC_ENABLE_TELEMETRY=false
```

### 存储后端配置 (四种模式)

#### localstorage 模式 (默认)

```bash
NEXT_PUBLIC_STORAGE_TYPE=localstorage
PASSWORD=yourpassword
NEXT_PUBLIC_SITE_NAME=MoonTV
```

#### Redis 模式 (Docker 推荐)

```bash
NEXT_PUBLIC_STORAGE_TYPE=redis
REDIS_URL=redis://localhost:6379
PASSWORD=yourpassword
USERNAME=admin
```

#### Upstash 模式 (Serverless)

```bash
NEXT_PUBLIC_STORAGE_TYPE=upstash
UPSTASH_URL=https://your-redis.upstash.io
UPSTASH_TOKEN=yourtoken
PASSWORD=yourpassword
USERNAME=admin
```

#### D1 模式 (Cloudflare Pages)

```bash
NEXT_PUBLIC_STORAGE_TYPE=d1
# Cloudflare D1通过环境变量自动绑定
PASSWORD=yourpassword
USERNAME=admin
```

## 📦 核心依赖分析

### 生产依赖 (核心功能)

```json
{
  "dependencies": {
    "next": "15.0.3",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "typescript": "5.6.3",
    "tailwindcss": "3.4.14",
    "clsx": "2.0.0",
    "lucide-react": "0.438.0",
    "@upstash/redis": "1.25.0",
    "ws": "8.18.0"
  }
}
```

### 开发依赖 (工具链)

```json
{
  "devDependencies": {
    "eslint": "8.57.1",
    "eslint-config-next": "15.0.3",
    "prettier": "3.3.3",
    "prettier-plugin-tailwindcss": "0.6.8",
    "@types/node": "22.7.5",
    "@types/react": "18.3.11",
    "@types/react-dom": "18.3.0",
    "@types/ws": "8.5.10"
  }
}
```

## 🚀 性能优化配置

### 构建优化策略

- **SWC 编译器**: Rust 编译器，构建速度提升 10 倍
- **增量构建**: 仅构建变更文件，开发体验优化
- **代码分割**: 自动路由级代码分割，首屏加载优化
- **Tree Shaking**: 自动移除未使用代码，包大小优化

### 运行时优化

- **Edge Runtime**: 全球边缘节点，冷启动<100ms
- **Streaming**: 流式 SSR 渲染，用户感知性能提升
- **缓存策略**: 多层缓存，重复访问性能优化
- **图片优化**: Next.js Image 组件，自动优化和格式转换

### 包管理优化 (pnpm)

```bash
# .pnpmrc 配置
strict-peer-dependencies=true
registry=https://registry.npmmirror.com
save-exact=true
fetch-concurrency=10
```

## 🔧 开发工具集成

### 代码质量工具

```json
// .eslintrc.json
{
  "extends": ["next/core-web-vitals", "@typescript-eslint/recommended"],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "prefer-const": "error"
  }
}
```

### 代码格式化

```json
// .prettierrc
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
```

### Git Hooks (自动化质量检查)

```json
// package.json scripts
{
  "scripts": {
    "precommit": "lint-staged",
    "lint": "eslint src --max-warnings 0",
    "lint:fix": "eslint src --fix && prettier --write src",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write src"
  }
}
```

## 🌐 部署配置优化

### Vercel 部署配置

```json
{
  "buildCommand": "pnpm build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "env": {
    "NEXT_PUBLIC_STORAGE_TYPE": "upstash"
  },
  "build": {
    "env": {
      "NEXT_PUBLIC_SITE_NAME": "MoonTV"
    }
  }
}
```

### Cloudflare Pages 配置

```yaml
build:
  command: 'pnpm pages:build'
  destination: '.vercel/output/static'
compatibility_flags:
  - 'nodejs_compat'
environment:
  NODE_VERSION: '20'
```

### Docker 部署优化

- **四阶段构建**: System Base → Dependencies → Application → Production
- **多架构支持**: AMD64 + ARM64 同时构建
- **安全配置**: Distroless 运行时 + 非 root 用户
- **缓存优化**: BuildKit 内联缓存 + GitHub Actions 缓存

## 📊 性能监控配置

### Vercel Analytics (默认)

- Core Web Vitals 监控
- 用户体验指标收集
- 性能瓶颈自动识别

### 自定义健康检查

```typescript
// /api/health/route.ts
export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
  });
}
```

### 错误追踪集成

```typescript
// 全局错误处理
window.addEventListener('error', handleError);
window.addEventListener('unhandledrejection', handleRejection);

// 错误边界组件
import ErrorBoundary from '@/components/ErrorBoundary';
```

## 🎯 最佳实践指南

### 代码组织原则

1. **组件原子化**: 单一职责，高内聚低耦合
2. **类型安全**: 100% TypeScript 覆盖，严格模式
3. **性能优先**: 代码分割，懒加载，缓存优化
4. **可维护性**: 清晰目录结构，统一命名规范

### 开发流程规范

1. **分支管理**: feature/\* 开发分支
2. **提交规范**: Conventional Commits
3. **代码审查**: PR 必须经过代码审查
4. **测试覆盖**: 关键逻辑必须有测试

### 性能优化清单

- ✅ 图片懒加载和优化
- ✅ 代码分割和动态导入
- ✅ 缓存策略优化
- ✅ Bundle 分析和优化
- ✅ 字体加载优化
- ✅ Edge Runtime 最大化利用

## 🔄 技术债务管理

### 版本更新策略

```bash
# 检查过时依赖
pnpm outdated

# 安全漏洞扫描
pnpm audit

# 更新补丁版本
pnpm update --latest patch

# 测试兼容性
pnpm build && pnpm test
```

### 技术演进规划

**短期 (1-3 个月)**: Next.js 15 最新版本 + Tailwind CSS 优化
**中期 (3-6 个月)**: React 19 评估 + 新 CSS 方案探索  
**长期 (6-12 个月)**: 新兴技术栈评估 + 架构现代化演进

## 📋 快速参考命令

### 开发命令

```bash
pnpm dev              # 开发服务器 (0.0.0.0:3000)
pnpm build            # 生产构建
pnpm start            # 生产服务器启动
pnpm lint             # ESLint检查
pnpm lint:fix         # 自动修复 + 格式化
pnpm typecheck        # TypeScript类型检查
pnpm format           # Prettier格式化
pnpm test             # 运行测试
pnpm test:watch       # 测试监听模式
```

### 生成命令

```bash
pnpm gen:manifest     # 生成PWA manifest.json
pnpm gen:runtime      # 生成运行时配置
pnpm pages:build      # Cloudflare Pages构建
```

### Docker 命令

```bash
# 优化构建
./scripts/docker-build-optimized.sh -t v5.1.0

# 多架构构建
./scripts/docker-build-optimized.sh --multi-arch --push -t v5.1.0

# 运行测试镜像
docker run -d -p 3000:3000 moontv:test
```

## 🏷️ 标签应用说明

### 标签使用指南

```yaml
前端技术查询: technology_stack:frontend:nextjs_15 → Next.js 15最新特性
  technology_stack:frontend:typescript_5 → TypeScript 5配置
  technology_stack:frontend:tailwind_css_3 → Tailwind CSS样式配置

后端技术查询: technology_stack:backend:edge_runtime → Edge Runtime使用
  technology_stack:backend:websocket_communication → WebSocket实现
  technology_stack:backend:middleware_system → 中间件系统

开发工具查询: technology_stack:tools:pnpm_package_manager → pnpm包管理
  technology_stack:tools:swc_compiler → SWC编译器配置
  technology_stack:tools:eslint_linter → ESLint规则配置

性能优化查询: performance_optimization:frontend:code_splitting → 代码分割策略
  performance_optimization:frontend:caching_strategies → 缓存策略配置
  performance_optimization:build:build_time_optimization → 构建优化

质量保证查询: development_workflow:quality:type_safety → 类型安全配置
  development_workflow:quality:code_standards → 代码标准规范
  testing_quality:tools:jest_framework → Jest测试配置
```

### 关联推荐

```yaml
Next.js生态: technology_stack:frontend:nextjs_15
  → project_architecture:core:nextjs_app_router
  → technology_stack:frontend:server_components
  → deployment_operations:platforms:vercel

开发工具链: technology_stack:tools:pnpm_package_manager
  → development_workflow:environment:dependency_management
  → technology_stack:tools:eslint_linter
  → development_workflow:quality:code_standards

性能优化: performance_optimization:frontend:code_splitting
  → performance_optimization:frontend:lazy_loading
  → performance_optimization:frontend:bundle_optimization
  → monitoring_analytics:application:performance_monitoring

部署相关: deployment_operations:platforms:vercel
  → project_architecture:core:nextjs_app_router
  → deployment_operations:containerization:docker_multi_stage
  → security_quality:infrastructure:container_security
```

## 🎯 技术栈总结

MoonTV v5.1 技术栈体现了现代全栈应用的最佳实践：

🎯 **技术选型**: Next.js 15 + TypeScript + Tailwind CSS 现代化组合  
🚀 **性能优化**: SWC 编译器 + Edge Runtime + 多层缓存策略  
🛡️ **开发体验**: 完整工具链 + 代码规范 + 自动化流程  
🔧 **部署灵活**: 多平台支持 + 容器化 + 边缘计算兼容  
📈 **可维护性**: 清晰架构 + 类型安全 + 监控调试

这套技术栈配置为项目提供了强大的技术基础和优秀的开发体验，是现代 Web 开发的优秀范例。

---

**配置维护**: 项目代码 + 官方文档  
**优化验证**: 性能测试 + 安全扫描  
**兼容性测试**: 多平台部署验证  
**语义标签**: v6.0 统一重整版  
**下次更新**: 依赖安全更新时
