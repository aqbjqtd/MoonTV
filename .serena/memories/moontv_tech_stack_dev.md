# MoonTV 技术栈配置 - Dev 版本

> **文档版本**: dev (永久开发版本) | **更新日期**: 2025-10-14 | **技术栈版本**: Next.js 14 + TypeScript 5

## 🏗️ 技术架构概览

### 核心技术栈

```yaml
前端框架:
  Next.js: 14.2.30 (App Router)
  React: 18.2.0
  TypeScript: 4.9.5

运行时环境:
  Edge Runtime (主要)
  Node.js: 24.0.3 (构建时)
  pnpm: 10.14.0 (包管理器)
```

## 📦 依赖包详解

### 生产依赖 (dependencies)

```yaml
# 核心框架
next: 14.2.30              # React 全栈框架
react: ^18.2.0              # React 核心库
react-dom: ^18.2.0          # React DOM 渲染

# UI 组件库
@headlessui/react: ^2.2.4   # 无样式 UI 组件
@heroicons/react: ^2.2.0    # 图标库
framer-motion: ^12.18.1     # 动画库
lucide-react: ^0.438.0      # 现代图标库
react-icons: ^5.4.0         # 丰富图标集

# 样式系统
tailwind-merge: ^2.6.0      # Tailwind 类合并
clsx: ^2.0.0               # 条件类名工具

# 视频播放器
@vidstack/react: ^1.12.13   # 现代视频播放器组件
vidstack: ^0.6.15          # 视频播放器核心
artplayer: ^5.2.5           # 功能强大的视频播放器
hls.js: ^1.6.6             # HTTP Live Streaming 客户端
media-icons: ^1.1.5        # 媒体图标库

# 拖拽排序
@dnd-kit/core: ^6.3.1       # 现代拖拽库核心
@dnd-kit/modifiers: ^9.0.0   # 拖拽修饰符
@dnd-kit/sortable: ^10.0.0   # 排序功能
@dnd-kit/utilities: ^3.2.2   # 拖拽工具

# 存储和缓存
@upstash/redis: ^1.25.0     # Serverless Redis 客户端
redis: ^4.6.7               # Redis 客户端

# 工具库
he: ^1.2.0                 # HTML 实体编解码
zod: ^3.24.1               # 运行时类型验证
glob-to-regexp: ^0.4.1     # Glob 模式转正则

# 用户体验
next-themes: ^0.4.6         # 主题切换
sweetalert2: ^11.11.0       # 美观的弹窗组件
swiper: ^11.2.8             # 现代轮播图组件

# PWA 支持
next-pwa: ^5.6.0           # Next.js PWA 插件
```

### 开发依赖 (devDependencies)

```yaml
# TypeScript 和类型
@types/node: 24.0.3         # Node.js 类型定义
@types/react: ^18.3.18      # React 类型定义
@types/react-dom: ^19.1.6   # React DOM 类型定义
@types/he: ^1.2.3           # HTML 实体编解码类型
@types/aria-query: ^5.0.4   # ARIA 查询类型
@types/testing-library__jest-dom: ^5.14.9  # Jest DOM 类型

# Next.js 生态
@svgr/webpack: ^8.1.0      # SVG 作为组件加载
eslint-config-next: ^14.2.23 # Next.js ESLint 配置
next-router-mock: ^0.9.0    # Next.js 路由模拟

# TypeScript 和 ESLint
typescript: ^4.9.5          # TypeScript 编译器
@typescript-eslint/eslint-plugin: ^5.62.0  # TypeScript ESLint 插件
@typescript-eslint/parser: ^5.62.0         # TypeScript ESLint 解析器
eslint: ^8.57.1             # JavaScript 代码检查
eslint-config-prettier: ^8.10.0  # ESLint + Prettier 兼容
eslint-plugin-simple-import-sort: ^7.0.0   # 导入排序
eslint-plugin-unused-imports: ^2.0.0       # 未使用导入检查

# 样式工具
tailwindcss: ^3.4.17        # Tailwind CSS 框架
autoprefixer: ^10.4.20      # CSS 前缀自动添加
postcss: ^8.5.1             # CSS 后处理器
@tailwindcss/forms: ^0.5.10  # Tailwind 表单样式
prettier: ^2.8.8            # 代码格式化
prettier-plugin-tailwindcss: ^0.5.0  # Tailwind CSS Prettier 插件

# 测试工具
jest: ^27.5.1               # JavaScript 测试框架
@testing-library/react: ^15.0.7  # React 测试工具
@testing-library/jest-dom: ^5.17.0  # Jest DOM 匹配器

# Git 工具
husky: ^7.0.4               # Git hooks
@commitlint/cli: ^16.3.0    # 提交信息检查
@commitlint/config-conventional: ^16.2.4  # 常规提交配置
lint-staged: ^12.5.0        # 暂存文件检查

# 构建工具
@cloudflare/next-on-pages: ^1.13.16  # Cloudflare Pages 适配
```

