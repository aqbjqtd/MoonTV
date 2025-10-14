# MoonTV 开发工作流程 - Dev 版本

> **文档版本**: dev (永久开发版本) | **更新日期**: 2025-10-14 | **流程类型**: 企业级开发标准

## 🎯 开发理念

### 核心开发原则

MoonTV 项目采用 **企业级开发标准**，专注于代码质量、开发效率和团队协作。

**开发原则**:

- 🏗️ **架构优先**: 清晰的架构设计指导开发
- 🧪 **测试驱动**: 测试用例指导代码开发
- 📚 **文档同步**: 代码与文档同步更新
- 🔄 **持续集成**: 自动化构建和部署流程
- 🛡️ **安全第一**: 安全性贯穿整个开发流程

### 开发模式

```yaml
开发模式: Git Flow + DevOps
代码管理: 特性分支 + Pull Request
质量控制: 自动化测试 + 代码审查
部署策略: 持续集成 + 持续部署
团队协作: 标准化流程 + 工具支持
```

## 🛠️ 开发环境配置

### 必需工具

```yaml
核心工具:
  - Node.js: 20.x (LTS)
  - pnpm: 10.14.0+ (包管理器)
  - Git: 2.30+ (版本控制)
  - Docker: 20.10+ (容器化)
  - Docker Compose: 2.0+ (容器编排)

开发工具:
  - VS Code: 推荐开发环境
  - Chrome DevTools: 调试工具
  - Postman: API 测试工具
  - DBeaver: 数据库管理工具

可选工具:
  - Redis Desktop Manager: Redis 管理
  - ngrok: 内网穿透工具
  - GitHub Desktop: Git GUI 工具
```

### 环境配置步骤

```bash
# 1. 克隆项目
git clone <repository-url> MoonTV
cd MoonTV

# 2. 安装 Node.js (使用 nvm 推荐)
nvm install 20
nvm use 20

# 3. 验证 pnpm 版本
pnpm --version

# 4. 安装项目依赖
pnpm install

# 5. 复制环境变量文件
cp .env.example .env.local

# 6. 配置环境变量
# 编辑 .env.local 文件

# 7. 启动开发服务器
pnpm dev
```

### 开发环境验证

```bash
# 验证依赖安装
pnpm list --depth=0

# 验证类型检查
pnpm typecheck

# 验证代码质量
pnpm lint

# 验证测试通过
pnpm test

# 验证应用启动
curl http://localhost:3000/api/health
```

## 📁 项目结构规范

### 目录结构

```
MoonTV/
├── .serena/                 # Serena MCP 配置和记忆
│   ├── project.yml          # 项目配置
│   └── memories/            # 项目记忆文件
├── .github/                 # GitHub 配置
│   ├── workflows/           # CI/CD 工作流
│   └── ISSUE_TEMPLATE/      # Issue 模板
├── src/                     # 源代码目录
│   ├── app/                 # Next.js App Router
│   │   ├── (auth)/          # 认证相关页面
│   │   ├── admin/           # 管理后台
│   │   ├── api/             # API 路由
│   │   ├── globals.css      # 全局样式
│   │   ├── layout.tsx       # 根布局
│   │   └── page.tsx         # 首页
│   ├── components/          # React 组件
│   │   ├── ui/              # UI 基础组件
│   │   ├── forms/           # 表单组件
│   │   └── layout/          # 布局组件
│   ├── lib/                 # 工具库
│   │   ├── *.db.ts          # 存储实现
│   │   ├── *.ts             # 工具函数
│   │   ├── admin.types.ts   # 管理类型定义
│   │   ├── config.ts        # 配置管理
│   │   ├── runtime.ts       # 运行时配置
│   │   └── version.ts       # 版本信息
│   ├── types/               # TypeScript 类型
│   └── styles/              # 样式文件
├── public/                  # 静态资源
├── scripts/                 # 构建脚本
├── tests/                   # 测试文件
├── docker-*.md             # Docker 文档
├── *.json                  # 配置文件
├── *.yml                   # YAML 配置
├── *.config.*              # 工具配置
└── *.md                    # 文档文件
```

### 命名规范

```yaml
文件命名:
  - 组件文件: PascalCase.tsx (UserProfile.tsx)
  - 工具文件: camelCase.ts (apiClient.ts)
  - 页面文件: kebab-case.tsx (user-profile.tsx)
  - 配置文件: kebab-case.config.js (tailwind.config.js)

目录命名:
  - 组件目录: kebab-case (user-profile/)
  - 工具目录: camelCase (apiClient/)
  - 页面目录: kebab-case (user-profile/)

变量命名:
  - 组件: PascalCase (UserProfile)
  - 函数: camelCase (getUserData)
  - 常量: UPPER_SNAKE_CASE (API_BASE_URL)
  - 类型: PascalCase (UserType)
```

