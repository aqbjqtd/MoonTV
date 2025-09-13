# MoonTV 项目当前状态快照

## 📅 最后更新: 2025-09-13

### 🎯 项目状态概览

- **项目名称**: MoonTV
- **当前版本**: v1.1.1
- **开发状态**: 稳定版本，功能完整
- **当前分支**: master
- **最新提交**: e187d53

### 🔧 技术栈

- **框架**: Next.js 14.2.23 (React 18.2.0)
- **语言**: TypeScript
- **包管理**: pnpm (已配置，但构建使用直接 node 执行)
- **样式**: Tailwind CSS
- **部署**: Docker 多阶段构建

### 📦 核心依赖

- **视频播放**: @vidstack/react, artplayer, hls.js
- **UI 组件**: @headlessui/react, @heroicons/react, lucide-react
- **动画**: framer-motion
- **拖拽**: @dnd-kit 系列
- **主题**: next-themes
- **PWA**: next-pwa

### 🐳 Docker 部署信息

- **镜像大小**: 1.37GB (稳定版本)
- **目标大小**: 300MB (优化尝试中，当前保持稳定)
- **运行命令**: `docker run -d --name moontv -p 9000:3000 --env PASSWORD=123456 aqbjqtd/moontv:test`
- **健康检查**: http://localhost:9000/api/health

### 📁 项目结构

```
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/health/        # 健康检查 API
│   │   ├── layout.tsx         # 根布局
│   │   └── page.tsx           # 主页
│   ├── components/             # React 组件
│   ├── lib/                   # 工具库和配置
│   └── styles/                # 样式文件
├── scripts/                   # 构建脚本
│   ├── convert-config.js      # 配置转换
│   ├── generate-manifest.js   # Manifest 生成
│   └── optimize-deps.js      # 依赖分析
├── public/                    # 静态资源
├── config.json               # 应用配置
├── Dockerfile               # Docker 构建配置
├── Dockerfile.v2-optimized  # 优化版本 (备用)
├── docker-compose.yml       # Docker Compose 配置
└── .serena/                  # 项目记忆和知识库
```

### 🚀 主要功能

- ✅ 视频流播放 (HLS 支持)
- ✅ 用户认证系统
- ✅ 响应式 UI 设计
- ✅ 深色/浅色主题切换
- ✅ PWA 支持
- ✅ 健康检查 API
- ✅ Docker 容器化部署

### 📊 版本控制状态

- **本地分支**: master (当前), main
- **远程分支**: main, master
- **标签**: v1.1.1 (最新)
- **GitHub 同步**: ✅ 完全同步
- **仓库 URL**: https://github.com/aqbjqtd/MoonTV

### 🔍 GitHub 仓库状态

- **最新提交**: e187d53 docs: 更新项目记忆和优化文档
- **分支状态**: main 和 master 已同步
- **Release**: v1.1.1 已发布
- **清理操作**: 已删除旧标签和分支

### 📝 重要配置文件

- **next.config.js**: Next.js 配置，包含 PWA 和图片优化
- **package.json**: 项目依赖和脚本配置
- **tsconfig.json**: TypeScript 配置
- **tailwind.config.js**: Tailwind CSS 配置

### 🛠️ 开发环境

- **启动命令**: `npm run dev` 或 `node scripts/convert-config.js && node scripts/generate-manifest.js && next dev -H 0.0.0.0`
- **构建命令**: `npm run build` 或 `node scripts/convert-config.js && node scripts/generate-manifest.js && next build`
- **环境要求**: Node.js 20.x

### 🔐 安全特性

- ✅ 非 root 用户运行 (Docker)
- ✅ 环境变量注入
- ✅ 健康检查端点
- ✅ 信号处理 (dumb-init)
- ✅ 容器端口映射

### 📈 性能优化

- ✅ 多阶段 Docker 构建
- ✅ 依赖分析和优化建议
- ✅ 图片优化配置
- ✅ SWC 压缩
- ✅ PWA 缓存策略

### 🔄 构建流程

1. **配置转换**: `scripts/convert-config.js`
2. **Manifest 生成**: `scripts/generate-manifest.js`
3. **Next.js 构建**: `next build`
4. **Docker 镜像构建**: 多阶段构建
5. **容器部署**: Docker 或 Docker Compose

### 🎨 UI/UX 特性

- ✅ 现代化设计系统
- ✅ 响应式布局
- ✅ 主题切换支持
- ✅ 无障碍访问优化
- ✅ 流畅的动画效果
- ✅ 拖拽交互支持

### 📱 PWA 功能

- ✅ 离线支持
- ✅ 添加到主屏幕
- ✅ 推送通知 (配置中)
- ✅ Service Worker 缓存

### 🚨 监控和日志

- ✅ 健康检查 API
- ✅ 容器状态监控
- ✅ 应用日志记录
- ✅ 错误处理机制

### 📚 文档和知识库

- ✅ 项目记忆系统 (.serena/)
- ✅ Docker 部署指南
- ✅ 优化建议文档
- ✅ GitHub 管理记录
- ✅ 当前状态快照 (本文件)

### 🎯 后续计划

- 🔄 持续优化 Docker 镜像大小
- 🚀 性能监控和优化
- 📱 移动端体验改进
- 🔐 安全功能增强
- 📊 分析和监控工具集成
