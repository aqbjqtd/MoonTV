# MoonTV 开发环境配置指南 v4.1

**文档类型**: 开发环境配置  
**项目版本**: MoonTV v4.1.0-dev  
**文档版本**: v4.1  
**创建时间**: 2025-10-09  
**维护状态**: 持续优化中

## 🛠️ 环境要求

### 系统要求

- **操作系统**: Linux/macOS/Windows 10+
- **Node.js**: 18.0+ (推荐 20.x LTS)
- **包管理器**: pnpm 8.15.0+ (推荐)
- **Git**: 2.30+
- **Docker**: 20.10+ (可选，用于容器化部署)

### 浏览器要求

- **Chrome**: 90+ (推荐)
- **Firefox**: 88+
- **Safari**: 14+
- **Edge**: 90+

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd MoonTV
```

### 2. 安装依赖

```bash
# 使用 pnpm (推荐)
pnpm install

# 或使用 npm
npm install

# 或使用 yarn
yarn install
```

### 3. 环境配置

```bash
# 复制环境变量模板
cp .env.example .env.local

# 编辑环境变量
nano .env.local
```

### 4. 启动开发服务器

```bash
# 开发模式启动
pnpm dev

# 访问应用
# http://localhost:3000
```

## ⚙️ 环境变量配置

### 核心配置

```bash
# ===========================================
# 必需配置 (Required Configuration)
# ===========================================

# 认证密码 - 所有模式下都需要
PASSWORD=yourpassword

# 存储类型选择 (localstorage | redis | upstash | d1)
NEXT_PUBLIC_STORAGE_TYPE=localstorage

# ===========================================
# 存储后端配置 (Storage Backend Configuration)
# ===========================================

# Redis 存储配置 (Docker 部署)
REDIS_URL=redis://localhost:6379

# Upstash 存储配置 (Serverless 部署)
UPSTASH_URL=https://your-project.upstash.io
UPSTASH_TOKEN=your-upstash-token

# Cloudflare D1 配置 (Cloudflare Pages 部署)
# 通过环境变量自动注入，无需手动配置

# ===========================================
# 站点配置 (Site Configuration)
# ===========================================

# 站点显示名称
NEXT_PUBLIC_SITE_NAME=MoonTV

# 管理员用户名 (非 localstorage 模式)
USERNAME=admin

# 允许公开注册
NEXT_PUBLIC_ENABLE_REGISTER=true

# 搜索限制
NEXT_PUBLIC_SEARCH_MAX_PAGE=5

# ===========================================
# 开发配置 (Development Configuration)
# ===========================================

# 开发模式
NODE_ENV=development

# 端口配置
PORT=3000

# 时区配置
TZ=Asia/Shanghai

# ===========================================
# Docker 配置 (Docker Configuration)
# ===========================================

# Docker 环境 (启用动态配置加载)
DOCKER_ENV=true

# 数据持久化目录
DATA_PATH=/app/data

# ===========================================
# 功能开关 (Feature Flags)
# ===========================================

# 启用调试模式
NEXT_PUBLIC_DEBUG=false

# 启用性能监控
NEXT_PUBLIC_ANALYTICS=false

# 启用错误报告
NEXT_PUBLIC_ERROR_REPORTING=false
```

### 环境变量说明

| 变量名                        | 必需 | 默认值         | 说明             |
| ----------------------------- | ---- | -------------- | ---------------- |
| `PASSWORD`                    | ✅   | -              | 应用认证密码     |
| `NEXT_PUBLIC_STORAGE_TYPE`    | ✅   | `localstorage` | 存储后端类型     |
| `REDIS_URL`                   | ❌   | -              | Redis 连接地址   |
| `UPSTASH_URL`                 | ❌   | -              | Upstash 服务地址 |
| `UPSTASH_TOKEN`               | ❌   | -              | Upstash 认证令牌 |
| `NEXT_PUBLIC_SITE_NAME`       | ❌   | `MoonTV`       | 站点显示名称     |
| `USERNAME`                    | ❌   | -              | 管理员用户名     |
| `NEXT_PUBLIC_ENABLE_REGISTER` | ❌   | `false`        | 是否允许注册     |
| `PORT`                        | ❌   | `3000`         | 应用端口         |

## 📦 依赖管理

### 核心依赖

```json
{
  "dependencies": {
    "next": "14.2.5",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "typescript": "^5.5.3",
    "@types/node": "^20.14.11",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "tailwindcss": "^3.4.4",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38"
  },
  "devDependencies": {
    "eslint": "^8.57.0",
    "eslint-config-next": "14.2.5",
    "@typescript-eslint/eslint-plugin": "^7.16.0",
    "@typescript-eslint/parser": "^7.16.0",
    "prettier": "^3.3.3",
    "prettier-plugin-tailwindcss": "^0.6.5"
  }
}
```

### 可选依赖 (按需安装)

```json
{
  "devDependencies": {
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.4.8",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0",
    "@playwright/test": "^1.45.3"
  }
}
```

## 🔧 开发工具配置

### VS Code 配置

```json
// .vscode/settings.json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "files.associations": {
    "*.css": "tailwindcss"
  },
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  }
}
```

### ESLint 配置

```json
// .eslintrc.json
{
  "extends": ["next/core-web-vitals", "@typescript-eslint/recommended"],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "prefer-const": "error",
    "no-var": "error"
  }
}
```

### Prettier 配置

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

### TypeScript 配置

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

## 🐳 Docker 开发环境

### Docker 开发配置

```dockerfile
# Dockerfile.dev
FROM node:20-alpine

WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制依赖文件
COPY package.json pnpm-lock.yaml ./

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动开发服务器
CMD ["pnpm", "dev", "--hostname", "0.0.0.0"]
```

### Docker Compose 开发配置

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=development
      - NEXT_PUBLIC_STORAGE_TYPE=redis
      - REDIS_URL=redis://redis:6379
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.next
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

### 启动 Docker 开发环境

```bash
# 构建并启动开发环境
docker-compose -f docker-compose.dev.yml up --build

# 后台运行
docker-compose -f docker-compose.dev.yml up -d --build

# 停止服务
docker-compose -f docker-compose.dev.yml down
```

## 🧪 测试环境配置

### 单元测试配置

```javascript
// jest.config.js
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testEnvironment: 'jest-environment-jsdom',
};

module.exports = createJestConfig(customJestConfig);
```

### E2E 测试配置

```javascript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## 📝 开发脚本

### package.json 脚本

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "prepare": "husky install",
    "gen:manifest": "node scripts/generate-manifest.js",
    "gen:runtime": "node scripts/generate-runtime.js",
    "pages:build": "next build && cp -r .next out",
    "docker:build": "docker build -t moontv:dev .",
    "docker:run": "docker run -p 3000:3000 moontv:dev"
  }
}
```

### 自定义脚本

#### 生成 PWA Manifest

```javascript
// scripts/generate-manifest.js
const fs = require('fs');
const path = require('path');

const manifest = {
  name: process.env.NEXT_PUBLIC_SITE_NAME || 'MoonTV',
  short_name: 'MoonTV',
  description: 'Next.js 视频聚合播放器',
  start_url: '/',
  display: 'standalone',
  background_color: '#ffffff',
  theme_color: '#000000',
  icons: [
    {
      src: '/icon-192x192.png',
      sizes: '192x192',
      type: 'image/png',
    },
    {
      src: '/icon-512x512.png',
      sizes: '512x512',
      type: 'image/png',
    },
  ],
};

fs.writeFileSync(
  path.join(__dirname, '../public/manifest.json'),
  JSON.stringify(manifest, null, 2)
);
```

#### 生成运行时配置

```javascript
// scripts/generate-runtime.js
const fs = require('fs');
const path = require('path');

// 读取配置文件
const config = require('../config.json');

// 生成运行时配置
const runtimeConfig = `
export const RUNTIME_CONFIG = ${JSON.stringify(config, null, 2)}
`;

fs.writeFileSync(path.join(__dirname, '../src/lib/runtime.ts'), runtimeConfig);
```

## 🔍 调试配置

### VS Code 调试配置

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug server-side",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev"
    },
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000"
    },
    {
      "name": "Next.js: debug full stack",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev",
      "env": {
        "NODE_OPTIONS": "--inspect"
      }
    }
  ]
}
```

### Chrome DevTools 配置

```javascript
// next.config.js
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  webpack: (config, { dev }) => {
    if (dev) {
      config.devtool = 'eval-source-map';
    }
    return config;
  },
};

module.exports = nextConfig;
```

## 📊 性能监控

### 开发性能监控

```javascript
// src/lib/performance.ts
export const performance = {
  // 页面加载性能
  measurePageLoad: () => {
    if (typeof window !== 'undefined' && window.performance) {
      const navigation = window.performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming
      return {
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
        firstPaint: window.performance.getEntriesByType('paint')[0]?.startTime,
        firstContentfulPaint: window.performance.getEntriesByType('paint')[1]?.startTime,
      }
    }
    return null
  },

  // 组件渲染性能
  measureComponentRender: (componentName: string) => {
    const startTime = performance.now()
    return () => {
      const endTime = performance.now()
      console.log(`${componentName} render time: ${endTime - startTime}ms`)
    }
  },
}
```

## 🚨 常见问题解决

### 依赖安装问题

```bash
# 清理缓存
pnpm store prune

# 删除 node_modules 重新安装
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### 端口占用问题

```bash
# 查找端口占用
lsof -i :3000

# 杀死进程
kill -9 <PID>

# 或使用其他端口
pnpm dev --port 3001
```

### TypeScript 错误

```bash
# 重新生成类型
pnpm typecheck

# 清理 Next.js 缓存
rm -rf .next
pnpm dev
```

### Docker 问题

```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建镜像
docker-compose -f docker-compose.dev.yml build --no-cache
```

---

**文档维护**: 开发环境配置随项目更新同步  
**最后更新**: 2025-10-09  
**适用版本**: MoonTV v4.1.0-dev  
**文档状态**: 生产就绪
