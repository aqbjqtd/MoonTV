# MoonTV 技术架构深度分析 (v3.2.0-dev)

## 🏗 系统架构层级

### L1: 前端展示层
```
React 18 + Next.js 14 App Router
├── 页面层 (src/app/*/page.tsx)
│   ├── 首页 (/) - 豆瓣推荐 + 自定义分类
│   ├── 搜索页 (/search) - 多源聚合搜索
│   ├── 播放页 (/play) - ArtPlayer视频播放
│   ├── 豆瓣页 (/douban) - 豆瓣分类浏览
│   ├── 登录页 (/login) - 用户认证
│   └── 管理后台 (/admin) - 配置管理（批量操作）
├── 组件层 (src/components/)
│   ├── 布局组件 (PageLayout, TopNav, MobileBottomNav)
│   ├── 业务组件 (VideoCard, EpisodeSelector, SourceSelector)
│   ├── 功能组件 (ThemeToggle, UserMenu, SearchSuggestions)
│   ├── 筛选组件 (FilterOptions - v3.2.0重构)
│   └── Provider组件 (ThemeProvider, SiteProvider, NavigationLoadingProvider)
└── 样式层
    ├── Tailwind CSS (原子化样式)
    ├── CSS变量 (主题系统)
    └── Framer Motion (动画)
```

### L2: API服务层
```
Next.js API Routes (Edge Runtime)
├── 用户认证 (/api/login, /api/register, /api/logout)
├── 搜索服务 (/api/search/*)
│   ├── /api/search - 多源搜索
│   ├── /api/search/one - 单源搜索
│   ├── /api/search/resources - 资源列表
│   ├── /api/search/suggestions - 搜索建议（v3.2.0优化）
│   └── /api/search/ws - WebSocket流式搜索
├── 详情服务 (/api/detail) - 视频详情
├── 豆瓣服务 (/api/douban/*)
│   ├── /api/douban/categories - 豆瓣分类
│   └── /api/douban/recommends - 豆瓣推荐
├── 配置服务 (/api/config/*)
│   ├── /api/config/sources - 资源站列表（v3.2.0简化）
│   └── /api/config/custom_category - 自定义分类
├── 用户数据 (/api/favorites, /api/playrecords, /api/searchhistory)
└── 管理员API (/api/admin/*)
    ├── /api/admin/category - 分类管理
    ├── /api/admin/source - 资源站管理（批量操作）
    ├── /api/admin/config - 配置管理
    ├── /api/admin/user - 用户管理
    └── /api/admin/tvbox - TVBox配置
```

### L3: 业务逻辑层
```
Core Libraries (src/lib/)
├── 认证模块 (auth.ts)
│   ├── JWT Token生成/验证
│   ├── HMAC签名（数据库模式）
│   ├── 会话管理
│   └── 权限检查
├── 配置管理 (config.ts, config.client.ts)
│   ├── 静态配置加载 (config.json)
│   ├── 动态配置管理 (非localstorage模式)
│   ├── 配置合并逻辑（复杂）
│   └── 环境变量处理
├── 数据库抽象层 (db.ts, db.client.ts)
│   ├── IStorage接口定义
│   ├── DbManager封装类
│   ├── 存储实现路由
│   └── 客户端存储抽象
├── 搜索引擎 (fetchVideoDetail.ts, downstream.ts)
│   ├── 多源并行搜索
│   ├── 流式结果返回
│   ├── 结果聚合排序
│   └── 超时控制
├── 豆瓣集成 (douban.ts, douban.client.ts)
│   ├── 豆瓣API代理
│   ├── 图片代理
│   └── 分类数据管理
├── 内容过滤 (yellow.ts)
│   └── 色情内容过滤
├── 版本管理 (version.ts, changelog.ts)
│   ├── 版本信息
│   └── 变更日志
└── 运行时配置 (runtime.ts - 自动生成)
    └── config.json编译时注入
```

### L4: 数据持久层
```
Storage Implementations
├── LocalStorage (浏览器端)
│   ├── 用户数据本地存储
│   ├── 无服务端依赖
│   └── 单设备使用
├── Redis (src/lib/redis.db.ts)
│   ├── 原生Redis客户端
│   ├── Docker部署专用
│   └── 高性能读写
├── Upstash Redis (src/lib/upstash.db.ts)
│   ├── HTTP-based Redis
│   ├── Serverless友好
│   └── 全球分布
└── Cloudflare D1 (src/lib/d1.db.ts)
    ├── SQLite-based
    ├── Cloudflare Pages专用
    └── SQL查询支持
```

