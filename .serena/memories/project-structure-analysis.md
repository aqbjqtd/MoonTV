# 项目结构分析

## 📁 根目录结构

```
MoonTV-master/
├── src/                    # 源代码目录
├── public/                 # 静态资源
├── scripts/               # 构建脚本
├── .next/                 # Next.js构建输出
├── .serena/               # Serena项目记忆
├── node_modules/          # 依赖包
├── package.json           # 项目配置
├── pnpm-lock.yaml         # 依赖锁定文件
├── tailwind.config.js     # Tailwind配置
├── tsconfig.json          # TypeScript配置
├── next.config.mjs        # Next.js配置
├── Dockerfile             # Docker构建文件
├── .dockerignore          # Docker排除文件
├── start.js               # 启动脚本
├── config.json            # 应用配置
└── README.md              # 项目文档
```

## 📂 src 目录结构

```
src/
├── app/                   # Next.js App Router
│   ├── play/              # 播放页面
│   │   ├── page.tsx       # 主播放器组件 (2109行)
│   │   └── page_old.tsx   # 备份文件
│   ├── layout.tsx         # 根布局
│   ├── page.tsx           # 首页
│   ├── login/             # 登录页面
│   ├── search/            # 搜索页面
│   ├── douban/            # 豆瓣相关
│   ├── admin/             # 管理后台
│   └── api/               # API路由
├── components/            # React组件
│   ├── PageLayout.tsx     # 页面布局
│   ├── EpisodeSelector.tsx # 选集器
│   └── ...               # 其他组件
├── lib/                   # 工具库
│   ├── db.client.ts       # 数据库客户端 (IndexedDB)
│   ├── runtime.ts         # 运行时配置
│   ├── types.ts           # 类型定义
│   ├── utils.ts           # 工具函数
│   └── ...
└── styles/                # 样式文件
```

## 🔧 核心文件分析

### 播放器核心 (src/app/play/page.tsx)
- **文件大小**: 2109行代码
- **主要功能**: 
  - HLS视频播放
  - 多源切换
  - 集数选择
  - 播放记录
  - 收藏功能
  - 跳过片头片尾
  - 去广告功能
- **技术栈**: React + HLS.js + Artplayer

### 数据库客户端 (src/lib/db.client.ts)
- **存储方式**: IndexedDB (浏览器本地存储)
- **主要功能**:
  - 播放记录管理
  - 收藏管理
  - 跳过配置管理
  - 搜索历史
- **特点**: 纯前端，无需后端数据库

### 页面布局 (src/components/PageLayout.tsx)
- **功能**: 统一的页面布局和导航
- **特性**: 响应式设计，支持移动端和桌面端

### 选集器 (src/components/EpisodeSelector.tsx)
- **功能**: 视频集数选择和源切换
- **特性**: 支持测速和优选功能

## 🎯 技术架构特点

### 1. 无后端架构
- **数据存储**: IndexedDB + localStorage
- **API**: Next.js API Routes (服务端渲染)
- **部署**: 静态部署 + Docker容器化

### 2. 视频播放技术
- **HLS.js**: 处理m3u8流媒体
- **Artplayer**: 播放器UI和交互
- **优化**: 缓冲区管理、错误恢复、多源切换

### 3. 用户体验优化
- **PWA**: 支持离线使用
- **响应式**: 适配各种设备
- **性能**: 代码分割、懒加载

## 📊 代码质量指标

### TypeScript 支持
- **严格模式**: 启用TypeScript严格检查
- **类型定义**: 完整的类型系统
- **编译检查**: 无TypeScript错误

### React 最佳实践
- **Hooks**: 使用现代React Hooks
- **组件化**: 模块化组件设计
- **状态管理**: 本地状态 + 上下文

### 性能优化
- **代码分割**: Next.js自动代码分割
- **图片优化**: Next.js Image组件
- **缓存策略**: 合理的缓存配置

## 🚀 构建和部署

### 开发环境
```bash
pnpm dev        # 启动开发服务器
pnpm build      # 构建生产版本
pnpm start      # 启动生产服务器
```

### Docker 部署
```bash
docker build -t aqbjqtd/moontv:simplified .
docker run -d -p 9000:3000 --env PASSWORD=123456 aqbjqtd/moontv:simplified
```

## 💡 技术亮点

### 1. 纯前端解决方案
- 无需后端数据库
- 完全基于浏览器存储
- 部署简单，成本低

### 2. 视频播放优化
- 多源自动切换
- 智能缓存管理
- 错误恢复机制

### 3. 用户体验
- 流畅的拖动体验
- 响应式设计
- PWA支持

### 4. 可维护性
- TypeScript类型安全
- 模块化代码结构
- 完整的项目文档