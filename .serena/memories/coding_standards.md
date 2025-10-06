# MoonTV 开发规范与最佳实践

## 📝 代码规范

### TypeScript规范

#### 类型定义
```typescript
// ✅ 推荐：使用interface定义对象结构
export interface SearchResult {
  id: string;
  title: string;
  poster: string;
  episodes: string[];
  source: string;
}

// ✅ 推荐：使用type定义联合类型
export type StorageType = 'localstorage' | 'redis' | 'd1' | 'upstash';

// ❌ 避免：使用any
// Bad: function process(data: any)
// Good: function process(data: SearchResult)

// ✅ 推荐：使用泛型提高复用性
interface IStorage<T = unknown> {
  get(key: string): Promise<T | null>;
  set(key: string, value: T): Promise<void>;
}
```

#### 命名约定
```typescript
// 接口：I前缀
interface IStorage { }

// 类型：PascalCase
type StorageType = 'redis' | 'upstash';

// 组件：PascalCase
export function VideoCard() { }

// 函数：camelCase
export async function fetchVideoDetail() { }

// 常量：UPPER_SNAKE_CASE
const MAX_SEARCH_RESULTS = 100;

// 私有变量：_前缀（可选）
const _internalCache = new Map();
```

### React组件规范

#### 组件结构
```typescript
// ✅ 推荐的组件结构
'use client'; // 客户端组件标记（如需要）

import { useState, useEffect } from 'react';
import { ComponentProps } from './types'; // 类型导入

// Props接口定义
interface VideoCardProps {
  title: string;
  poster: string;
  onClick?: () => void;
}

// 组件实现
export function VideoCard({ title, poster, onClick }: VideoCardProps) {
  // 1. Hooks
  const [isHovered, setIsHovered] = useState(false);
  
  // 2. 事件处理函数
  const handleClick = () => {
    onClick?.();
  };
  
  // 3. 副作用
  useEffect(() => {
    // ...
  }, []);
  
  // 4. 渲染
  return (
    <div onClick={handleClick}>
      {/* JSX */}
    </div>
  );
}
```

#### Server/Client组件选择
```typescript
// ✅ Server Component（默认）
// - 数据获取
// - 访问后端资源
// - SEO优化
export async function HomePage() {
  const config = await getConfig();
  return <div>{config.siteName}</div>;
}

// ✅ Client Component
// - 交互状态
// - 浏览器API
// - 事件监听
'use client';
export function ThemeToggle() {
  const [theme, setTheme] = useState('dark');
  return <button onClick={() => setTheme('light')}>Toggle</button>;
}
```

### CSS与样式规范

#### Tailwind CSS最佳实践
```typescript
// ✅ 推荐：使用clsx和tailwind-merge
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// 使用
<div className={cn(
  'base-class',
  isActive && 'active-class',
  'override-class'
)} />

// ✅ 推荐：响应式设计
<div className="flex flex-col lg:flex-row gap-4">
  {/* 移动端纵向，桌面端横向 */}
</div>

// ✅ 推荐：主题变量
<div className="bg-white dark:bg-black text-gray-900 dark:text-gray-200">
  {/* 自动适配主题 */}
</div>
```

#### 自定义样式
```css
/* ✅ 推荐：使用CSS变量 */
:root {
  --primary-color: #3b82f6;
  --background: white;
}

.dark {
  --background: black;
}

/* ✅ 推荐：模块化CSS（如需要） */
.component {
  @apply flex items-center gap-2;
}
```

---

## 🏗 架构模式

### API路由设计

#### RESTful风格
```typescript
// ✅ 推荐的API路由结构
src/app/api/
├── [resource]/
│   ├── route.ts          # GET /api/resource, POST /api/resource
│   └── [id]/
│       └── route.ts      # GET /api/resource/:id, PUT /api/resource/:id

// 示例：用户收藏
/api/favorites              # GET: 获取列表, POST: 添加收藏
/api/favorites/[id]         # DELETE: 删除收藏
```

#### Edge Runtime使用
```typescript
// ✅ 推荐：API路由使用Edge Runtime
export const runtime = 'edge';

export async function GET(request: Request) {
  // Edge函数优势：
  // 1. 快速冷启动
  // 2. 全球分布
  // 3. 低延迟
  return Response.json({ data: 'hello' });
}
```

