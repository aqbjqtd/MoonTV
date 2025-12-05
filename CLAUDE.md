# MoonTV - Claude Code 项目指南

**项目类型**: 开源视频聚合平台
**技术栈**: Next.js 14.2.30 + TypeScript 4.9.5 + 多存储抽象
**当前版本**: v3.4.2
**最后更新**: 2025-11-25

---

## 🎯 项目核心架构

### 技术架构特征

```yaml
架构模式: 全栈Web应用 (JAMstack架构)
渲染策略: Edge-First + Fallback (边缘优先)
运行时: Edge Runtime (优先) + Node.js Runtime (降级)
存储模式: 多后端抽象 (统一IStorage接口)
部署模式: 多平台部署 (Docker/Vercel/Cloudflare/自托管)
```

### 核心技术栈

- **前端框架**: Next.js 14.2.30 (App Router) + React 18.2.0
- **开发语言**: TypeScript 4.9.5 (严格模式)
- **样式框架**: Tailwind CSS 3.4.17 + Headless UI 2.2.4
- **播放器**: ArtPlayer 5.2.5 + HLS.js 1.6.6 + Vidstack 0.6.15
- **状态管理**: React Context API + SWR/React Query
- **包管理**: pnpm 10.14.0

### 存储抽象层设计

```typescript
// 核心存储接口 - 支持多种后端
interface IStorage {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
  mget<T>(keys: string[]): Promise<(T | null)[]>;
  mset<T>(entries: Array<[string, T]>): Promise<void>;
  // ... 更多方法
}

// 支持的存储后端:
// - LocalStorage (浏览器本地存储)
// - Redis 4.6.7 (自托管缓存)
// - Upstash Redis 1.25.0 (云端缓存)
// - Cloudflare D1 (无服务器SQLite)
```

---

## 🏗️ 项目目录结构

### 核心目录架构

```
MoonTV/
├── src/
│   ├── app/                    # Next.js 14 App Router页面
│   │   ├── api/               # API路由 (40+ RESTful端点)
│   │   │   ├── search/        # 搜索API (批量/单源/WebSocket)
│   │   │   ├── detail/        # 播放详情API
│   │   │   ├── admin/         # 管理面板API
│   │   │   ├── douban/        # 豆瓣数据API
│   │   │   └── tvbox/         # TVBox配置API
│   │   ├── admin/             # 管理面板页面
│   │   ├── search/            # 搜索页面
│   │   ├── play/              # 播放页面
│   │   └── douban/            # 豆瓣数据页面
│   ├── components/            # React组件库 (30+组件)
│   │   ├── VideoCard.tsx      # 视频卡片组件
│   │   ├── EpisodeSelector.tsx # 剧集选择器
│   │   ├── SearchSuggestions.tsx # 搜索建议
│   │   └── *Provider.tsx      # Context Provider组件
│   ├── lib/                   # 核心业务逻辑库
│   │   ├── config.ts          # 配置管理系统
│   │   ├── storage.types.ts   # 存储抽象层定义
│   │   ├── db.ts              # 数据库连接管理
│   │   ├── auth.ts            # 认证授权逻辑
│   │   ├── douban.ts          # 豆瓣数据集成
│   │   └── logger.ts          # 日志系统
│   └── styles/                # 样式文件 (Tailwind CSS)
├── public/                    # 静态资源
├── scripts/                   # 构建和部署脚本
└── docker相关文件              # Docker部署配置
```

### API 架构设计

```yaml
核心业务API (/api):
  - /api/search/* # 视频搜索 (批量/单源/WebSocket/建议)
  - /api/detail/* # 播放详情获取
  - /api/login|logout|register # 用户认证
  - /api/favorites|playrecords # 用户数据

内容管理API (/api/admin/*):
  - /api/admin/user # 用户管理
  - /api/admin/source # 视频源管理
  - /api/admin/site # 站点配置
  - /api/admin/tvbox # TVBox配置管理
  - /api/admin/data_migration/* # 数据迁移工具

外部集成API:
  - /api/douban/* # 豆瓣数据集成
  - /api/tvbox/* # TVBox生态对接
  - /api/image-proxy # 图片代理服务
```

---

## 🔧 开发工作流

### 核心开发命令

