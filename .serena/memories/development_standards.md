# MoonTV 开发规范

**记忆类型**: 开发规范  
**创建时间**: 2025-12-12  
**最后更新**: 2025-12-12  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 技术架构, 项目概览, 功能模块  
**语义标签**: 编码规范, 工作流程, 质量标准, 最佳实践  
**索引关键词**: TypeScript 规范, ESLint, Prettier, Git 工作流, 测试规范, 组件开发

## 概述

MoonTV 项目的开发规范、工作流程、代码质量标准和最佳实践指南，确保代码一致性、可维护性和团队协作效率。

## 开发环境设置

### 环境准备

#### 1. 系统要求

- **Node.js**: 20.x 或更高版本
- **包管理器**: pnpm 10.14.0 (推荐) 或 npm/yarn
- **Git**: 2.x 或更高版本
- **操作系统**: Windows/macOS/Linux (推荐 Linux 或 WSL2)

#### 2. 环境配置

```bash
# 克隆仓库
git clone https://github.com/stardm0/MoonTV.git
cd MoonTV

# 安装依赖 (推荐使用pnpm)
pnpm install

# 复制环境变量模板
cp .env.example .env.local

# 编辑环境变量
vim .env.local  # 或使用其他编辑器
```

#### 3. 启动开发环境

```bash
# 启动开发服务器 (监听所有网络接口)
pnpm dev

# 访问应用
# 浏览器打开: http://localhost:3000
```

### 开发工具推荐

#### 编辑器配置

- **VS Code**: 推荐使用，安装以下扩展：
  - ESLint
  - Prettier
  - Tailwind CSS IntelliSense
  - TypeScript 和 JavaScript 语言特性
  - GitLens

#### 浏览器工具

- **React Developer Tools**: React 组件调试
- **Redux DevTools**: 状态管理调试 (如使用)
- **Lighthouse**: 性能和质量审计

## 核心开发命令

### 开发相关

```bash
# 开发环境 (监听所有网络接口)
pnpm dev                    # 启动开发服务器 0.0.0.0:3000

# 生产环境
pnpm build                  # 生产构建 (包含manifest和runtime生成)
pnpm start                  # 启动生产服务器
pnpm pages:build           # Cloudflare Pages构建
```

### 代码质量检查

```bash
pnpm lint                   # ESLint代码检查
pnpm lint:fix              # 自动修复代码问题
pnpm lint:strict           # 严格模式检查 (max-warnings=0)
pnpm typecheck             # TypeScript类型检查
pnpm format                # Prettier代码格式化
pnpm format:check          # 检查代码格式化
```

### 测试相关

```bash
pnpm test                  # Jest单元测试
pnpm test:watch            # 测试监听模式
pnpm test:coverage         # 测试覆盖率报告
```

### 代码生成

```bash
pnpm gen:manifest          # PWA清单生成
pnpm gen:runtime           # 运行时配置生成
```

### Git 相关

```bash
# 提交前自动检查 (通过Husky配置)
git add .                  # 添加更改
git commit -m "feat: 添加新功能"  # 提交更改
git push                   # 推送更改
```

## 代码质量标准

### TypeScript 规范

#### 基本规则

- **严格模式**: 必须启用 `strict: true`
- **类型覆盖率**: 目标 >95%
- **避免 any 类型**: 尽量减少使用 `any`，使用具体类型或 `unknown`
- **明确的类型**: 避免隐式类型，显式定义类型

#### 类型定义最佳实践

```typescript
// 优先使用接口定义对象类型
interface User {
  id: string;
  name: string;
  email: string;
}

// 使用类型别名定义复杂类型
type ApiResponse<T> = {
  success: boolean;
  data?: T;
  error?: string;
};

// 使用泛型提高复用性
function processItems<T>(items: T[]): T[] {
  return items.filter((item) => item != null);
}

// 使用联合类型和交叉类型
type AdminUser = User & { role: 'admin' };
type Status = 'pending' | 'approved' | 'rejected';
```

#### 导入导出规范

```typescript
// 默认导出 (用于组件)
export default ComponentName;

// 命名导出 (用于工具函数、常量、类型)
export { functionName, CONSTANT_VALUE };
export type { User, ApiResponse };

// 避免通配符导入
// ❌ 避免: import * as utils from './utils';
// ✅ 推荐: import { formatDate, parseJSON } from './utils';
```

### ESLint 规则配置

#### 核心规则

- **代码风格**: 使用单引号，强制分号，最大行长度 100 字符
- **代码质量**: 禁止未使用的变量和导入，函数最大参数 3 个
- **React 规则**: Hook 规则，JSX 规则，组件命名规则
- **TypeScript 规则**: 类型安全规则，接口命名规则