---

## 🔄 数据流设计

### 搜索流程
```
用户输入关键词
    ↓
前端 /search/page.tsx
    ↓
API /api/search/route.ts
    ↓
getAvailableApiSites() - 获取启用的资源站
    ↓
并行调用20+资源站API (苹果CMS V10格式)
    ↓
结果聚合 + 去重 + 排序
    ↓
返回JSON响应
    ↓
前端渲染VideoCard组件
```

### 流式搜索流程（WebSocket）
```
用户输入关键词
    ↓
WebSocket连接 /api/search/ws
    ↓
searchFromApiStream() - 流式搜索函数
    ↓
逐个资源站搜索
    ↓
每个站点返回立即推送
    ↓
前端实时更新结果列表
    ↓
所有站点完成后关闭连接
```

### 播放流程
```
用户选择视频+集数
    ↓
前端 /play/page.tsx
    ↓
API /api/detail/route.ts (获取播放URL)
    ↓
handleSpecialSourceDetail() - 特殊源处理
    ↓
ArtPlayer初始化
    ↓
HLS.js加载m3u8流
    ↓
播放开始
    ↓
记录播放进度 → /api/playrecords
    ↓
定期更新断点续播位置
```

### 用户认证流程

#### localstorage模式
```
用户输入密码
    ↓
API /api/login/route.ts
    ↓
验证 PASSWORD 环境变量
    ↓
生成Cookie (password字段)
    ↓
中间件验证密码
    ↓
受保护路由访问
```

#### 数据库模式
```
用户输入账号密码
    ↓
API /api/login/route.ts
    ↓
存储层验证 (IStorage.verifyUser)
    ↓
生成HMAC签名
    ↓
生成Cookie (username + signature)
    ↓
中间件验证签名 (crypto.subtle.verify)
    ↓
受保护路由访问控制
```

### 配置加载流程

#### localstorage模式
```
应用启动
    ↓
读取 config.json (静态或Docker动态)
    ↓
合并环境变量
    ↓
生成 AdminConfig
    ↓
缓存到 cachedConfig
    ↓
注入到 window.RUNTIME_CONFIG
```

#### 数据库模式
```
应用启动
    ↓
从存储层读取 AdminConfig
    ↓
读取 config.json (基线配置)
    ↓
合并逻辑（复杂）:
  - config.json 提供基线源和分类
  - AdminConfig 提供用户自定义
  - from='config' vs from='custom' 标记
    ↓
补全用户列表 (getAllUsers)
    ↓
设置站长角色 (USERNAME环境变量)
    ↓
写回数据库（更新/创建）
    ↓
缓存到 cachedConfig
    ↓
注入到 window.RUNTIME_CONFIG
```

---

## 🔐 安全架构

### 认证机制

#### localstorage模式
```
Cookie结构
├── auth-token: { password: "..." }
├── httpOnly: true
├── secure: true (生产)
├── sameSite: 'lax'
└── maxAge: 7天

中间件验证
└── authInfo.password === process.env.PASSWORD
```

#### 数据库模式
```
Cookie结构
├── auth-token: { username: "...", signature: "..." }
├── httpOnly: true
├── secure: true (生产)
├── sameSite: 'lax'
└── maxAge: 7天

签名生成 (登录时)
├── 使用 crypto.subtle.sign
├── 算法: HMAC-SHA256
├── 密钥: PASSWORD环境变量
└── 数据: username

签名验证 (中间件)
├── 使用 crypto.subtle.verify
├── 算法: HMAC-SHA256
├── 密钥: PASSWORD环境变量
└── 数据: username
```

### 权限层级
```
角色系统
├── owner (USERNAME环境变量指定)
│   ├── 所有管理员权限
│   ├── 设置其他管理员
│   ├── 删除用户
│   └── AdminConfig中role='owner'
├── admin (由站长指定)
│   ├── 配置管理
│   ├── 资源站管理（批量操作）
│   ├── 分类管理
│   ├── 查看用户列表
│   └── AdminConfig中role='admin'
└── user (普通用户)
    ├── 搜索视频
    ├── 播放视频
    ├── 收藏管理
    ├── 播放记录
    └── AdminConfig中role='user'
```

