# MoonTV 项目核心信息 v4.0.0

**项目名称**: MoonTV
**版本**: v4.0.0 (标准四阶段构建)
**更新日期**: 2025-10-08
**项目类型**: Next.js 14 App Router 跨平台视频聚合播放器

## 🎯 项目概述

MoonTV 是一个基于 Next.js 14 App Router 的现代化跨平台视频聚合播放器，支持 20+ 视频 API 源聚合，具备多存储后端支持、双模配置系统和双模认证机制。

### 核心特性

- 🔌 **插件化存储**: localstorage/redis/upstash/d1 可切换
- 🔄 **双模配置**: 静态 config.json + 动态数据库配置
- 🔒 **双模认证**: 密码模式 + 用户名/密码/HMAC 模式
- 🌊 **流式搜索**: WebSocket 实时多源并行搜索
- ⚡ **Edge Runtime**: 所有 API 路由支持边缘计算

## 🏗️ 技术架构

### 前端技术栈

- **框架**: Next.js 14 App Router
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **状态管理**: React Hooks + Context API
- **UI 组件**: Headless UI + Heroicons + 自定义组件

### 后端技术栈

- **运行时**: Node.js 20 + Edge Runtime
- **API 设计**: RESTful API + WebSocket
- **数据库**: Redis / Upstash / Cloudflare D1 / LocalStorage
- **缓存**: 内置多级缓存机制

### 部署架构

- **容器化**: Docker 标准四阶段构建
- **部署平台**: Docker, Vercel, Netlify, Cloudflare Pages
- **存储后端**: 支持多种存储方案的灵活切换

## 📁 项目结构

```
MoonTV/
├── src/                      # 应用源代码
│   ├── app/                  # Next.js 14 App Router
│   ├── components/           # React 组件
│   ├── lib/                  # 工具库和配置
│   └── styles/               # 样式文件
├── public/                   # 静态资源
├── scripts/                  # 构建和部署脚本
├── claudedocs/              # Claude 相关文档
├── Dockerfile               # 标准四阶段构建
├── docker-compose.yml       # 容器编排配置
├── package.json            # 项目依赖和脚本
├── config.json             # 主配置文件
├── VERSION.txt              # 版本信息
└── *.config.js             # 各种配置文件
```

## 🔧 核心配置

### 环境变量

```bash
# 存储配置
NEXT_PUBLIC_STORAGE_TYPE=localstorage|redis|upstash|d1

# Redis 配置
REDIS_URL=redis://redis:6379

# Upstash 配置
UPSTASH_URL=https://your-upstash-url
UPSTASH_TOKEN=your-upstash-token

# 认证配置
PASSWORD=admin
USERNAME=admin
NEXT_PUBLIC_ENABLE_REGISTER=false

# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_SEARCH_MAX_PAGE=5

# Docker 环境
DOCKER_ENV=true
NODE_ENV=production
```

### 存储类型配置

- **localstorage**: 浏览器本地存储，无需服务器
- **redis**: Redis 数据库，需要 Redis 服务器
- **upstash**: Upstash Redis 云服务，适合 Serverless
- **d1**: Cloudflare D1 SQLite，仅限 Cloudflare Pages

### 认证模式配置

- **localstorage 模式**: 仅密码认证
- **数据库模式**: 用户名/密码 + HMAC 签名认证

## 🚀 开发命令

### 基础开发

```bash
# 开发服务器
pnpm dev

# 生产构建
pnpm build

# 生产启动
pnpm start

# 代码质量检查
pnpm lint
pnpm lint:fix
pnpm typecheck

# 代码格式化
pnpm format
```

### Docker 构建

```bash
# 标准四阶段构建
docker build -t moontv:latest .

# 多架构构建
docker buildx build --platform linux/amd64,linux/arm64 -t moontv:multi-arch .

# 运行容器
docker run -d -p 3000:3000 --name moontv moontv:latest
```

### 验证测试

```bash
# Docker 构建验证
./scripts/docker-four-stage-test.sh

# 版本检查验证
./scripts/test-version-check.sh
```

## 📊 性能指标

### 构建性能 (v4.0.0)

- **镜像大小**: ~200MB (较传统构建减少 37%)
- **构建时间**: ~2.5 分钟 (BuildKit 优化提升 33%)
- **缓存命中率**: ~90%+ (四阶段缓存优化)
- **安全评分**: 9/10 (Distroless 加固)

### 运行时性能

- **启动时间**: ~20 秒 (较 v3.2.0 提升 33%)
- **内存使用**: ~27MB (较 v3.2.0 减少 23%)
- **健康检查**: 企业级轻量级检查机制

## 🔒 安全特性

### Docker 安全

- **最小化运行时**: Distroless 无系统工具
- **非特权用户**: UID 1001 非 root 运行
- **精简镜像**: 仅包含运行时必需组件
- **健康检查**: 内置安全健康检查机制

### 应用安全

- **输入验证**: 严格的输入验证和过滤
- **CORS 配置**: 完善的跨域资源共享配置
- **认证授权**: 多层次认证和授权机制
- **数据加密**: 敏感数据传输和存储加密

## 📚 API 集成

### 视频源支持

- **Apple CMS V10**: 主要视频源格式
- **自定义扩展**: 支持自定义 API 源集成
- **配置管理**: 通过 admin 界面管理 API 源

### 搜索功能

- **并行搜索**: 多源并行搜索提升效率
- **实时更新**: WebSocket 实时推送搜索结果
- **缓存优化**: 智能缓存减少重复请求

## 🔄 版本管理

### 版本策略

- **语义化版本**: 遵循 SemVer 规范
- **自动检查**: 内置版本更新检测机制
- **上游同步**: 与上游仓库版本保持一致

### 当前版本

- **应用版本**: v3.2.0 (与上游同步)
- **npm 包版本**: 0.1.0 (独立管理)
- **Docker 镜像版本**: v4.0.0 (标准四阶段构建)

## 📈 监控和维护

### 健康检查

- **API 健康检查**: `/api/health` 端点
- **容器健康检查**: Docker 内置健康检查
- **日志监控**: 结构化日志记录

### 维护工具

- **代码质量**: ESLint + Prettier + TypeScript
- **测试覆盖**: Jest 测试框架
- **构建验证**: 自动化构建和部署验证

## 🎯 最佳实践

### 开发最佳实践

- **类型安全**: 全面使用 TypeScript
- **代码规范**: 严格的 ESLint 和 Prettier 规则
- **组件化**: 模块化组件设计
- **性能优化**: 代码分割和懒加载

### 部署最佳实践

- **容器化**: 标准化 Docker 构建流程
- **环境隔离**: 开发/测试/生产环境分离
- **配置管理**: 环境变量和配置文件分离
- **监控告警**: 全面的监控和告警机制

---

**最后更新**: 2025-10-08
**维护状态**: ✅ 活跃维护
**文档版本**: v4.0.0
**技术栈**: Next.js 14 + TypeScript + Docker