#### 配置文件

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    'max-len': ['error', { code: 100 }],
    'no-console': ['warn', { allow: ['warn', 'error'] }],
  },
};
```

### Prettier 配置

#### 格式化规则

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

#### 集成配置

- **编辑器集成**: 保存时自动格式化
- **Git Hooks**: 提交前自动格式化
- **CI/CD**: 构建时检查代码格式

## Git 工作流程

### Git 操作方向标准 (重要)

#### 核心方向定义

**拉取/同步操作 (从上游到本地)**

```
本地仓库 ← 上游仓库/远程仓库
```

**标准操作和描述:**

- ✅ **正确**: "从上游同步到本地"
- ✅ **正确**: "本地从上游获取更新"
- ✅ **正确**: "让本地与上游保持一致"
- ✅ **正确**: "同步上游标签到本地"

**错误描述示例:**

- ❌ **错误**: "同步上游到本地" (方向模糊)
- ❌ **错误**: "更新上游" (方向错误)

**推送操作 (从本地到远程)**

```
上游仓库/远程仓库 ← 本地仓库
```

**标准操作和描述:**

- ✅ **正确**: "推送本地更改到远程"
- ✅ **正确**: "将本地分支推送到远程"
- ✅ **正确**: "发布本地标签到远程"

**常见操作场景:**

1. **定期同步上游更新**

   ```bash
   git fetch upstream
   git merge upstream/main
   ```

   标准描述: "定期从上游仓库同步更新到本地"

2. **标签管理**

   ```bash
   git tag -d dev  # 删除本地标签
   git fetch upstream --tags --force  # 从上游强制同步标签
   ```

   标准描述: "删除本地 dev 标签，然后从上游同步标签到本地"

3. **发布推送**
   ```bash
   git push origin main
   git push origin --tags
   ```
   标准描述: "推送本地开发成果到远程仓库"

### 分支策略

### 分支策略

#### 主要分支

- **main**: 生产分支，受保护，只接受合并
- **develop**: 开发分支，功能集成分支
- **release/\***: 发布分支，版本发布准备
- **hotfix/\***: 热修复分支，紧急 bug 修复

#### 功能分支

- **feature/\***: 新功能开发
- **bugfix/\***: bug 修复
- **refactor/\***: 代码重构
- **docs/\***: 文档更新

### 提交规范

#### 提交消息格式

```
<type>: <subject>

<body>

<footer>
```

#### 提交类型

- **feat**: 新功能
- **fix**: 修复 bug
- **docs**: 文档更新
- **style**: 代码格式变更 (不影响功能)
- **refactor**: 代码重构 (既不修复 bug 也不增加功能)
- **test**: 测试相关
- **chore**: 构建过程或辅助工具的变动
- **perf**: 性能优化
- **ci**: CI/CD 相关

#### 提交示例

```bash
# 新功能
feat: 添加用户认证系统

# Bug修复
fix: 修复播放进度同步问题

# 文档更新
docs: 更新部署指南

# 代码重构
refactor: 重构存储抽象层接口
```

### Git Hooks 配置

#### pre-commit

- 运行 ESLint 检查
- 运行 Prettier 格式化
- 运行类型检查 (可选)

#### commit-msg

- 验证提交消息格式
- 使用 commitlint 规范

#### pre-push

- 运行测试套件
- 确保所有测试通过

## 组件开发规范

### 组件命名

#### 文件命名

- 使用 PascalCase 命名组件文件: `ComponentName.tsx`
- 组件名称与文件名保持一致
- 使用描述性名称，避免缩写

#### 示例

```
✅ VideoCard.tsx          # 视频卡片组件
✅ EpisodeSelector.tsx    # 剧集选择器组件
✅ SearchSuggestions.tsx  # 搜索建议组件
❌ card.tsx              # 不明确
❌ epSel.tsx             # 缩写不推荐
```

### 组件结构

#### 标准组件结构

```typescript
import React from 'react';
import { SomeType } from '@/lib/types';

// Props接口定义
interface ComponentProps {
  title: string;
  items: SomeType[];
  onSelect?: (item: SomeType) => void;
  className?: string;
}

// 组件实现
export const ComponentName: React.FC<ComponentProps> = ({
  title,
  items,
  onSelect,
  className = '',
}) => {
  // 状态和副作用
  const [selected, setSelected] = React.useState<SomeType | null>(null);

  // 事件处理
  const handleSelect = (item: SomeType) => {
    setSelected(item);
    onSelect?.(item);
  };

  // 渲染逻辑
  return (
    <div className={`container ${className}`}>
      <h2>{title}</h2>
      <div className='items-list'>
        {items.map((item) => (
          <ItemCard
            key={item.id}
            item={item}
            isSelected={selected?.id === item.id}
            onSelect={handleSelect}
          />
        ))}
      </div>
    </div>
  );
};