## 🔄 Git 工作流程

### 分支策略

```yaml
主分支: main
  - 用途: 开发环境主分支
  - 保护: 禁止直接推送
  - 合并: 必须通过 Pull Request
  - 标签: dev (始终指向最新)

特性分支: feature/[功能名]
  - 用途: 新功能开发
  - 创建: 从 main 分支创建
  - 命名: feature/user-authentication
  - 合并: 开发完成后合并到 main

修复分支: fix/[问题描述]
  - 用途: 问题修复
  - 创建: 从 main 分支创建
  - 命名: fix/login-validation-error
  - 合并: 修复完成后合并到 main

热修复分支: hotfix/[问题描述]
  - 用途: 紧急问题修复
  - 创建: 从生产版本标签创建
  - 命名: hotfix/security-vulnerability
  - 合并: 修复后合并到 main 和生产版本
```

### 提交规范

```yaml
提交格式: <type>(<scope>): <subject>

类型 (type):
  - feat: 新功能
  - fix: 问题修复
  - docs: 文档更新
  - style: 代码格式化
  - refactor: 代码重构
  - test: 测试相关
  - chore: 构建工具或辅助工具的变动

范围 (scope):
  - api: API 相关
  - ui: UI 组件
  - config: 配置相关
  - docker: Docker 相关
  - auth: 认证相关
  - storage: 存储相关

示例:
  - feat(auth): 添加用户登录功能
  - fix(api): 修复搜索结果分页问题
  - docs(docker): 更新 Docker 构建文档
  - style(ui): 调整按钮样式
  - refactor(storage): 重构 Redis 存储实现
```

### Pull Request 流程

```yaml
创建 PR: 1. 创建特性分支并开发
  2. 推送分支到远程仓库
  3. 创建 Pull Request
  4. 填写 PR 模板
  5. 指定审查者

PR 审查: 1. 自动化检查通过
  2. 代码审查 (至少 1 人)
  3. 测试验证
  4. 讨论和修改
  5. 批准合并

合并要求:
  - 所有 CI 检查通过
  - 至少 1 个代码审查批准
  - 无合并冲突
  - 文档已更新
  - 测试已通过
```

## 🧪 测试策略

### 测试分层

```yaml
单元测试 (Unit Tests):
  - 范围: 单个函数或组件
  - 工具: Jest + React Testing Library
  - 覆盖率: >80
  - 位置: __tests__/ 目录

集成测试 (Integration Tests):
  - 范围: 多个组件协作
  - 工具: Jest + Supertest
  - 重点: API 端点测试
  - 位置: tests/integration/

端到端测试 (E2E Tests):
  - 范围: 完整用户流程
  - 工具: Playwright
  - 重点: 关键业务流程
  - 位置: tests/e2e/
```

### 测试命令

```bash
# 运行所有测试
pnpm test

# 监视模式运行测试
pnpm test:watch

# 运行特定测试文件
pnpm test UserProfile.test.tsx

# 生成测试覆盖率报告
pnpm test --coverage

# 运行 E2E 测试
pnpm test:e2e

# 运行集成测试
pnpm test:integration
```

### 测试最佳实践

```yaml
单元测试:
  - 测试名称清晰描述测试场景
  - 使用 AAA 模式 (Arrange, Act, Assert)
  - 模拟外部依赖
  - 测试边界情况
  - 保持测试独立和快速

集成测试:
  - 测试组件间交互
  - 测试 API 端点
  - 使用真实数据库 (测试环境)
  - 验证数据流
  - 测试错误处理

E2E 测试:
  - 模拟真实用户操作
  - 测试完整业务流程
  - 验证用户界面
  - 测试响应式设计
  - 包含性能测试
```

## 🔍 代码质量控制

### 代码质量工具

```yaml
ESLint:
  - 配置: .eslintrc.js
  - 规则: 严格的 TypeScript 规则
  - 目标: 0 警告，0 错误
  - 自动修复: eslint --fix

Prettier:
  - 配置: .prettierrc
  - 作用: 代码格式化
  - 集成: ESLint 插件
  - 自动格式化: 编辑器保存时

TypeScript:
  - 配置: tsconfig.json
  - 模式: 严格模式
  - 目标: 类型安全
  - 检查: tsc --noEmit

Husky:
  - 配置: .husky/
  - 作用: Git hooks
  - 预提交: 代码检查和格式化
  - 预推送: 类型检查和测试
```

