# MoonTV 项目概览

## 项目类型
基于 Next.js 14 的影视聚合播放器应用，支持多资源搜索、在线播放、收藏同步、播放记录等功能。

## 核心技术栈
- **前端框架**: Next.js 14 (App Router)
- **UI框架**: Tailwind CSS 3
- **语言**: TypeScript 4.9.5
- **播放器**: ArtPlayer + HLS.js
- **状态管理**: React hooks
- **测试**: Jest + Testing Library
- **代码质量**: ESLint + Prettier
- **包管理**: pnpm

## 主要功能
- 多源聚合搜索（流式搜索）
- 丰富的详情页展示
- 流畅在线播放
- 收藏和继续观看记录
- PWA 支持
- 响应式布局
- 智能去广告（实验性）

## 部署方式
支持多种部署方式：
- Vercel 部署（推荐）
- Netlify 部署
- Cloudflare Pages 部署
- Docker 部署

## 存储方式
- LocalStorage（本地存储）
- Upstash Redis（云端同步）
- Cloudflare D1（数据库）
- 原生 Redis