```bash
# 开发环境 (监听所有网络接口)
pnpm dev                    # 启动开发服务器 0.0.0.0:3000

# 构建相关
pnpm build                  # 生产构建 (包含manifest和runtime生成)
pnpm start                  # 启动生产服务器
pnpm pages:build           # Cloudflare Pages构建

# 代码质量检查
pnpm lint                   # ESLint代码检查
pnpm lint:fix              # 自动修复代码问题
pnpm lint:strict           # 严格模式检查 (max-warnings=0)
pnpm typecheck             # TypeScript类型检查
pnpm format                # Prettier代码格式化

# 测试
pnpm test                  # Jest单元测试
pnpm test:watch            # 测试监听模式

# 代码生成
pnpm gen:manifest          # PWA清单生成
pnpm gen:runtime           # 运行时配置生成
```

### 代码质量保证

```yaml
代码规范:
  - ESLint (next config + typescript rules)
  - Prettier (代码格式化)
  - Husky (Git hooks)
  - lint-staged (提交前检查)
  - commitlint (提交信息规范)

TypeScript配置:
  - 严格模式启用
  - 路径别名配置 (@/ 映射到 src/)
  - 类型覆盖率 >95%
  - 增量编译支持

构建优化:
  - 自动代码分割
  - Tree Shaking
  - 图片优化 (WebP支持)
  - 字体优化
  - Gzip/Brotli压缩
```

---

## 🚀 部署配置

### 多平台部署支持

```yaml
Docker部署 (推荐):
  - 镜像: ghcr.io/stardm0/moontv:latest (313MB)
  - 运行: 非特权用户 (UID: 1001)
  - 存储: 环境变量配置存储后端
  - 健康检查: 内置健康检查机制

Vercel部署 (零配置):
  - 自动CI/CD集成
  - 边缘计算支持
  - 全球CDN分发
  - 预览环境隔离

Cloudflare Pages部署 (边缘计算):
  - D1数据库集成
  - 边缘函数支持
  - 构建命令: pnpm pages:build
  - 兼容性标志: nodejs_compat

自托管部署:
  - Node.js 20.x环境
  - 反向代理: Nginx推荐
  - 进程管理: PM2推荐
  - SSL证书自动配置
```

### 关键环境变量

```yaml
核心配置:
  PASSWORD                 # 管理员密码 (必需)
  USERNAME                 # 管理员用户名
  NEXT_PUBLIC_SITE_NAME    # 站点名称
  NEXT_PUBLIC_STORAGE_TYPE # 存储类型 (localstorage/redis/upstash/d1)

存储配置:
  REDIS_URL               # Redis连接URL
  UPSTASH_URL            # Upstash Redis URL
  UPSTASH_TOKEN          # Upstash Redis Token

功能配置:
  NEXT_PUBLIC_ENABLE_REGISTER  # 是否开放用户注册
  NEXT_PUBLIC_SEARCH_MAX_PAGE  # 搜索最大页数 (1-50)
  TVBOX_ENABLED               # TVBox接口开关 (默认true)

豆瓣集成:
  NEXT_PUBLIC_DOUBAN_PROXY_TYPE        # 豆瓣数据代理类型
  NEXT_PUBLIC_DOUBAN_PROXY            # 自定义豆瓣代理URL
  NEXT_PUBLIC_DOUBAN_IMAGE_PROXY_TYPE  # 豆瓣图片代理类型
```

---

## 🎨 核心功能特性

### 视频聚合系统

```yaml
搜索能力:
  - 20+视频源并行搜索
  - Apple CMS V10 API标准
  - 流式搜索 (WebSocket支持)
  - 智能缓存 (7200秒TTL)
  - 失败源过滤和重试机制

播放系统:
  - HLS流媒体播放
  - ArtPlayer + HLS.js + Vidstack
  - 播放进度同步
  - 剧集列表管理
  - 跳过片头片尾 (实验性)
```

### 存储和管理系统

```yaml
多存储后端:
  - LocalStorage: 5-10MB本地存储
  - Redis: 高性能内存缓存
  - Upstash Redis: 云端分布式缓存
  - Cloudflare D1: 边缘SQLite数据库

数据迁移:
  - 增量迁移支持
  - 分批处理避免内存溢出
  - 数据完整性验证
  - 断点续传和回滚机制
```

### 集成生态