### 代码审查清单

```yaml
功能性审查:
  - [ ] 功能是否按需求实现
  - [ ] 边界情况是否处理
  - [ ] 错误处理是否完善
  - [ ] 性能是否满足要求
  - [ ] 安全性是否考虑

代码质量审查:
  - [ ] 代码是否清晰可读
  - [ ] 命名是否规范
  - [ ] 注释是否充分
  - [ ] 重复代码是否消除
  - [ ] 设计模式是否合理

测试审查:
  - [ ] 测试覆盖率是否达标
  - [ ] 测试用例是否充分
  - [ ] 测试是否可维护
  - [ ] 边界测试是否包含
  - [ ] 集成测试是否通过

文档审查:
  - [ ] API 文档是否更新
  - [ ] 组件文档是否完整
  - [ ] 配置文档是否准确
  - [ ] 变更记录是否记录
  - [ ] 使用示例是否提供
```

## 🚀 构建和部署

### 构建流程

```yaml
开发构建:
  - 命令: pnpm dev
  - 用途: 开发环境运行
  - 特性: 热重载、错误报告
  - 环境: development

生产构建:
  - 命令: pnpm build
  - 用途: 生产环境部署
  - 优化: 代码压缩、Tree Shaking
  - 环境: production

Docker 构建:
  - 命令: docker build
  - 用途: 容器化部署
  - 优化: 多阶段构建
  - 目标: 企业级镜像
```

### 部署环境

```yaml
开发环境:
  - 服务器: 本地或开发服务器
  - 数据库: localstorage
  - 配置: 环境变量
  - 访问: 内网访问

测试环境:
  - 服务器: Docker 容器
  - 数据库: Redis
  - 配置: 环境变量
  - 访问: 内网访问

生产环境:
  - 服务器: Docker Swarm/K8s
  - 数据库: Redis Cluster
  - 配置: 配置管理系统
  - 访问: 外网访问 + HTTPS
```

### 部署脚本

```bash
#!/bin/bash
# deploy.sh - 部署脚本

set -e

# 配置
ENVIRONMENT=${1:-development}
VERSION=${2:-latest}
REGISTRY="your-registry.com"

echo "🚀 开始部署 MoonTV ($ENVIRONMENT)"

# 1. 构建 Docker 镜像
echo "📦 构建 Docker 镜像..."
docker build -t moontv:$VERSION .
docker tag moontv:$VERSION $REGISTRY/moontv:$VERSION

# 2. 推送镜像
if [ "$ENVIRONMENT" != "development" ]; then
  echo "📤 推送镜像到 Registry..."
  docker push $REGISTRY/moontv:$VERSION
fi

# 3. 部署应用
echo "🔧 部署应用..."
if [ "$ENVIRONMENT" = "production" ]; then
  docker-compose -f docker-compose.prod.yml up -d
else
  docker-compose up -d
fi

# 4. 健康检查
echo "🏥 健康检查..."
sleep 10
curl -f http://localhost:3000/api/health || exit 1

echo "✅ 部署完成"
```

## 📊 监控和日志

### 应用监控

```yaml
性能监控:
  - 响应时间: API 响应时间监控
  - 吞吐量: 请求处理能力监控
  - 错误率: 错误发生率监控
  - 资源使用: CPU、内存使用监控

业务监控:
  - 用户活跃度: 用户使用情况
  - 功能使用率: 功能使用统计
  - 搜索性能: 搜索功能监控
  - 播放质量: 视频播放质量监控

基础设施监控:
  - 服务器状态: 服务器健康状态
  - 数据库性能: 数据库性能监控
  - 网络状态: 网络连接状态
  - 存储使用: 存储空间使用
```

### 日志管理

```yaml
日志级别:
  - ERROR: 错误信息
  - WARN: 警告信息
  - INFO: 一般信息
  - DEBUG: 调试信息

日志格式:
  - 时间戳: ISO 8601 格式
  - 级别: 日志级别
  - 模块: 代码模块
  - 消息: 日志消息
  - 上下文: 相关上下文信息

日志收集:
  - 应用日志: 结构化日志输出
  - 访问日志: HTTP 请求日志
  - 错误日志: 错误堆栈信息
  - 审计日志: 用户操作记录
```

