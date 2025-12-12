# MoonTV 技术架构

**记忆类型**: 技术架构  
**创建时间**: 2025-12-12  
**最后更新**: 2025-12-12  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 项目概览, 开发规范, 功能模块  
**语义标签**: 技术栈, 架构设计, 依赖关系, 系统设计  
**索引关键词**: Next.js, TypeScript, Tailwind, 存储抽象, API 设计, 安全架构

## 概述

MoonTV 采用现代化的全栈 Web 应用架构，基于 Next.js 14 的 App Router 模式，结合 TypeScript 类型安全和 Tailwind CSS 样式系统，构建高性能、可扩展的影视聚合播放平台。

## 核心技术栈

### 前端框架

- **Next.js 14.2.30**: 全栈 React 框架，App Router 架构
- **TypeScript 4.9.5**: 静态类型检查，严格模式启用
- **React 18.2.0**: 前端 UI 库，支持并发特性
- **Tailwind CSS 3.4.17**: 实用优先的 CSS 框架

### 核心依赖库

#### UI 组件和动画

- **Framer Motion 12.18.1**: 高性能动画库
- **Lucide React 0.438.0**: 现代化图标库
- **@headlessui/react 2.2.4**: 无头 UI 组件
- **Swiper 11.2.8**: 触摸友好的轮播组件
- **SweetAlert2 11.11.0**: 美观的弹窗组件

#### 播放器相关

- **ArtPlayer 5.2.5**: 主播放器，支持 HLS 和弹幕
- **HLS.js 1.6.6**: HLS 流媒体协议支持
- **Vidstack 0.6.15**: 现代 Web 组件播放器
- **@vidstack/react 1.12.13**: React 封装的 Vidstack 组件

#### 工具和状态管理

- **Zod 3.24.1**: TypeScript 优先的数据验证
- **clsx 2.0.0**: 条件类名工具
- **tailwind-merge 2.6.0**: Tailwind 类合并工具
- **next-themes 0.4.6**: Next.js 主题切换

#### 存储后端

- **Redis 4.6.7**: 本地 Redis 客户端
- **@upstash/redis 1.25.0**: Upstash Redis 客户端
- **crypto-js 4.2.0**: JavaScript 加密库

### 开发工具

- **ESLint 8.57.1**: 代码质量检查
- **Prettier 2.8.8**: 代码格式化
- **Jest 27.5.1**: 测试框架
- **Husky 7.0.4**: Git hooks 管理
- **lint-staged 12.5.0**: 提交前代码检查

## 架构设计

### 整体架构模式

```
┌─────────────────────────────────────────────┐
│               用户界面层                    │
│   (React组件, Tailwind样式, 页面路由)      │
├─────────────────────────────────────────────┤
│               业务逻辑层                    │
│   (API路由, 数据验证, 业务规则)            │
├─────────────────────────────────────────────┤
│               数据访问层                    │
│   (存储抽象接口, 多种后端实现)              │
├─────────────────────────────────────────────┤
│               存储后端层                    │
│   (LocalStorage, Redis, Upstash, D1)       │
└─────────────────────────────────────────────┘
```

### 存储抽象层设计

#### 核心存储接口

```typescript
interface IStorage {
  // 播放记录管理
  getPlayRecord(userName: string, key: string): Promise<PlayRecord | null>;
  setPlayRecord(
    userName: string,
    key: string,
    record: PlayRecord
  ): Promise<void>;
  getAllPlayRecords(userName: string): Promise<{ [key: string]: PlayRecord }>;

  // 收藏管理
  getFavorite(userName: string, key: string): Promise<Favorite | null>;
  setFavorite(userName: string, key: string, favorite: Favorite): Promise<void>;
  getAllFavorites(userName: string): Promise<{ [key: string]: Favorite }>;

  // 用户管理
  registerUser(userName: string, password: string): Promise<void>;
  verifyUser(userName: string, password: string): Promise<boolean>;
  checkUserExist(userName: string): Promise<boolean>;
}
```

#### 支持的存储后端

1. **LocalStorage 后端**: 浏览器本地存储，适合单用户场景
2. **Redis 后端**: 自托管 Redis，适合多用户场景
3. **Upstash 后端**: 云端 Redis 服务，无需运维
4. **D1 后端**: Cloudflare D1 数据库，无服务器 SQLite

### API 架构设计

#### RESTful API 设计原则

- 资源使用复数名词 (如 `/api/users`, `/api/videos`)
- HTTP 方法语义化 (GET 获取，POST 创建，PUT 更新，DELETE 删除)
- 统一响应格式和错误处理
- 版本控制支持 (`/api/v1/` 前缀)

#### 主要 API 分类

##### 核心业务 API

- `/api/search/*` - 视频搜索 (批量/单源/WebSocket/建议)
- `/api/detail/*` - 播放详情获取
- `/api/login|logout|register` - 用户认证
- `/api/favorites|playrecords` - 用户数据管理

##### 内容管理 API

- `/api/admin/user` - 用户管理
- `/api/admin/source` - 视频源管理
- `/api/admin/site` - 站点配置
- `/api/admin/tvbox` - TVBox 配置管理
- `/api/admin/data_migration/*` - 数据迁移工具

