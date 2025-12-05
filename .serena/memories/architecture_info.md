# MoonTV 架构信息

## 技术架构特征
```yaml
架构模式: 全栈Web应用 (JAMstack架构)
渲染策略: Edge-First + Fallback (边缘优先)
运行时: Edge Runtime (优先) + Node.js Runtime (降级)
存储模式: 多后端抽象 (统一IStorage接口)
部署模式: 多平台部署 (Docker/Vercel/Cloudflare/自托管)
```

## 目录结构
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

## 存储抽象层设计
```typescript
// 核心存储接口 - 支持多种后端
interface IStorage {
  get<T>(key: string): Promise<T | null>
  set<T>(key: string, value: T, ttl?: number): Promise<void>
  delete(key: string): Promise<void>
  mget<T>(keys: string[]): Promise<(T | null)[]>
  mset<T>(entries: Array<[string, T]>): Promise<void>
  // ... 更多方法
}

// 支持的存储后端:
// - LocalStorage (浏览器本地存储)
// - Redis 4.6.7 (自托管缓存)
// - Upstash Redis 1.25.0 (云端缓存)
// - Cloudflare D1 (无服务器SQLite)
```

## API架构设计
```yaml
核心业务API (/api):
  - /api/search/*          # 视频搜索 (批量/单源/WebSocket/建议)
  - /api/detail/*          # 播放详情获取
  - /api/login|logout|register # 用户认证
  - /api/favorites|playrecords # 用户数据

内容管理API (/api/admin/*):
  - /api/admin/user        # 用户管理
  - /api/admin/source      # 视频源管理
  - /api/admin/site        # 站点配置
  - /api/admin/tvbox       # TVBox配置管理
  - /api/admin/data_migration/* # 数据迁移工具

外部集成API:
  - /api/douban/*          # 豆瓣数据集成
  - /api/tvbox/*           # TVBox生态对接
  - /api/image-proxy       # 图片代理服务
```

## 安全架构
- **认证方式**: Cookie-based会话管理 + bcrypt密码哈希
- **权限模型**: 管理员权限 + 普通用户权限 + TVBox接口密码保护
- **数据安全**: HTTPS/TLS 1.3 + 安全HTTP头部 + CORS跨域保护
- **输入验证**: XSS防护 + CSRF Token + SQL注入防护