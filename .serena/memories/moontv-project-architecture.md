# MoonTV项目架构总结

## 项目概览
MoonTV是一个基于Next.js的流媒体Web应用，使用TypeScript构建，支持用户认证、媒体播放、收藏管理等功能。

## 技术栈
- **前端框架**: Next.js 14.2.30 (React 18.2.0)
- **开发语言**: TypeScript 4.9.5
- **样式方案**: TailwindCSS 3.4.17
- **包管理器**: pnpm 10.14.0
- **媒体播放**: ArtPlayer 5.2.5, HLS.js 1.6.6
- **状态管理**: React hooks + 上下文
- **UI组件**: 自定义组件 + Lucide React图标

## 核心功能模块

### 用户系统
- **登录认证**: /api/login, /api/logout
- **密码管理**: /api/change-password
- **用户注册**: /api/register
- **权限控制**: 管理员后台 (/admin)

### 内容管理
- **媒体播放**: /play页面，支持HLS流
- **搜索功能**: /search页面，支持资源搜索
- **收藏系统**: /api/favorites
- **播放记录**: /api/playrecords

### 数据源
- **豆瓣集成**: /douban页面，/api/douban/*
- **媒体源管理**: 管理员后台配置
- **图片代理**: /api/image-proxy

### 系统功能
- **定时任务**: /api/cron
- **配置管理**: /api/server-config
- **健康检查**: /api/health
- **PWA支持**: Service Worker + Manifest

## 项目结构

### 关键目录
- **src/app/**: Next.js 13+ App Router页面
- **src/components/**: React组件库
- **src/lib/**: 工具库和配置
- **public/**: 静态资源
- **scripts/**: 构建脚本

### 重要文件
- **src/lib/runtime.ts**: 动态生成的运行时配置
- **manifest.json**: PWA应用清单
- **config.json**: 应用配置文件
- **start.js**: 生产环境启动脚本

## Docker部署

### 构建配置
- **多阶段构建**: 4阶段优化构建
- **基础镜像**: node:20-alpine
- **输出模式**: Next.js standalone
- **安全配置**: 非root用户运行
- **健康检查**: 内置健康监控

### 环境变量
- **PASSWORD**: 管理员密码
- **NODE_ENV**: production
- **DOCKER_ENV**: Docker环境标识
- **NEXT_PUBLIC_SITE_NAME**: 站点名称

## 依赖特点

### 生产依赖 (56个)
- **核心**: next, react, react-dom
- **媒体**: artplayer, hls.js, @vidstack/react, vidstack
- **UI**: lucide-react, @headlessui/react, framer-motion
- **图标**: react-icons, @heroicons/react, media-icons
- **工具**: zod, clsx, tailwind-merge, sweetalert2
- **拖拽**: @dnd-kit/* 系列
- **主题**: next-themes
- **数据库**: @upstash/redis, redis

### 开发依赖 (28个)
- **TypeScript**: @types/* 系列
- **代码质量**: eslint, prettier, @typescript-eslint/*
- **测试**: jest, @testing-library/*
- **构建**: @svgr/webpack, tailwindcss, autoprefixer
- **Git**: husky, @commitlint/*, lint-staged

## 重要技术决策

### 1. Edge Runtime → Node Runtime
- **原因**: Edge Runtime限制较多，不支持完整Node.js API
- **实现**: 自动替换route.ts中的runtime配置
- **影响**: 提高了兼容性，支持更多功能

### 2. 动态配置生成
- **机制**: scripts/convert-config.js生成runtime.ts
- **优势**: 支持Docker环境变量动态配置
- **文件**: src/lib/runtime.ts (运行时生成)

### 3. PWA支持
- **配置**: next-pwa插件
- **功能**: 离线支持、安装到桌面
- **文件**: public/sw.js, public/manifest.json

### 4. 多阶段构建优化
- **目标**: 减少镜像体积
- **策略**: 分离构建和运行时环境
- **结果**: 从完整构建优化到生产环境

## 性能特点

### 构建性能
- **构建时间**: 约2分钟（完整依赖安装）
- **镜像体积**: 1.37GB (完整功能)
- **启动时间**: 约278ms

### 运行时性能
- **内存使用**: 中等（Node.js + Next.js）
- **响应速度**: 快速（SSR + 静态优化）
- **并发处理**: 良好（Next.js优化）

## 安全考虑

### 容器安全
- **非root用户**: nextjs用户（UID 1001）
- **最小权限**: 只必要的系统包
- **健康检查**: 内置监控机制

### 应用安全
- **输入验证**: Zod schema验证
- **认证授权**: 基于token的认证
- **环境变量**: 敏感配置隔离
- **CORS**: API访问控制

## 扩展性

### 水平扩展
- **无状态设计**: 支持多实例部署
- **外部存储**: Redis用于缓存和会话
- **负载均衡**: 可使用标准Web服务器

### 功能扩展
- **插件化**: 模块化的数据源设计
- **主题系统**: 支持动态主题切换
- **API设计**: RESTful接口，易于集成