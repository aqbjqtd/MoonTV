# MoonTV 开发命令参考

## 开发命令
```bash
# 启动开发服务器
pnpm dev

# 构建项目
pnpm build

# 启动生产服务器
pnpm start
```

## 代码质量检查
```bash
# 运行 ESLint 检查
pnpm lint

# 自动修复 ESLint 问题并格式化
pnpm lint:fix

# 严格模式检查（零警告）
pnpm lint:strict

# TypeScript 类型检查
pnpm typecheck

# 格式化代码
pnpm format

# 检查格式化
pnpm format:check
```

## 测试命令
```bash
# 运行测试
pnpm test

# 监视模式运行测试
pnpm test:watch
```

## 项目构建命令
```bash
# 生成 manifest 文件
pnpm gen:manifest

# 生成 runtime 文件
pnpm gen:runtime

# 构建 Cloudflare Pages
pnpm pages:build
```

## 系统命令（Windows）
```bash
# 查看目录结构
dir

# 查看文件内容
type filename

# 搜索文件
findstr /s "text" *.ts *.tsx

# Git 操作
git status
git add .
git commit -m "message"
git push origin main
```

## Docker 命令
```bash
# 拉取镜像
docker pull stardm/startv:latest

# 运行容器
docker run -d --name moontv -p 3000:3000 --env PASSWORD=your_password stardm/startv:latest
```