# MoonTV 开发规范 v5.0

**文档类型**: 开发规范  
**项目版本**: MoonTV v5.0.0-dev  
**文档版本**: v5.0  
**创建时间**: 2025 年 10 月 09 日  
**更新时间**: 2025 年 10 月 09 日  
**维护状态**: ✅ 生产就绪

## 🎯 编码原则

### 核心原则

- **可读性优先**: 代码应该易于理解和维护
- **一致性**: 保持代码风格和命名规范一致
- **简洁性**: 避免过度设计，保持简单有效
- **性能意识**: 注意代码性能影响

### TypeScript 规范

```typescript
// ✅ 正确示例
interface VideoConfig {
  id: string;
  title: string;
  url: string;
  isActive?: boolean;
}

const fetchVideo = async (id: string): Promise<VideoConfig | null> => {
  try {
    const response = await fetch(`/api/video/${id}`);
    if (!response.ok) return null;
    return response.json();
  } catch (error) {
    console.error('Failed to fetch video:', error);
    return null;
  }
};

// ❌ 错误示例
function getVideo(id) {
  return fetch('/api/video/' + id).then((res) => res.json());
}
```

### React 组件规范

```typescript
// ✅ 正确示例
interface VideoPlayerProps {
  videoUrl: string;
  title: string;
  onEnded?: () => void;
}

export const VideoPlayer: React.FC<VideoPlayerProps> = ({
  videoUrl,
  title,
  onEnded,
}) => {
  const [isPlaying, setIsPlaying] = useState(false);

  const handlePlay = useCallback(() => {
    setIsPlaying(true);
  }, []);

  return (
    <div className='video-player'>
      <h2 className='text-lg font-semibold'>{title}</h2>
      <video
        src={videoUrl}
        controls
        onPlay={handlePlay}
        onEnded={onEnded}
        className='w-full rounded-lg'
      />
    </div>
  );
};
```

## 📁 文件命名规范

### 组件文件

- **React 组件**: `PascalCase.tsx` (如 `VideoPlayer.tsx`)
- **组件样式**: `componentName.module.css`
- **组件测试**: `ComponentName.test.tsx`

### 工具文件

- **工具函数**: `camelCase.ts` (如 `videoUtils.ts`)
- **类型定义**: `camelCase.types.ts`
- **常量文件**: `UPPER_SNAKE_CASE.ts`

### 页面文件

- **页面组件**: `kebab-case/page.tsx` (如 `video-detail/page.tsx`)
- **布局组件**: `layout.tsx`
- **加载组件**: `loading.tsx`
- **错误组件**: `error.tsx`

## 🎨 样式规范

### Tailwind CSS 使用规范

```typescript
// ✅ 正确示例 - 使用 Tailwind 类名
<div className="flex flex-col items-center justify-center p-4 bg-gray-100 rounded-lg">
  <h1 className="text-2xl font-bold text-gray-800">Title</h1>
  <p className="text-gray-600 mt-2">Description</p>
</div>

// ✅ 组合使用条件类名
<div className={`
  px-4 py-2 rounded-lg font-medium transition-colors
  ${isActive
    ? 'bg-blue-500 text-white'
    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
  }
`}>
  Button
</div>
```

### CSS Modules 使用规范

```typescript
// styles/VideoPlayer.module.css
.container {
  @apply flex flex-col items-center justify-center;
}

.title {
  @apply text-2xl font-bold text-gray-800;
}

// VideoPlayer.tsx
import styles from './VideoPlayer.module.css'

export const VideoPlayer = () => {
  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Video Title</h1>
    </div>
  )
}
```

## 🔧 Git 提交规范

### 提交消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型说明

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建工具或辅助工具的变动

### 示例

```bash
feat(search): 添加视频搜索功能

- 实现多源并行搜索
- 添加搜索结果缓存
- 支持搜索历史记录

Closes #123
```

## 📝 代码质量检查

### ESLint 规则

```json
{
  "extends": ["next/core-web-vitals", "@typescript-eslint/recommended"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "prefer-const": "error",
    "no-console": "warn",
    "eqeqeq": "error"
  }
}
```

### Prettier 配置

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
```

## 🧪 测试规范

### 单元测试

```typescript
// VideoCard.test.tsx
import { render, screen } from '@testing-library/react';
import { VideoCard } from './VideoCard';

describe('VideoCard', () => {
  it('should render video title', () => {
    const mockVideo = {
      id: '1',
      title: 'Test Video',
      url: 'https://example.com/video.mp4',
    };

    render(<VideoCard video={mockVideo} />);

    expect(screen.getByText('Test Video')).toBeInTheDocument();
  });
});
```

### API 测试

```typescript
// api/videos.test.ts
import { createMocks } from 'node-mocks-http';
import handler from './videos';

describe('/api/videos', () => {
  it('should return video list', async () => {
    const { req, res } = createMocks({ method: 'GET' });

    await handler(req, res);

    expect(res._getStatusCode()).toBe(200);
    const data = JSON.parse(res._getData());
    expect(Array.isArray(data.videos)).toBe(true);
  });
});
```

## 🏗️ 项目结构规范

### 目录结构

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # API 路由
│   │   └── [route]/       # 具体路由
│   ├── [category]/        # 页面分类
│   │   ├── [id]/         # 动态路由
│   │   ├── page.tsx      # 页面组件
│   │   ├── loading.tsx   # 加载组件
│   │   └── error.tsx     # 错误组件
│   ├── layout.tsx         # 根布局
│   └── globals.css        # 全局样式
├── components/            # React 组件
│   ├── ui/               # 基础 UI 组件
│   ├── forms/            # 表单组件
│   └── layout/           # 布局组件
├── lib/                  # 工具库
│   ├── types.ts          # 类型定义
│   ├── utils.ts          # 工具函数
│   ├── constants.ts      # 常量定义
│   └── hooks/            # 自定义 Hooks
├── styles/               # 样式文件
│   └── globals.css       # 全局样式
└── types/               # 类型定义
    └── index.ts         # 导出所有类型
```