### 中间件保护
```typescript
// src/middleware.ts
受保护路由匹配器:
matcher: [
  '/((?!_next/static|_next/image|favicon.ico|login|warning|api/login|api/register|api/logout|api/cron|api/server-config|api/tvbox/config|api/tvbox/categories|api/douban/recommends|api/admin/tvbox).*)'
]

跳过认证路径:
- /_next/* - Next.js内部资源
- /favicon.ico, /robots.txt, /manifest.json
- /icons/*, /logo.png
- /login, /warning - 公开页面
- /api/login, /api/register, /api/logout - 认证API
- /api/tvbox/config - TVBox公开接口（密码保护）

需要登录:
- /admin/* - 管理后台
- /api/admin/* - 管理API
- /api/favorites, /api/playrecords, /api/searchhistory

认证失败处理:
- API路由 → 401 Unauthorized
- 页面路由 → 重定向到 /login?redirect=...
```

---

## 🎨 UI架构设计

### 响应式策略
```
断点系统 (Tailwind默认)
├── sm: 640px - 小屏手机
├── md: 768px - 平板
├── lg: 1024px - 桌面
├── xl: 1280px - 大桌面
└── 2xl: 1536px - 超大屏

布局切换
├── < lg: 移动布局
│   ├── MobileHeader (顶部)
│   ├── 内容区域
│   └── MobileBottomNav (底部导航)
└── >= lg: 桌面布局
    ├── TopNav (顶部导航)
    ├── 侧边栏 (可选)
    └── 内容区域
```

### 主题系统
```
CSS变量驱动
├── 明亮模式
│   ├── --background: white
│   ├── --foreground: gray-900
│   └── --primary: blue-600
└── 暗黑模式
    ├── --background: black
    ├── --foreground: gray-200
    └── --primary: blue-500

切换机制
├── ThemeProvider (next-themes)
├── ThemeToggle组件
├── localStorage持久化
├── 系统偏好检测
└── 简化切换逻辑 (v3.2.0优化)
```

### 动画系统
```
Framer Motion
├── 页面切换动画
├── 列表项淡入
├── 模态框弹出
└── 骨架屏加载

CSS Transitions
├── 主题切换 (disableTransitionOnChange: true)
├── Hover效果
└── Loading状态

Loading优化 (v3.2.0)
├── NavigationLoadingIndicator
├── 加载动画优化
└── 骨架屏改进
```

---

## 📦 构建与部署架构

### 构建流程
```
开发模式 (pnpm dev)
├── gen:manifest - 生成PWA manifest.json
├── gen:runtime - 生成src/lib/runtime.ts
└── next dev -H 0.0.0.0 - 启动开发服务器

生产构建 (pnpm build)
├── gen:manifest - 生成PWA manifest.json
├── gen:runtime - 生成src/lib/runtime.ts
├── next build - Next.js构建
│   ├── standalone输出
│   ├── Edge Runtime优化
│   └── PWA资源生成
└── 输出.next/目录

运行时配置生成
├── scripts/generate-runtime.js
├── 读取 config.json
├── 生成 src/lib/runtime.ts
└── export default { api_site, custom_category }
```

### Docker部署架构
```
Dockerfile
├── 基础镜像: node:18-alpine
├── 工作目录: /app
├── 依赖安装: pnpm install
├── 构建: pnpm build
├── 生产依赖: pnpm install --prod
├── 环境变量: DOCKER_ENV=true
├── 暴露端口: 3000
└── 启动: node start.js

数据持久化
├── localstorage模式: 无需卷挂载
├── Redis模式: 外部Redis连接
└── 配置文件: 挂载 config.json (可选)

动态配置加载 (DOCKER_ENV=true)
├── 运行时读取 config.json
├── 支持热更新配置
└── 无需重新构建镜像
```

### Serverless部署架构
```
Vercel/Netlify
├── 自动检测Next.js项目
├── 环境变量配置
├── Edge Runtime部署
├── 全球CDN分发
└── 自动HTTPS

Cloudflare Pages
├── 构建命令: pnpm run pages:build
├── 输出目录: .vercel/output/static
├── 兼容性标志: nodejs_compat
├── D1数据库绑定: process.env.DB
├── 环境变量配置: 密钥形式
└── 边缘函数部署
```

---

## 🔌 第三方集成架构