##### 外部集成 API

- `/api/douban/*` - 豆瓣数据集成
- `/api/tvbox/*` - TVBox 生态对接
- `/api/image-proxy` - 图片代理服务

### 前端架构设计

#### 组件层级结构

```
src/components/
├── 布局组件 (Layout, Navigation, ThemeProvider)
├── 业务组件 (VideoCard, EpisodeSelector, SearchSuggestions)
├── UI组件 (Button, Modal, Input, Card)
└── 工具组件 (Loading, ErrorBoundary, EmptyState)
```

#### 状态管理策略

- **服务端状态**: 使用 Next.js 服务端组件和数据获取
- **客户端状态**: React 状态钩子 (useState, useContext)
- **全局状态**: 使用 React Context API
- **表单状态**: 使用受控组件和 Zod 验证

### 安全架构

#### 认证授权

- **认证方式**: Cookie-based 会话管理
- **密码安全**: bcrypt 密码哈希存储
- **权限模型**: 管理员权限 + 普通用户权限
- **TVBox 接口**: 密码保护访问控制

#### 网络安全

- **传输安全**: HTTPS/TLS 1.3
- **HTTP 头部**: 安全 HTTP 头部配置 (CSP, HSTS, X-Frame-Options)
- **CORS 策略**: 严格的跨域资源共享配置
- **速率限制**: API 调用频率限制

#### 数据安全

- **输入验证**: 所有用户输入经过 Zod 验证
- **XSS 防护**: 输出编码和 CSP 策略
- **CSRF 防护**: CSRF Token 验证
- **SQL 注入防护**: 参数化查询和 ORM 使用

### 性能优化策略

#### 前端性能

- **代码分割**: Next.js 自动代码分割
- **图片优化**: Next.js Image 组件自动优化
- **字体优化**: 字体预加载和子集化
- **Bundle 优化**: Tree-shaking 和代码压缩

#### 后端性能

- **缓存策略**: Redis 缓存多层数据
- **数据库优化**: 查询索引和连接池
- **CDN 集成**: 静态资源 CDN 加速
- **压缩传输**: Gzip/Brotli 压缩

#### PWA 优化

- **Service Worker**: 离线缓存和资源预加载
- **Web App Manifest**: 原生应用体验配置
- **离线策略**: 关键资源离线可用
- **更新机制**: Service Worker 版本管理

## 开发配置

### TypeScript 配置

```json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "module": "Node16",
    "moduleResolution": "node16",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "~/*": ["./public/*"]
    }
  }
}
```

### 构建配置

- **开发命令**: `pnpm dev` (监听所有网络接口)
- **生产构建**: `pnpm build` (包含 manifest 和 runtime 生成)
- **生产启动**: `pnpm start`
- **Cloudflare 构建**: `pnpm pages:build`

### 代码质量工具

- **ESLint 配置**: Next.js 官方配置 + TypeScript 规则
- **Prettier 配置**: 统一代码格式化
- **Git Hooks**: 提交前自动检查和格式化
- **测试配置**: Jest 单元测试和覆盖率

## 扩展性设计

### 插件系统规划

- **视频源插件**: 支持自定义视频源解析
- **播放器插件**: 支持多种播放器集成
- **主题插件**: 支持自定义主题和样式
- **功能插件**: 模块化功能扩展

### 微服务拆分规划

- **搜索服务**: 独立搜索微服务
- **用户服务**: 独立用户管理微服务
- **播放服务**: 独立播放处理微服务
- **存储服务**: 统一存储网关服务

## 技术决策记录

### 关键技术决策

1. **选择 Next.js 14**: 提供完整的全栈解决方案，优秀的开发体验和性能
2. **TypeScript 严格模式**: 提高代码质量和可维护性
3. **存储抽象层**: 提供部署灵活性和多种存储后端支持
4. **TVBox 生态集成**: 扩大用户群体，提供更好的 Android TV 体验
5. **PWA 支持**: 提供原生应用体验和离线功能

### 未来技术规划

- **实时通信**: WebSocket 实时更新和通知
- **AI 推荐**: 基于用户行为的智能推荐
- **多语言支持**: 国际化(i18n)和多语言界面
- **移动应用**: React Native 移动应用开发

## 相关资源

- **Next.js 文档**: https://nextjs.org/docs
- **TypeScript 文档**: https://www.typescriptlang.org/docs
- **Tailwind CSS 文档**: https://tailwindcss.com/docs
- **Redis 文档**: https://redis.io/documentation
- **Upstash 文档**: https://upstash.com/docs

## 更新历史

- 2025-12-12: 创建技术架构记忆文件，基于项目记忆管理器新规则重构
- 2025-12-09: 项目版本升级到 3.6.2
- 2025-12-05: 引入 Vidstack 播放器，升级播放器技术栈
- 2025-10-15: 实现存储抽象层，支持多种存储后端
- 2025-10-01: 确定技术栈，基于 Next.js 14 + TypeScript + Tailwind CSS
