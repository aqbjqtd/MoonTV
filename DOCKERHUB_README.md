# MoonTV - 现代化的视频播放平台

MoonTV是一个基于Next.js 14构建的现代化视频播放平台，提供流畅的用户体验和丰富的功能特性。

## 🚀 v2.0.0 版本特性

### ✨ 核心功能
- **🎬 智能视频播放**: 支持多种视频格式，自适应码率切换
- **🔍 高级搜索**: 智能搜索算法，支持关键词联想和搜索历史
- **📱 响应式设计**: 完美适配桌面、平板和移动设备
- **⭐ 收藏系统**: 用户可收藏喜欢的视频，支持分类管理
- **📊 播放记录**: 自动记录观看历史，支持断点续播

### 🛡️ 安全与性能
- **🔒 安全认证**: JWT身份验证，安全的用户会话管理
- **⚡ 性能优化**: Next.js 14 App Router，服务端渲染优化
- **📦 容器化部署**: Docker容器化，一键部署运行
- **🌐 CDN就绪**: 静态资源优化，支持CDN加速

### 🎨 用户体验
- **🌙 深色模式**: 支持系统级深色/浅色主题切换
- **🎯 智能推荐**: 基于观看历史的个性化内容推荐
- **📝 评论互动**: 用户评论和评分系统
- **🔔 实时通知**: 新内容更新和系统通知

## 🐳 快速开始

### 使用Docker运行
```bash
# 拉取最新版本
docker pull aqbjqtd/moontv:latest

# 运行容器
docker run -d \
  -p 3000:3000 \
  --name moontv \
  aqbjqtd/moontv:latest
```

### 使用Docker Compose
```yaml
version: '3.8'
services:
  moontv:
    image: aqbjqtd/moontv:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
```

## ⚙️ 环境配置

### 必需环境变量
```bash
# 数据库配置
DATABASE_URL=your_database_connection_string

# 认证配置
NEXTAUTH_SECRET=your_secret_key
NEXTAUTH_URL=http://localhost:3000

# 文件存储
UPLOAD_PATH=/app/uploads
```

### 可选环境变量
```bash
# 性能调优
MAX_FILE_SIZE=50MB
CACHE_TTL=3600

# 功能开关
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
```

## 📊 技术栈

- **前端框架**: Next.js 14 + TypeScript
- **样式方案**: Tailwind CSS + shadcn/ui
- **状态管理**: Zustand
- **数据库**: PostgreSQL with Prisma ORM
- **认证**: NextAuth.js
- **部署**: Docker + Node.js 18

## 🔧 开发特性

### 开发模式
```bash
# 克隆项目
git clone https://github.com/your-username/moontv.git
cd moontv

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

### 构建生产版本
```bash
# 构建应用
npm run build

# 启动生产服务器
npm start

# 使用Docker构建
docker build -t your-username/moontv:latest .
```

## 📈 监控与日志

- **健康检查**: `/api/health` 端点提供应用状态
- **性能监控**: 内置性能指标收集
- **错误追踪**: 集中式错误日志记录
- **访问日志**: 详细的请求响应日志

## 🤝 贡献指南

我们欢迎贡献！请阅读我们的贡献指南：
1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 支持

如果您遇到问题：
- 查看 [文档](https://github.com/your-username/moontv/wiki)
- 提交 [Issue](https://github.com/your-username/moontv/issues)
- 发送邮件至 support@moontv.com

---

**MoonTV v2.0.0** - 为您带来卓越的视频观看体验！ 🎉