// 默认导出
export default ComponentName;
```

#### Props 设计原则

- 使用 TypeScript 接口明确定义 props
- 提供合理的默认值
- 避免过多的 props 参数 (>5 个考虑拆分)
- 使用解构赋值接收 props
- 可选参数使用 `?` 标记

### 组件分类

#### 布局组件

- 负责页面布局和结构
- 通常包含其他组件
- 示例: `Layout`, `Sidebar`, `Header`

#### 业务组件

- 包含具体业务逻辑
- 与数据流和状态管理集成
- 示例: `VideoCard`, `SearchResults`, `Player`

#### UI 组件

- 可复用的 UI 元素
- 无业务逻辑或极少业务逻辑
- 示例: `Button`, `Modal`, `Input`, `Card`

#### 容器组件

- 负责数据获取和状态管理
- 传递数据给展示组件
- 示例: `VideoContainer`, `UserProfileContainer`

## API 开发规范

### RESTful API 设计

#### 资源命名

- 使用复数名词: `/api/videos`, `/api/users`
- 嵌套资源: `/api/users/{userId}/videos`
- 动作使用 HTTP 方法，不是 URL 路径

#### HTTP 方法语义

- **GET**: 获取资源
- **POST**: 创建资源
- **PUT**: 更新整个资源
- **PATCH**: 部分更新资源
- **DELETE**: 删除资源

#### 响应格式

##### 成功响应

```json
{
  "success": true,
  "data": {
    "id": "123",
    "name": "视频名称"
  },
  "message": "操作成功"
}
```

##### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "输入验证失败",
    "details": {
      "field": "email",
      "message": "邮箱格式不正确"
    }
  }
}
```

### 输入验证

#### Zod 验证示例

```typescript
import { z } from 'zod';

// 验证模式
const UserSchema = z.object({
  name: z.string().min(2).max(50),
  email: z.string().email(),
  age: z.number().int().min(0).max(150).optional(),
});

// 使用验证
const validatedData = UserSchema.parse(requestBody);
```

#### 验证规则

- 验证所有用户输入
- 清理和转义特殊字符
- 限制请求大小和频率
- 使用白名单验证允许的输入

### 错误处理

#### 统一错误处理中间件

```typescript
// 错误处理中间件示例
export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  console.error('API Error:', err);

  if (err instanceof ValidationError) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: err.message,
        details: err.details,
      },
    });
  }

  // 其他错误类型处理...

  // 默认错误
  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: '内部服务器错误',
    },
  });
}
```

## 测试规范

### 测试文件组织

#### 测试文件位置

```
src/
├── components/
│   ├── VideoCard.tsx
│   └── VideoCard.test.tsx    # 测试文件与源文件同级
└── __tests__/               # 或集中测试目录
    └── integration/         # 集成测试
```

#### 测试文件命名

- 单元测试: `ComponentName.test.ts` 或 `ComponentName.spec.ts`
- 集成测试: `integration.test.ts`
- E2E 测试: `e2e.test.ts`

### 测试覆盖率目标

#### 覆盖率指标

- **语句覆盖率**: >80%
- **分支覆盖率**: >70%
- **函数覆盖率**: >85%
- **行覆盖率**: >80%

#### 覆盖率报告

```bash
# 生成覆盖率报告
pnpm test:coverage

# 查看HTML报告
open coverage/lcov-report/index.html
```

### 测试类型

#### 单元测试

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import VideoCard from '@/components/VideoCard';