### 数据抽象层

#### 存储接口实现
```typescript
// ✅ 推荐：实现IStorage接口
export class RedisStorage implements IStorage {
  private client: Redis;
  
  async getPlayRecord(userName: string, key: string): Promise<PlayRecord | null> {
    const data = await this.client.get(`playrecord:${userName}:${key}`);
    return data ? JSON.parse(data) : null;
  }
  
  async setPlayRecord(userName: string, key: string, record: PlayRecord): Promise<void> {
    await this.client.set(
      `playrecord:${userName}:${key}`,
      JSON.stringify(record)
    );
  }
}

// ✅ 推荐：工厂模式创建存储实例
export function getStorage(): IStorage {
  const type = process.env.NEXT_PUBLIC_STORAGE_TYPE;
  switch (type) {
    case 'redis': return new RedisStorage();
    case 'upstash': return new UpstashStorage();
    case 'd1': return new D1Storage();
    default: throw new Error('Invalid storage type');
  }
}
```

---

## 🔒 安全实践

### 认证与授权

#### JWT最佳实践
```typescript
// ✅ 推荐：使用httpOnly Cookie
export async function createSession(userName: string, role: string) {
  const token = await sign({ userName, role }, JWT_SECRET, {
    expiresIn: '7d',
  });
  
  cookies().set('auth-token', token, {
    httpOnly: true,    // 防止XSS
    secure: true,      // 仅HTTPS
    sameSite: 'lax',   // CSRF保护
    maxAge: 7 * 24 * 60 * 60, // 7天
  });
}

// ✅ 推荐：中间件验证Token
export async function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token');
  if (!token) {
    return NextResponse.redirect('/login');
  }
  
  const payload = await verify(token.value, JWT_SECRET);
  // 验证通过，继续请求
}
```

#### 权限检查
```typescript
// ✅ 推荐：细粒度权限控制
export async function checkPermission(request: Request, requiredRole: string) {
  const user = await getCurrentUser(request);
  
  if (!user) {
    throw new UnauthorizedError();
  }
  
  if (user.role !== requiredRole && user.role !== 'admin') {
    throw new ForbiddenError();
  }
  
  return user;
}
```

### 输入验证

#### Zod验证
```typescript
// ✅ 推荐：使用Zod验证请求数据
import { z } from 'zod';

const LoginSchema = z.object({
  userName: z.string().min(3).max(20),
  password: z.string().min(6),
});

export async function POST(request: Request) {
  const body = await request.json();
  
  // 验证输入
  const result = LoginSchema.safeParse(body);
  if (!result.success) {
    return Response.json({ error: result.error }, { status: 400 });
  }
  
  const { userName, password } = result.data;
  // 处理登录...
}
```

---

## 🎯 性能优化

### 前端优化

#### 图片优化
```typescript
// ✅ 推荐：使用next/image
import Image from 'next/image';

<Image
  src={poster}
  alt={title}
  width={300}
  height={400}
  loading="lazy"        // 懒加载
  placeholder="blur"    // 模糊占位符
  blurDataURL={blurUrl} // 低质量占位图
/>

// ✅ 推荐：自定义图片加载器（如需要）
export default function ImageLoader({ src, width, quality }) {
  return `https://cdn.example.com/${src}?w=${width}&q=${quality || 75}`;
}
```

#### 代码分割
```typescript
// ✅ 推荐：动态导入非关键组件
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <LoadingSkeleton />,
  ssr: false, // 仅客户端渲染
});

// ✅ 推荐：路由级代码分割（自动）
// Next.js自动为每个页面生成单独bundle
```

### 后端优化

#### 并行请求
```typescript
// ✅ 推荐：并行调用独立API
async function searchAllSources(keyword: string) {
  const sources = Object.values(apiSites);
  
  // 并行请求所有资源站
  const results = await Promise.allSettled(
    sources.map(source => fetchFromSource(source, keyword))
  );
  
  // 过滤成功的结果
  return results
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value);
}
```

#### 缓存策略
```typescript
// ✅ 推荐：多层缓存
import { cache } from 'react';

// React缓存（请求级）
export const getConfig = cache(async () => {
  return await fetchConfigFromDB();
});