### 豆瓣数据集成
```
代理模式配置
├── direct - 服务端直连豆瓣
├── cors-proxy-zwei - 浏览器通过CORS代理
├── cmliussss-cdn-tencent - 腾讯云CDN
├── cmliussss-cdn-ali - 阿里云CDN
└── custom - 自定义代理URL

图片代理模式
├── direct - 浏览器直连豆瓣图片域名
├── server - 服务端代理 (/api/image-proxy)
├── img3 - 豆瓣官方CDN（阿里云）
├── cmliussss-cdn-* - CMLiussss CDN
└── custom - 自定义代理

配置注入
├── 环境变量配置
├── AdminConfig存储
├── window.RUNTIME_CONFIG注入
└── 客户端动态读取
```

### TVBox对接架构
```
接口路径: /api/tvbox/config?pwd=密码
├── 密码验证
├── 读取配置 (AdminConfig.TvboxConfig)
├── 生成TVBox格式配置JSON
│   ├── 资源站点列表
│   ├── 直播源配置
│   └── 播放器设置
└── 返回配置

安全措施
├── 密码保护 (必需)
├── 可禁用接口 (AdminConfig.SiteConfig.TVBoxEnabled)
├── 独立密码管理 (AdminConfig.SiteConfig.TVBoxPassword)
└── localstorage模式使用PASSWORD环境变量

配置管理 (v3.2.0)
├── 管理后台配置界面
├── 随机密码生成
├── 开关控制
└── 接口地址自动生成
```

### OrionTV/Selene集成
```
后端API兼容
├── 搜索接口 (/api/search)
├── 详情接口 (/api/detail)
├── 收藏接口 (/api/favorites)
├── 播放记录 (/api/playrecords)
└── 用户认证 (/api/login)

客户端要求
├── HTTP请求标准化
├── Token认证支持 (Cookie)
└── JSON数据格式
```

---

## 📊 性能优化架构

### 缓存策略
```
多层缓存
├── L1: 浏览器缓存
│   ├── LocalStorage (用户数据)
│   ├── Service Worker (PWA离线)
│   └── HTTP缓存 (静态资源)
├── L2: 服务端缓存
│   ├── 搜索结果缓存 (配置时长)
│   ├── 豆瓣数据缓存
│   ├── 配置缓存 (cachedConfig)
│   └── React cache() (请求级)
└── L3: CDN缓存
    ├── 静态资源
    ├── 图片代理
    └── 边缘函数响应

缓存配置 (v3.2.0)
├── SiteInterfaceCacheTime (config.json)
├── API响应 Cache-Control头
├── max-age: 配置时长
└── s-maxage: 0 (边缘不缓存)
```

### 性能优化技术
```
前端优化
├── React Server Components
├── 流式渲染 (Suspense)
├── 图片懒加载
├── 代码分割 (动态import)
├── CSS内联关键样式
├── PWA离线缓存
└── 加载动画优化 (v3.2.0)

后端优化
├── Edge Runtime (快速启动)
├── 并行API调用 (Promise.allSettled)
├── 流式响应 (WebSocket)
├── 数据预取
├── 查询优化
└── 超时控制 (fetchWithTimeout)

v3.2.0性能改进
├── 明暗模式切换简化
├── 加载动画优化
├── FilterOptions组件重构
└── API路由简化
```

---

## 🧩 扩展性设计

### 插件化架构要点
```
资源站点插件化
├── 配置驱动 (config.json)
├── 统一接口 (苹果CMS V10)
├── 热更新支持 (Docker模式)
├── from标记 (config/custom)
├── disabled开关
└── 批量操作 (v3.2.0新增)

存储后端插件化
├── IStorage接口
├── 环境变量切换
├── 实现独立
├── DbManager封装
└── 易于扩展新后端

主题系统可扩展
├── CSS变量驱动
├── Tailwind配置
├── 组件主题支持
└── 自定义主题色

配置系统可扩展
├── AdminConfig类型扩展
├── 配置合并逻辑
├── 环境变量回退
└── 管理界面自动适配
```

### v3.2.0架构改进
```
批量操作架构
├── 资源站点批量启用/禁用
├── 分类批量管理
├── UI组件重构支持
└── API批量更新支持

代码简化
├── API路由优化
├── 组件逻辑重构
├── 类型安全增强
└── 错误处理改进
```

---

**文档更新**: 2025-10-06  
**架构版本**: v2.0 (全面更新)  
**技术栈**: Next.js 14 + React 18 + TypeScript 4  
**当前版本**: v3.2.0-dev