describe('VideoCard', () => {
  it('显示视频标题', () => {
    const video = { id: '1', title: '测试视频', description: '描述' };
    render(<VideoCard video={video} />);
    expect(screen.getByText('测试视频')).toBeInTheDocument();
  });

  it('点击卡片触发回调', () => {
    const handleClick = jest.fn();
    const video = { id: '1', title: '测试视频' };
    render(<VideoCard video={video} onClick={handleClick} />);
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledWith(video);
  });
});
```

#### 集成测试

```typescript
describe('搜索功能', () => {
  it('搜索并显示结果', async () => {
    // 模拟API响应
    mockSearchAPI.mockResolvedValue({ videos: [...] });

    // 渲染搜索页面
    render(<SearchPage />);

    // 输入搜索词
    fireEvent.change(screen.getByPlaceholderText('搜索视频'), {
      target: { value: '电影' }
    });

    // 点击搜索按钮
    fireEvent.click(screen.getByText('搜索'));

    // 验证结果显示
    await waitFor(() => {
      expect(screen.getByText('搜索结果')).toBeInTheDocument();
    });
  });
});
```

#### E2E 测试

```typescript
// 使用Playwright或Cypress
describe('用户流程', () => {
  it('用户可以搜索并播放视频', async () => {
    await page.goto('http://localhost:3000');
    await page.fill('input[placeholder="搜索视频"]', '电影');
    await page.click('button:has-text("搜索")');
    await page.waitForSelector('.video-card');
    await page.click('.video-card:first-child');
    await page.waitForSelector('.player-container');
    expect(await page.isVisible('.player-container')).toBeTruthy();
  });
});
```

### 测试最佳实践

#### 测试组织

- 每个测试文件一个描述块
- 使用清晰的测试描述
- 遵循 AAA 模式 (Arrange, Act, Assert)
- 避免测试依赖和共享状态

#### 模拟和桩

- 模拟外部 API 调用
- 模拟文件系统和数据库
- 使用适当的测试数据工厂
- 清理测试后的状态

## 文档规范

### 代码注释

#### JSDoc 注释

```typescript
/**
 * 获取用户信息
 * @param userId - 用户ID
 * @param includeDetails - 是否包含详细信息
 * @returns 用户信息对象
 * @throws {UserNotFoundError} 用户不存在时抛出
 * @example
 * const user = await getUser('123', true);
 */
async function getUser(userId: string, includeDetails = false): Promise<User> {
  // 实现...
}
```

#### 行内注释

```typescript
// 计算缓存过期时间 (24小时)
const cacheExpiry = Date.now() + 24 * 60 * 60 * 1000;

// TODO: 未来优化 - 实现LRU缓存策略
// FIXME: 临时解决方案 - 需要重构错误处理
// NOTE: 重要 - 此函数有副作用，使用需谨慎
```

### 项目文档

#### README.md 结构

1. 项目标题和徽章
2. 功能特性列表
3. 快速开始指南
4. 部署说明
5. 配置指南
6. 开发指南
7. 贡献指南
8. 许可证信息

#### API 文档

- 使用 OpenAPI 规范 (Swagger)
- 提供 API 端点详细说明
- 包含请求/响应示例
- 提供错误代码说明

## 部署规范

### 部署前检查清单

#### 代码质量

- [ ] 所有测试通过
- [ ] TypeScript 类型检查通过
- [ ] ESLint 检查通过
- [ ] 构建成功
- [ ] 代码覆盖率达标

#### 环境配置

- [ ] 环境变量配置正确
- [ ] 数据库迁移完成
- [ ] 存储后端连接正常
- [ ] 域名和 SSL 证书配置

#### 安全配置

- [ ] 管理员密码设置
- [ ] 安全 HTTP 头部配置
- [ ] 访问控制配置
- [ ] 日志和监控配置

### 部署策略

#### 开发环境

- 自动部署到预览环境
- 每次提交触发构建
- 使用测试数据库

#### 测试环境

- 手动部署，充分测试
- 模拟生产环境配置
- 性能和安全测试

#### 生产环境

- 蓝绿部署或金丝雀发布
- 逐步流量切换
- 回滚计划准备

### 监控和日志

#### 应用监控

- 性能监控 (响应时间，错误率)
- 业务指标监控 (用户数，播放数)
- 资源使用监控 (CPU，内存，磁盘)

#### 日志记录

- 访问日志记录
- 错误日志记录
- 审计日志记录
- 性能日志记录

## 团队协作规范

### 代码审查

#### 审查要点

- 代码质量和可读性
- 功能正确性和完整性
- 测试覆盖率和质量
- 安全性和性能影响
- 文档完整性和准确性

#### 审查流程

1. 创建 Pull Request
2. 自动检查运行 (CI/CD)
3. 团队成员审查
4. 问题讨论和修复
5. 批准和合并

### 知识共享

#### 文档维护

- 及时更新开发文档
- 记录技术决策和问题解决
- 分享最佳实践和经验教训

#### 代码学习

- 定期代码审查会议
- 技术分享会
- 结对编程和代码走查

## 更新历史

- 2025-12-12: 创建开发规范记忆文件，基于项目记忆管理器新规则重构
- 2025-12-09: 更新 TypeScript 和 ESLint 配置
- 2025-11-01: 完善测试规范和覆盖率要求
- 2025-10-15: 建立完整的 Git 工作流程和提交规范
