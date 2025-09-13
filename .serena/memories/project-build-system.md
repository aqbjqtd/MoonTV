# MoonTV 项目构建系统信息

## 📦 包管理工具

- **主要包管理器**: pnpm
- **版本**: pnpm@10.14.0
- **配置文件**: package.json 中指定了 `"packageManager": "pnpm@10.14.0"`

## 🚀 构建命令

```bash
# 开发环境启动
pnpm run dev

# 生产环境构建
pnpm run build

# 代码质量检查
pnpm run lint

# 类型检查
pnpm run typecheck

# 代码格式化
pnpm run format

# 测试
pnpm run test
```

## ⚠️ 重要提醒

**所有构建和开发操作都必须使用 pnpm，而不是 npm！**

### 为什么重要？

- 项目依赖使用 pnpm 锁定 (pnpm-lock.yaml)
- npm 无法正确解析 pnpm 的依赖结构
- 使用 npm 会导致依赖错误和构建失败

### 正确的构建流程

```bash
# 1. 安装依赖
pnpm install

# 2. 开发模式
pnpm run dev

# 3. 构建生产版本
pnpm run build

# 4. 代码质量检查
pnpm run lint && pnpm run typecheck
```

### 常见错误避免

- ❌ 不要使用 `npm install`
- ❌ 不要使用 `npm run build`
- ❌ 不要使用 `npm run dev`
- ✅ 始终使用 `pnpm` 命令

## 🔧 脚本说明

虽然 package.json 中的某些脚本被修改为直接使用 node 命令（为了 Docker 构建兼容性），但在开发环境中仍应使用 pnpm 运行这些脚本。

### Docker 环境的特殊处理

在 Docker 构建环境中，为了兼容性，一些脚本使用了直接的 node 命令，但在本地开发中仍应使用 pnpm。
