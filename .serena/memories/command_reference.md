# MoonTV 常用命令速查

## 📦 包管理

### pnpm 命令

```bash
# 安装依赖
pnpm install

# 添加依赖
pnpm add <package>              # 生产依赖
pnpm add -D <package>           # 开发依赖

# 更新依赖
pnpm update                     # 全部更新
pnpm update <package>           # 更新指定包

# 删除依赖
pnpm remove <package>
```

---

## 🚀 开发命令

### 开发服务器

```bash
# 启动开发服务器（监听所有网络接口）
pnpm dev
# 等同于: pnpm gen:manifest && pnpm gen:runtime && next dev -H 0.0.0.0

# 仅启动Next.js开发服务器（无manifest/runtime生成）
next dev
```

### 构建与启动

```bash
# 生产构建
pnpm build
# 执行: gen:manifest → gen:runtime → next build

# 启动生产服务器
pnpm start
# 执行: next start

# Cloudflare Pages构建
pnpm pages:build
# 使用: @cloudflare/next-on-pages
```

---

## 🧹 代码质量

### Lint 与格式化

```bash
# ESLint检查
pnpm lint               # 检查src目录
pnpm lint:fix          # 自动修复 + 格式化
pnpm lint:strict       # 严格模式（0警告）

# Prettier格式化
pnpm format            # 格式化所有文件
pnpm format:check      # 检查格式（不修改）

# TypeScript类型检查
pnpm typecheck
# 执行: tsc --noEmit --incremental false
```

### Git 钩子（自动执行）

```bash
# pre-commit（提交前）
# → lint-staged → ESLint + Prettier

# commit-msg（提交信息验证）
# → commitlint → 验证提交格式
```

---

## 🧪 测试

### Jest 测试

```bash
# 运行所有测试
pnpm test

# 监听模式（开发时）
pnpm test:watch

# 单个文件测试
pnpm test <file-pattern>

# 覆盖率报告
pnpm test --coverage
```

---

## 🛠 工具脚本

### 自定义脚本

```bash
# 生成PWA manifest
pnpm gen:manifest
# 执行: node scripts/generate-manifest.js

# 生成运行时配置
pnpm gen:runtime
# 执行: node scripts/generate-runtime.js

# Husky安装（首次克隆后）
pnpm prepare
# 执行: husky install
```

---

## 🐳 Docker 命令

### 构建镜像

```bash
# 构建本地镜像
docker build -t moontv:latest .

# 指定平台构建
docker build --platform linux/amd64 -t moontv:latest .
```

### 运行容器

```bash
# 基础运行（localstorage模式）
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e PASSWORD=your_password \
  ghcr.io/stardm0/moontv:latest

# 使用Redis
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e NEXT_PUBLIC_STORAGE_TYPE=redis \
  -e REDIS_URL=redis://host:6379 \
  -e USERNAME=admin \
  -e PASSWORD=admin_password \
  ghcr.io/stardm0/moontv:latest

# 使用Upstash
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e NEXT_PUBLIC_STORAGE_TYPE=upstash \
  -e UPSTASH_URL=https://... \
  -e UPSTASH_TOKEN=... \
  -e USERNAME=admin \
  -e PASSWORD=admin_password \
  ghcr.io/stardm0/moontv:latest
```

### 容器管理

```bash
# 查看运行状态
docker ps

# 查看日志
docker logs moontv
docker logs -f moontv  # 实时日志

# 停止容器
docker stop moontv

# 启动容器
docker start moontv

# 重启容器
docker restart moontv

# 删除容器
docker rm moontv

# 删除镜像
docker rmi ghcr.io/stardm0/moontv:latest
```

### Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps
```

---

## 🗂 Git 命令

### 基础操作

```bash
# 查看状态
git status

# 查看分支
git branch

# 切换分支
git checkout <branch>
git switch <branch>  # 新语法

# 创建并切换分支
git checkout -b <branch>
git switch -c <branch>  # 新语法

# 暂存文件
git add <file>
git add .  # 所有文件

# 提交
git commit -m "feat: 提交信息"

# 推送
git push origin <branch>
```

### 项目提供的 Git 工具

```bash
# 简化Git操作（scripts/git-simple.sh）
./scripts/git-simple.sh

# Git诊断工具（scripts/git-check.sh）
./scripts/git-check.sh

# Git救援工具（scripts/git-rescue.sh）
./scripts/git-rescue.sh

# Git自动化（scripts/git-automation.sh）
./scripts/git-automation.sh

# Git设置（scripts/git-setup.sh）
./scripts/git-setup.sh
```

---

## 🌐 环境变量

### 开发环境

```bash
# 创建.env.local文件
cp .env.example .env.local

# 编辑环境变量
nano .env.local
```

### 关键环境变量

```bash
# 必需
PASSWORD=your_secure_password

# 存储配置
NEXT_PUBLIC_STORAGE_TYPE=localstorage  # 或 redis, upstash, d1
REDIS_URL=redis://localhost:6379       # Redis模式
UPSTASH_URL=https://...                # Upstash模式
UPSTASH_TOKEN=...                      # Upstash模式

# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV
ANNOUNCEMENT=站点公告内容
NEXT_PUBLIC_ENABLE_REGISTER=false

# 管理员账户（非localstorage模式）
USERNAME=admin
PASSWORD=admin_password

# 豆瓣代理
NEXT_PUBLIC_DOUBAN_PROXY_TYPE=direct
NEXT_PUBLIC_DOUBAN_IMAGE_PROXY_TYPE=direct

# 其他
NEXT_PUBLIC_SEARCH_MAX_PAGE=5
NEXT_PUBLIC_DISABLE_YELLOW_FILTER=false
```

---

## 🔍 调试命令

### Next.js 调试

```bash
# 详细构建日志
VERBOSE=1 pnpm build

# 分析bundle大小
ANALYZE=true pnpm build
```

### 网络调试

```bash
# 检查端口占用
lsof -i :3000

# 杀死占用进程
kill -9 <PID>

# 测试API
curl http://localhost:3000/api/config/sources
```

---

## 📊 性能分析

### Lighthouse

```bash
# 全局安装
npm install -g lighthouse

# 运行分析
lighthouse http://localhost:3000 --view
```

### Bundle 分析

```bash
# 安装分析工具
pnpm add -D @next/bundle-analyzer

# 配置next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

# 运行分析
ANALYZE=true pnpm build
```

---

## 🚢 部署命令

### Vercel 部署

```bash
# 安装Vercel CLI
npm install -g vercel

# 登录
vercel login

# 部署
vercel        # 预览部署
vercel --prod # 生产部署
```

### Netlify 部署

```bash
# 安装Netlify CLI
npm install -g netlify-cli

# 登录
netlify login

# 部署
netlify deploy        # 草稿部署
netlify deploy --prod # 生产部署
```

---

## 🧰 实用命令组合

### 完整检查流程

```bash
# 代码质量全面检查
pnpm format && pnpm lint && pnpm typecheck && pnpm test
```

### 清理与重置

```bash
# 清理依赖和缓存
rm -rf node_modules .next pnpm-lock.yaml
pnpm install

# 完全重置（包括环境）
rm -rf node_modules .next pnpm-lock.yaml .env.local
pnpm install
pnpm dev
```

### 快速调试

```bash
# 检查构建输出
pnpm build && ls -lh .next/standalone

# 测试生产构建
pnpm build && pnpm start
```

---

**文档版本**: v1.0  
**最后更新**: 2025-10-06  
**快速索引**: 开发 | 构建 | 测试 | Docker | Git | 环境变量 | 部署
