# MoonTV 开发指南

## 核心开发命令
```bash
# 开发环境 (监听所有网络接口)
pnpm dev                    # 启动开发服务器 0.0.0.0:3000

# 构建相关
pnpm build                  # 生产构建 (包含manifest和runtime生成)
pnpm start                  # 启动生产服务器
pnpm pages:build           # Cloudflare Pages构建

# 代码质量检查
pnpm lint                   # ESLint代码检查
pnpm lint:fix              # 自动修复代码问题
pnpm lint:strict           # 严格模式检查 (max-warnings=0)
pnpm typecheck             # TypeScript类型检查
pnpm format                # Prettier代码格式化

# 测试
pnpm test                  # Jest单元测试
pnpm test:watch            # 测试监听模式

# 代码生成
pnpm gen:manifest          # PWA清单生成
pnpm gen:runtime           # 运行时配置生成
```

## 环境变量配置
### 核心配置
```yaml
PASSWORD                 # 管理员密码 (必需)
USERNAME                 # 管理员用户名
NEXT_PUBLIC_SITE_NAME    # 站点名称
NEXT_PUBLIC_STORAGE_TYPE # 存储类型 (localstorage/redis/upstash/d1)
```

### 存储配置
```yaml
REDIS_URL               # Redis连接URL
UPSTASH_URL            # Upstash Redis URL
UPSTASH_TOKEN          # Upstash Redis Token
```

### 功能配置
```yaml
NEXT_PUBLIC_ENABLE_REGISTER  # 是否开放用户注册
NEXT_PUBLIC_SEARCH_MAX_PAGE  # 搜索最大页数 (1-50)
TVBOX_ENABLED               # TVBox接口开关 (默认true)
```

## 部署说明

### Docker部署 (推荐)
```bash
# 拉取镜像
docker pull ghcr.io/stardm0/moontv:latest

# 运行容器
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e PASSWORD=your_password \
  -e USERNAME=your_username \
  ghcr.io/stardm0/moontv:latest
```

### Vercel部署 (零配置)
- 连接GitHub仓库自动部署
- 自动CI/CD集成
- 边缘计算支持
- 全球CDN分发

### Cloudflare Pages部署
```yaml
构建命令: pnpm pages:build
输出目录: .vercel/output/static
兼容性标志: nodejs_compat
```

### 自托管部署
```bash
# 安装依赖
pnpm install

# 构建项目
pnpm build

# 启动服务
pnpm start

# 使用PM2进程管理
pm2 start npm --name "moontv" -- start
```

## 开发流程

### 1. 环境准备
```bash
# 安装Node.js 20.x
# 安装pnpm 10.14.0
# 克隆仓库并进入目录
git clone https://github.com/stardm0/MoonTV.git
cd MoonTV
pnpm install
```

### 2. 开发环境配置
```bash
# 复制环境变量模板
cp .env.example .env.local

# 编辑环境变量
vim .env.local
```

### 3. 启动开发环境
```bash
# 启动开发服务器
pnpm dev

# 访问应用
# 浏览器打开: http://localhost:3000
```

### 4. 代码提交规范
```bash
# Git提交规范 (使用commitlint)
feat: 新功能
fix: 修复
docs: 文档
style: 格式化
refactor: 重构
test: 测试
chore: 构建过程或辅助工具的变动
```

## 代码质量保证
- **ESLint**: next config + typescript rules
- **Prettier**: 代码格式化
- **Husky**: Git hooks
- **lint-staged**: 提交前检查
- **commitlint**: 提交信息规范
- **TypeScript**: 严格模式，类型覆盖率 >95%

## 调试技巧
```bash
# 查看存储类型和配置
curl http://localhost:3000/api/server-config

# 测试搜索API
curl "http://localhost:3000/api/search?wd=测试关键词"

# 检查TVBox配置
curl "http://localhost:3000/api/tvbox/config?pwd=密码"
```

## 常见问题
1. **存储后端切换**: 使用内置数据迁移工具，避免数据丢失
2. **环境变量配置**: 部署前检查必需的环境变量设置
3. **API安全**: 生产环境必须设置密码保护
4. **缓存策略**: 合理设置缓存时间，平衡性能和实时性