### 组件组织

```typescript
// components/ui/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
  onClick?: () => void;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  children,
  onClick,
}) => {
  const baseClasses = 'font-medium rounded-lg transition-colors';
  const variantClasses = {
    primary: 'bg-blue-500 text-white hover:bg-blue-600',
    secondary: 'bg-gray-200 text-gray-700 hover:bg-gray-300',
  };
  const sizeClasses = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

## 🚀 性能优化规范

### React 性能优化

```typescript
// ✅ 使用 React.memo 优化组件重渲染
export const VideoCard = React.memo<VideoCardProps>(({ video }) => {
  return (
    <div className='video-card'>
      <h3>{video.title}</h3>
    </div>
  );
});

// ✅ 使用 useMemo 优化计算
const ExpensiveComponent = ({ items }: { items: Item[] }) => {
  const sortedItems = useMemo(
    () => items.sort((a, b) => a.name.localeCompare(b.name)),
    [items]
  );

  return <div>{/* 渲染排序后的项目 */}</div>;
};

// ✅ 使用 useCallback 优化函数引用
const ParentComponent = () => {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    setCount((c) => c + 1);
  }, []);

  return <ChildComponent onClick={handleClick} />;
};
```

### Next.js 性能优化

```typescript
// ✅ 动态导入组件
import dynamic from 'next/dynamic';

const VideoPlayer = dynamic(() => import('./VideoPlayer'), {
  loading: () => <div>Loading...</div>,
  ssr: false, // 仅客户端渲染
});

// ✅ 使用 generateMetadata 进行 SEO 优化
export async function generateMetadata({ params }: { params: { id: string } }) {
  const video = await getVideo(params.id);

  return {
    title: video.title,
    description: video.description,
    openGraph: {
      title: video.title,
      images: [video.thumbnail],
    },
  };
}
```

## 🔒 安全编码规范

### 输入验证

```typescript
// ✅ 验证用户输入
const validateSearchQuery = (query: string): string => {
  // 清理和验证输入
  const cleaned = query.trim().replace(/[<>]/g, '');

  if (cleaned.length === 0 || cleaned.length > 100) {
    throw new Error('Invalid search query');
  }

  return cleaned;
};

// ✅ 防止 XSS 攻击
const sanitizeInput = (input: string): string => {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};
```

### API 安全

```typescript
// ✅ 验证 API 请求
import { NextRequest } from 'next/server';

export async function GET(request: NextRequest) {
  // 验证请求来源
  const origin = request.headers.get('origin');
  const allowedOrigins = ['http://localhost:3000', 'https://yourdomain.com'];

  if (!allowedOrigins.includes(origin || '')) {
    return new Response('Forbidden', { status: 403 });
  }

  // 验证请求参数
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q');

  if (!query || query.length > 100) {
    return new Response('Bad Request', { status: 400 });
  }

  // 处理请求
  // ...
}
```

## 📊 代码审查检查清单

### 功能性检查

- [ ] 代码实现了需求规格中的所有功能
- [ ] 边界条件和错误情况得到处理
- [ ] 性能满足要求
- [ ] 安全漏洞得到修复

### 代码质量检查

- [ ] 代码结构清晰，易于理解
- [ ] 变量和函数命名具有描述性
- [ ] 没有重复代码
- [ ] 遵循项目编码规范

### 测试检查

- [ ] 单元测试覆盖核心功能
- [ ] 集成测试验证组件交互
- [ ] E2E 测试覆盖关键用户流程
- [ ] 测试用例覆盖边界情况

### 文档检查

- [ ] 代码注释清晰准确
- [ ] API 文档完整
- [ ] README 文件更新
- [ ] 变更日志记录

## 🔄 v5.0 更新内容

### 新增规范

- **记忆系统集成**: v5.0 企业级知识管理规范
- **Docker 开发**: 容器化开发环境规范
- **安全编码**: 增强的安全编码标准
- **性能优化**: 新增性能优化最佳实践

### 改进内容

- **TypeScript 规范**: 更严格的类型检查
- **React 组件**: 更清晰的组件组织方式
- **测试规范**: 完善的测试覆盖要求
- **Git 工作流**: 标准化的提交规范

### 工具链更新

- **ESint 配置**: 更新至最新规则
- **Prettier 配置**: 统一代码格式
- **TypeScript**: 升级至 5.5.3
- **测试框架**: Jest 和 Playwright 最新版本

## 📚 相关资源

### 官方文档

- **React 文档**: https://react.dev/
- **Next.js 文档**: https://nextjs.org/docs
- **TypeScript 手册**: https://www.typescriptlang.org/docs/
- **Tailwind CSS**: https://tailwindcss.com/docs

### 工具文档

- **ESLint 规则**: https://eslint.org/docs/rules/
- **Prettier 配置**: https://prettier.io/docs/options/
- **Jest 测试**: https://jestjs.io/docs/getting-started
- **Playwright E2E**: https://playwright.dev/

### 项目相关

- **项目核心信息**: `moontv_core_project_info_v5_0.md`
- **开发环境配置**: `moontv_dev_environment_standards_v5_0.md`
- **质量保证指南**: `moontv_quality_assurance_testing_v5_0.md`
- **记忆系统**: `moonTV_memory_master_index_v5_0.md`

---

**文档维护**: 开发规范随项目更新同步  
**最后更新**: 2025 年 10 月 09 日  
**适用版本**: MoonTV v5.0.0-dev  
**文档状态**: ✅ 生产就绪
