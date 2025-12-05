# MoonTV 项目状态信息

## 版本信息
- **项目版本**: v3.5.0 (2025-12-05更新)
- **Next.js版本**: 14.2.30
- **React版本**: 18.2.0
- **TypeScript版本**: 4.9.5
- **Node.js要求**: 20.x
- **包管理器**: pnpm 10.14.0

## Git状态
- **当前分支**: v3.4.2-with-upstream-fixes
- **主分支**: main
- **工作目录状态**: Clean（除新增的.serena目录和PWA文件）
- **未跟踪文件**: 
  - .serena/（项目记忆系统）
  - public/sw.js（Service Worker文件）
  - public/workbox-e9849328.js（Workbox文件）

## 构建状态
- **TypeScript**: 严格模式，类型覆盖率 >95%
- **ESLint**: 配置完整，支持Next.js + TypeScript规则
- **Prettier**: 代码格式化配置
- **Husky**: Git hooks配置
- **测试**: Jest单元测试环境

## Docker信息
- **官方镜像**: ghcr.io/stardm0/moontv:latest (约313MB)
- **运行用户**: 非特权用户 (UID: 1001)
- **健康检查**: 内置健康检查机制
- **平台支持**: linux/amd64, linux/arm64

## 依赖更新状态
### 核心依赖（最新）:
- Next.js 14.2.30（最新稳定版）
- React 18.2.0（稳定版）
- TypeScript 4.9.5（稳定版）
- Tailwind CSS 3.4.17（最新版）

### 新增依赖:
- @vidstack/react: 1.12.13（现代播放器）
- framer-motion: 12.18.1（动画库）
- lucide-react: 0.438.0（图标库）

## 环境配置
- **Edge Runtime**: 优先支持边缘计算
- **Node.js Runtime**: 降级兼容
- **多存储后端**: LocalStorage/Redis/Upstash/D1
- **PWA支持**: Service Worker + Web App Manifest

## 近期更新
1. 新增日志系统和工具
2. 添加版本一致性检查脚本
3. 升级播放器到Vidstack
4. 完善PWA功能
5. 优化Docker配置