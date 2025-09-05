# MoonTV 项目概览

## 项目基本信息
- **项目名称**: MoonTV-master
- **项目类型**: Next.js 14 视频流媒体应用
- **主要技术**: React, TypeScript, Next.js, HLS.js, ArtPlayer, Docker
- **开发语言**: TypeScript
- **包管理器**: pnpm

## 当前状态 (2025-09-05)
- **主版本**: 稳定的 v1.0-moontv-stable (已回滚)
- **当前分支**: master
- **构建状态**: ✅ 成功构建简化版 Docker 镜像
- **运行状态**: ✅ 容器正常运行在端口 9000

## 核心功能
- 🎬 视频播放 (HLS.js + ArtPlayer)
- 🔍 视频搜索和源切换
- 📱 响应式设计
- 🗂️ 收藏和播放记录
- ⚙️ 管理员后台
- 🌐 PWA 支持

## 技术架构
- **前端**: Next.js 14 + React 18 + TypeScript
- **样式**: Tailwind CSS
- **视频播放**: HLS.js + Artplayer
- **状态管理**: React Hooks + localStorage
- **数据库**: 无后端数据库，使用前端存储
- **部署**: Docker 多阶段构建

## Docker 配置
- **镜像名**: aqbjqtd/moontv:simplified
- **运行端口**: 9000
- **环境变量**: PASSWORD=123456
- **构建方式**: 多阶段构建，使用 BuildKit

## 最近更新
- 回滚到稳定版本解决播放问题
- 优化视频拖动缓冲区配置
- 完善 .dockerignore 文件
- 成功构建简化版镜像