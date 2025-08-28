# MoonTV 项目上下文

## 项目目的
MoonTV 是一个基于 Next.js 14 的影视聚合播放器，支持多资源搜索、在线播放、收藏同步、播放记录等功能。

## 技术栈
- **前端框架**: Next.js 14 (App Router)
- **样式**: Tailwind CSS 3
- **语言**: TypeScript 4.x
- **播放器**: ArtPlayer + HLS.js + Vidstack
- **状态管理**: React + Context
- **存储**: Redis/D1/Upstash/LocalStorage
- **UI组件**: Headless UI, Heroicons, Lucide React
- **动画**: Framer Motion
- **PWA**: next-pwa
- **包管理器**: pnpm (主要) / npm (兼容)

## 项目结构
```
/
├── .github/          # GitHub Actions 工作流
├── .husky/           # Git hooks
├── .vscode/          # VS Code 配置
├── public/           # 静态资源
├── scripts/          # 构建脚本
├── src/
│   ├── app/          # Next.js App Router 页面
│   ├── components/   # React 组件
│   ├── lib/          # 工具函数和配置
│   └── types/        # TypeScript 类型定义
├── config.json       # 影视资源站点配置
├── package.json      # 项目依赖和脚本
└── 各种配置文件
```

## 存储方案支持矩阵
- LocalStorage: 本地浏览器存储
- Redis: 原生 Redis 服务器
- D1: Cloudflare D1 数据库
- Upstash: 云端 Redis 服务

## 部署平台支持
- Docker (推荐)
- Vercel 
- Netlify
- ~~Cloudflare Pages~~ (已不支持)