```yaml
TVBox集成:
  - 动态配置生成: /api/tvbox/config
  - 密码保护访问
  - 标准TVBox配置格式
  - 移动播放器兼容

豆瓣数据集成:
  - 5种代理配置选项
  - 电影元数据丰富
  - 评分/评论/演员信息
  - 自定义分类支持
  - CDN图片优化

PWA功能:
  - Service Worker离线支持
  - 桌面安装提示
  - 移动端原生体验
  - 自动生成manifest
```

---

## 🔒 安全架构

### 认证授权机制

```yaml
认证方式:
  - Cookie-based会话管理
  - bcrypt密码哈希 (成本因子12)
  - 会话超时机制
  - 多设备登录支持

权限模型:
  - 管理员权限: 用户管理/视频源管理/系统配置
  - 普通用户权限: 搜索播放/个人数据管理
  - TVBox接口: 密码保护访问
```

### 数据安全保护

```yaml
传输安全:
  - HTTPS/TLS 1.3强制加密
  - 安全HTTP头部设置
  - CORS跨域保护

数据保护:
  - 输入验证和XSS防护
  - CSRF Token验证
  - SQL注入防护
  - 敏感数据字段加密
```

---

## 📊 性能优化策略

### 前端性能优化

```yaml
代码优化:
  - React组件记忆化 (React.memo)
  - 计算结果缓存 (useMemo)
  - 函数引用稳定 (useCallback)
  - 虚拟列表长列表优化

资源优化:
  - 图片懒加载和WebP支持
  - 字体预加载和显示策略
  - 关键资源预加载
  - Service Worker缓存策略
```

### 后端性能优化

```yaml
缓存策略:
  - 多层缓存架构 (L1:浏览器/L2:CDN/L3:应用)
  - 热点数据预加载
  - 智能缓存失效

API优化:
  - 异步编程模式
  - 批量操作支持
  - 连接池复用
  - 响应压缩 (Gzip/Brotli)
```

---

## 🛠️ 重要开发约定

### 代码组织原则

```yaml
组件设计:
  - 单一职责原则 (SRP)
  - 函数组件 + Hooks优先
  - Props接口严格定义
  - 错误边界处理

API设计:
  - RESTful风格
  - 统一错误响应格式
  - 请求参数严格验证
  - API版本控制支持

存储使用:
  - 优先使用存储抽象层
  - 数据操作原子性
  - 缓存策略一致性
  - 错误处理和降级
```

### Git 工作流

```yaml
分支策略:
  - main: 生产分支
  - dev: 开发分支
  - feature/*: 功能分支

提交规范:
  - feat: 新功能
  - fix: 修复
  - docs: 文档
  - style: 格式化
  - refactor: 重构
  - test: 测试
```

---

## 📈 项目特色亮点

### 技术创新

- **Edge-First 架构**: 边缘计算优先，全球化性能
- **存储抽象设计**: 统一接口支持多种后端
- **流式搜索**: WebSocket 实时搜索体验
- **PWA 集成**: 原生应用级别的用户体验

### 开发友好

- **完整类型定义**: TypeScript 严格模式
- **现代化工具链**: pnpm + ESLint + Prettier + Husky
- **多部署方案**: 4 种部署选择，适应不同场景
- **详细文档**: 完善的开发和部署文档

### 生态集成

- **TVBox 兼容**: 扩展播放设备支持
- **豆瓣数据**: 丰富的电影元数据
- **拖拽排序**: 现代化交互体验
- **数据迁移**: 完整的跨存储迁移方案

---

## 🎯 开发注意事项

### 重要提醒

1. **存储后端切换**: 使用内置数据迁移工具，避免数据丢失
2. **环境变量配置**: 部署前检查必需的环境变量设置
3. **API 安全**: 生产环境必须设置密码保护
4. **缓存策略**: 合理设置缓存时间，平衡性能和实时性

### 调试技巧

```bash
# 查看存储类型和配置
curl http://localhost:3000/api/server-config

# 测试搜索API
curl "http://localhost:3000/api/search?wd=测试关键词"

# 检查TVBox配置
curl "http://localhost:3000/api/tvbox/config?pwd=密码"
```

---

**项目维护状态**: 🚀 生产就绪，活跃开发中
**文档版本**: v1.0.0
**最后更新**: 2025-11-25
**技术支持**: 通过 GitHub Issues 获取帮助

这个 CLAUDE.md 文件为未来的 Claude Code 实例提供了项目架构、开发流程、部署配置和核心特性的全面指导，确保快速理解和高效开发。
