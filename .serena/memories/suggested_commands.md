# MoonTV 推荐命令

## 开发命令
```bash
# 启动开发服务器
npm run dev
pnpm dev

# 构建项目 (生产环境)
npm run build
pnpm build

# 启动生产服务器
npm start
pnpm start

# 代码检查和修复
npm run lint          # ESLint 检查
npm run lint:fix      # 自动修复 ESLint 错误
npm run lint:strict   # 严格模式检查 (0 warnings)

# 类型检查
npm run typecheck     # TypeScript 类型检查

# 代码格式化
npm run format        # Prettier 格式化
npm run format:check  # 检查格式化状态

# 测试
npm test              # 运行 Jest 测试
npm run test:watch    # 监听模式运行测试

# 生成工具
npm run gen:runtime   # 生成运行时配置
npm run gen:manifest  # 生成 PWA manifest

# Git 相关
npm run prepare       # Husky 安装 (自动运行)
```

## 包管理器
- **主要**: pnpm (项目配置的 packageManager)
- **兼容**: npm (使用 --legacy-peer-deps 解决依赖冲突)

## 系统工具 (Linux)
```bash
ls          # 列出文件
cd          # 切换目录  
grep        # 文本搜索
find        # 文件查找
cat         # 查看文件内容
head/tail   # 查看文件头尾
git         # 版本控制
docker      # 容器化部署
```