# MoonTV 项目概览

## 项目类型
基于 Next.js 14 的现代化影视聚合播放器应用，支持多资源搜索、在线播放、收藏同步、播放记录、用户管理等功能。项目成熟度评分：8.6/10（优秀）

## 核心技术栈
- **前端框架**: Next.js 14 (App Router)
- **UI框架**: Tailwind CSS 3
- **语言**: TypeScript 4.9.5 (严格模式)
- **播放器**: ArtPlayer + HLS.js (主要) + VidStack React (备用)
- **状态管理**: React hooks + 自定义Context
- **测试**: Jest + Testing Library
- **代码质量**: ESLint + Prettier + Husky + lint-staged
- **包管理**: pnpm 10.14.0

## 核心架构特点
- **多后端存储抽象**: LocalStorage/Redis/Upstash/D1 统一接口
- **智能配置管理**: 文件配置 + 数据库配置动态合并
- **多层认证架构**: HMAC签名 + 防重放攻击
- **Edge Runtime**: 全球部署优化
- **PWA支持**: 离线缓存和原生应用体验

## 主要功能
- 多源聚合搜索（并发查询，流式返回）
- 丰富详情页展示（豆瓣数据集成）
- 流畅在线播放（智能源切换，质量优选）
- 收藏和继续观看记录（跨设备同步）
- 用户权限管理（owner/admin/user三级）
- 管理员后台（运行时配置管理）
- TVBox接口支持（外部服务集成）
- PWA 支持（离线缓存，桌面安装）
- 响应式布局（桌面侧边栏 + 移动底部导航）
- 智能去广告（实验性功能）

## 部署方式
支持多种部署方式：
- Vercel 部署（推荐，零配置）
- Docker 部署（多阶段构建优化）
- Netlify 部署
- Cloudflare Pages 部署（D1集成）

## 存储后端
- LocalStorage（本地存储，默认）
- Upstash Redis（云端同步，推荐）
- Cloudflare D1（边缘SQL数据库）
- 原生 Redis（自建服务）

## 安全特性
- HMAC签名认证
- 防重放攻击机制
- 中间件路由保护
- 权限分级管理
- 密码强制保护

## 开发工具
- 完整的TypeScript类型系统
- ESLint + Prettier代码规范
- Git hooks自动化检查
- Jest测试框架
- 热重载开发环境
- Docker容器化支持

## 最近更新
- 版本: v3.1.0
- 架构优化: Edge Runtime全面应用
- 新增功能: TVBox接口支持
- 安全增强: HMAC认证机制
- 用户体验: 流式搜索优化