## 🔧 核心配置文件

### TypeScript 配置 (tsconfig.json)

```json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
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
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/types/*": ["./src/types/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### Next.js 配置 (next.config.js)

```javascript
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
  runtimeCaching: [
    {
      urlPattern: /^https?.*/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'https-calls',
        networkTimeoutSeconds: 15,
        expiration: {
          maxEntries: 150,
          maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
        },
        cacheableResponse: {
          statuses: [0, 200],
        },
      },
    },
  ],
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    runtime: 'edge',
  },
  images: {
    domains: ['localhost'],
    unoptimized: true,
  },
  env: {
    NEXT_PUBLIC_APP_NAME: 'MoonTV',
    NEXT_PUBLIC_APP_VERSION: 'dev',
  },
  webpack: (config, { dev, isServer }) => {
    // Edge Runtime 优化
    if (!dev && !isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }

    // SVG 支持
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack'],
    });

    return config;
  },
  // 构建优化
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
};

module.exports = withPWA(nextConfig);
```

### Tailwind CSS 配置 (tailwind.config.js)

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/typography')],
};
```

### ESLint 配置 (.eslintrc.js)

```javascript
module.exports = {
  extends: [
    'next/core-web-vitals',
    '@typescript-eslint/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint', 'simple-import-sort', 'unused-imports'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    'simple-import-sort/exports': 'error',
    'simple-import-sort/imports': 'error',
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'error',
      {
        vars: 'all',
        varsIgnorePattern: '^_',
        args: 'after-used',
        argsIgnorePattern: '^_',
      },
    ],
  },
  overrides: [
    {
      files: ['*.js', '*.jsx'],
      rules: {
        '@typescript-eslint/no-require-imports': 'off',
      },
    },
  ],
};
```

### Prettier 配置 (.prettierrc)

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

## 🚀 构建配置

### Package.json Scripts 解析

```yaml
开发脚本:
  dev:
    - 生成 PWA manifest
    - 生成运行时配置
    - 启动开发服务器 (0.0.0.0:3000)

  build:
    - 生成 PWA manifest
    - 生成运行时配置
    - 生产环境构建

  start:
    - 启动生产服务器

代码质量:
  lint: ESLint 代码检查
  lint:fix: 自动修复 + 格式化
  lint:strict: 严格模式检查 (0 警告)
  typecheck: TypeScript 类型检查
  format: Prettier 格式化

测试工具:
  test: 运行所有测试
  test:watch: 监视模式测试

实用工具:
  gen:manifest: 生成 PWA manifest.json
  gen:runtime: 从 config.json 生成运行时配置
  pages:build: Cloudflare Pages 构建
```

### 构建优化策略

```yaml
代码分割:
  - 自动路由分割 (Next.js App Router)
  - 动态导入大型依赖
  - 组件级别懒加载

资源优化:
  - 图片自动优化 (next/image)
  - 字体优化 (next/font)
  - 静态资源缓存

Bundle 分析:
  - webpack-bundle-analyzer 集成
  - 依赖大小监控
  - 优化建议生成
```

## 🔒 环境变量配置

### 必需环境变量