// Redis缓存（应用级）
export async function getCachedData(key: string) {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);
  
  const fresh = await fetchFreshData();
  await redis.set(key, JSON.stringify(fresh), { ex: 3600 });
  return fresh;
}
```

---

## 🧪 测试规范

### 单元测试
```typescript
// ✅ 推荐的测试结构
import { render, screen } from '@testing-library/react';
import { VideoCard } from './VideoCard';

describe('VideoCard', () => {
  it('应该正确渲染标题和海报', () => {
    render(<VideoCard title="Test" poster="/test.jpg" />);
    
    expect(screen.getByText('Test')).toBeInTheDocument();
    expect(screen.getByRole('img')).toHaveAttribute('src', '/test.jpg');
  });
  
  it('点击时应该调用onClick回调', () => {
    const handleClick = jest.fn();
    render(<VideoCard title="Test" onClick={handleClick} />);
    
    screen.getByText('Test').click();
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### API测试
```typescript
// ✅ 推荐：Mock外部依赖
jest.mock('@/lib/db', () => ({
  getStorage: () => ({
    getFavorite: jest.fn().mockResolvedValue({ title: 'Test' }),
  }),
}));

describe('GET /api/favorites', () => {
  it('应该返回用户收藏列表', async () => {
    const response = await GET(mockRequest);
    const data = await response.json();
    
    expect(response.status).toBe(200);
    expect(data).toHaveLength(1);
  });
});
```

---

## 📦 部署规范

### 环境变量管理
```bash
# ✅ 推荐：分层环境变量

# 必需环境变量（所有部署）
PASSWORD=your_secure_password

# 可选环境变量（功能开关）
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_STORAGE_TYPE=localstorage
NEXT_PUBLIC_ENABLE_REGISTER=false

# 存储配置（按需）
# Redis
REDIS_URL=redis://localhost:6379

# Upstash
UPSTASH_URL=https://...
UPSTASH_TOKEN=...

# 豆瓣代理（可选）
NEXT_PUBLIC_DOUBAN_PROXY_TYPE=direct
```

### Docker最佳实践
```dockerfile
# ✅ 推荐：多阶段构建
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "server.js"]
```

---

## 🔧 开发工具配置

### ESLint配置要点
```javascript
// .eslintrc.js 关键规则
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    'simple-import-sort/imports': 'error',
    'unused-imports/no-unused-imports': 'error',
  },
};
```

### Prettier配置
```javascript
// .prettierrc.js
module.exports = {
  semi: true,
  singleQuote: true,
  trailingComma: 'es5',
  tabWidth: 2,
  plugins: ['prettier-plugin-tailwindcss'],
};
```

### Git工作流
```bash
# ✅ 推荐的开发流程

# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 开发并提交（Commitlint规范）
git commit -m "feat: 添加新功能"
# 类型：feat, fix, docs, style, refactor, test, chore

# 3. 推送并创建PR
git push origin feature/new-feature

# 4. 代码审查后合并
git checkout main
git merge feature/new-feature

# 5. 删除功能分支
git branch -d feature/new-feature
```

---

## 📋 代码审查清单

### 提交前检查
- [ ] 代码格式化（`pnpm format`）
- [ ] ESLint无错误（`pnpm lint`）
- [ ] TypeScript类型检查（`pnpm typecheck`）
- [ ] 测试通过（`pnpm test`）
- [ ] 构建成功（`pnpm build`）

### 代码质量检查
- [ ] 无any类型使用
- [ ] 无console.log残留
- [ ] 正确的错误处理
- [ ] 敏感数据使用环境变量
- [ ] 组件拆分合理
- [ ] 避免过深嵌套（<4层）

### 性能检查
- [ ] 避免不必要的re-render
- [ ] 大数据使用分页/虚拟滚动
- [ ] 图片使用next/image
- [ ] 路由预加载合理
- [ ] 避免客户端大量计算

### 安全检查
- [ ] 输入验证（Zod）
- [ ] SQL注入防护
- [ ] XSS防护（正确转义）
- [ ] CSRF防护（SameSite Cookie）
- [ ] 权限验证完整

---

**规范版本**: v1.0  
**最后更新**: 2025-10-06  
**维护者**: MoonTV开发团队