## 🔧 开发工具配置

### VS Code 配置

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "typescript.preferences.importModuleSpecifier": "relative",
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "files.associations": {
    "*.css": "tailwindcss"
  }
}
```

### VS Code 推荐扩展

```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-typescript-next",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-json",
    "ms-vscode-remote.remote-containers",
    "ms-vscode.vscode-docker"
  ]
}
```

### Git 配置

```bash
# 用户信息配置
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 编辑器配置
git config --global core.editor "code --wait"

# 换行符配置
git config --global core.autocrlf false
git config --global core.safecrlf warn

# 分支默认配置
git config --global init.defaultBranch main
git config --global pull.rebase false
```

## 📚 文档管理

### 文档类型

```yaml
技术文档:
  - API 文档: OpenAPI/Swagger
  - 组件文档: Storybook
  - 架构文档: 系统设计文档
  - 配置文档: 环境配置说明

用户文档:
  - 用户手册: 功能使用说明
  - 部署指南: 部署步骤说明
  - 故障排除: 常见问题解决
  - 最佳实践: 使用建议

开发文档:
  - 开发指南: 开发环境搭建
  - 代码规范: 编码标准说明
  - 测试指南: 测试策略说明
  - 贡献指南: 开源贡献流程
```

### 文档更新流程

```yaml
触发条件:
  - 功能开发完成
  - API 变更
  - 配置变更
  - 流程变更

更新流程: 1. 更新相关文档
  2. 本地预览文档
  3. 提交文档变更
  4. 部署文档站点
  5. 通知团队变更

文档维护:
  - 定期审查: 每月审查文档准确性
  - 版本同步: 文档与代码版本同步
  - 用户反馈: 收集用户文档反馈
  - 持续改进: 根据反馈改进文档
```

## 🚨 故障处理

### 常见开发问题

```yaml
依赖问题:
  - 问题: pnpm install 失败
  - 解决: 清理缓存，重新安装
  - 预防: 锁定依赖版本

构建问题:
  - 问题: Next.js 构建失败
  - 解决: 检查类型错误，修复警告
  - 预防: 严格 TypeScript 配置

环境问题:
  - 问题: 环境变量配置错误
  - 解决: 检查 .env.local 配置
  - 预防: 使用环境变量模板

性能问题:
  - 问题: 应用响应缓慢
  - 解决: 性能分析和优化
  - 预防: 定期性能监控
```

### 应急响应流程

```yaml
问题识别:
  - 监控告警: 自动监控发现异常
  - 用户反馈: 用户报告问题
  - 定期检查: 主动健康检查
  - 测试验证: 功能测试发现问题

问题分类:
  - P0: 严重问题，影响核心功能
  - P1: 重要问题，影响用户体验
  - P2: 一般问题，功能缺陷
  - P3: 优化问题，性能改进

问题处理:
  - P0: 立即响应，紧急修复
  - P1: 4小时内响应，24小时内修复
  - P2: 24小时内响应，1周内修复
  - P3: 1周内响应，纳入迭代计划
```

## 🔮 持续改进

### 开发流程优化

```yaml
效率提升:
  - 自动化工具: 减少手工操作
  - 模板化: 标准化开发模板
  - 工具集成: 开发工具链集成
  - 流程简化: 简化审批流程

质量提升:
  - 代码审查: 更严格的代码审查
  - 自动化测试: 更全面的测试覆盖
  - 性能监控: 更细致的性能监控
  - 安全检查: 更严格的安全检查

协作优化:
  - 文档完善: 更详细的项目文档
  - 沟通机制: 更高效的团队沟通
  - 知识共享: 更好的知识管理
  - 培训体系: 更系统的技能培训
```

### 技术债务管理

```yaml
债务识别:
  - 代码审查: 代码审查中识别
  - 技术分析: 定期技术分析
  - 团队反馈: 开发团队反馈
  - 性能分析: 性能瓶颈分析

债务分类:
  - 代码质量: 代码风格、结构问题
  - 架构问题: 设计缺陷、技术选型
  - 测试问题: 测试覆盖、测试质量
  - 文档问题: 文档缺失、过时

债务处理:
  - 优先级排序: 按影响程度排序
  - 迭代计划: 纳入开发迭代
  - 专项处理: 安排专项优化
  - 持续改进: 长期改进计划
```

---

**开发流程特点**: 标准化、自动化、高质量
**管理策略**: Git Flow + DevOps + 持续改进
**文档更新**: 2025-10-14
**版本**: dev (永久开发版本)