```yaml
认证相关:
  PASSWORD: 所有模式必需的认证密码

存储配置:
  NEXT_PUBLIC_STORAGE_TYPE: 存储类型选择
    - localstorage (默认)
    - redis (Docker)
    - upstash (Serverless)
    - d1 (Cloudflare)

存储特定配置:
  REDIS_URL: Redis 连接地址 (redis 模式)
  UPSTASH_URL: Upstash Redis 地址 (upstash 模式)
  UPSTASH_TOKEN: Upstash 认证令牌 (upstash 模式)
  DB: Cloudflare D1 数据库绑定 (Pages 部署)
```

### 可选环境变量

```yaml
站点配置:
  NEXT_PUBLIC_SITE_NAME: 站点显示名称
  USERNAME: 所有者账户 (非 localstorage 模式)
  NEXT_PUBLIC_ENABLE_REGISTER: 允许公开注册
  NEXT_PUBLIC_SEARCH_MAX_PAGE: 每源最大搜索页数

部署特定:
  DOCKER_ENV: 启用动态配置加载 (Docker)
  NODE_ENV: 运行环境 (production/development)
  PORT: 应用端口 (默认 3000)
  TZ: 时区配置 (Asia/Shanghai)

开发工具:
  NEXT_PUBLIC_DEBUG: 调试模式
  NEXT_PUBLIC_ANALYTICS: 分析工具配置
```

## 📊 性能监控配置

### Core Web Vitals 目标

```yaml
性能指标:
  LCP (Largest Contentful Paint): < 2.5s
  FID (First Input Delay): < 100ms
  CLS (Cumulative Layout Shift): < 0.1
  FCP (First Contentful Paint): < 1.8s
  TTFB (Time to First Byte): < 800ms
  INP (Interaction to Next Paint): < 200ms
```

### 性能优化配置

```yaml
构建优化:
  - SWC 压缩和优化
  - Tree shaking 移除无用代码
  - CSS 代码分割和压缩

运行时优化:
  - Edge Runtime 冷启动优化
  - 智能缓存策略
  - 预加载关键资源

监控集成:
  - Vercel Analytics (可选)
  - 自定义性能监控
  - 错误边界和日志收集
```

## 🔧 开发工具集成

### VS Code 推荐配置

```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-typescript-next",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-json"
  ]
}
```

### Git Hooks 配置

```yaml
Pre-commit hooks:
  - lint-staged: 检查暂存文件
  - ESLint: 代码质量检查
  - Prettier: 代码格式化

Pre-push hooks:
  - TypeScript 类型检查
  - 单元测试运行
  - 构建验证

Commit message:
  - Commitlint: 提交信息规范检查
  - Conventional Commits: 标准化提交格式
```

## 🚀 部署适配配置

### Docker 构建优化

```yaml
多阶段构建:
  - 基础环境: Node.js + pnpm
  - 依赖安装: 缓存优化
  - 应用构建: 生产环境优化
  - 运行时: 最小化镜像

BuildKit 特性:
  - 内联缓存: --cache-from
  - 并行构建: --build-arg
  - 安全扫描: 内置安全检查
```

### Serverless 适配

```yaml
Vercel 配置:
  - vercel.json: 构建和路由配置
  - Edge Functions: API 路由优化
  - 环境变量管理

Cloudflare Pages:
  - _headers: 自定义头部
  - _redirects: URL 重写规则
  - Functions: 边缘函数配置
```

## 📈 技术债务管理

### 版本更新策略

```yaml
主要依赖:
  - Next.js: 跟随稳定版本
  - React: 18.x 系列最新
  - TypeScript: 5.x 系列最新

依赖更新频率:
  - 每月检查安全和更新
  - 季度主要版本升级
  - 年度技术栈评估
```

### 安全维护

```yaml
依赖扫描:
  - npm audit: 自动安全检查
  - Snyk 集成: 漏洞监控
  - GitHub Dependabot: 自动 PR

最佳实践:
  - 定期更新依赖
  - 安全补丁优先
  - 破坏性变更评估
```

---

**技术栈特点**: 现代化、高性能、企业级
**维护策略**: 持续更新、安全优先、性能优化
**文档更新**: 2025-10-14
**版本**: dev (永久开发版本)
