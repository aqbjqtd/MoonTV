# MoonTV 开发规范 v4.1

**文档类型**: 开发规范  
**项目版本**: MoonTV v4.1.0-dev  
**文档版本**: v4.1  
**创建时间**: 2025-10-09

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

---

**最后更新**: 2025-10-09  
**适用版本**: MoonTV v4.1.0-dev
