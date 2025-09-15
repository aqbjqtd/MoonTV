# MoonTV系统性性能优化计划书

## 📅 计划制定时间
2025-09-14  
制定者：SuperClaude + Serena 协同框架  
计划状态：✅ 已制定完成，待执行

---

## 🎯 计划概述

### 核心理念
- **安全第一**：每个步骤都有完整恢复机制
- **系统性强**：严格按照7阶段执行，避免随意修改
- **风险可控**：每步都有验证和回退方案
- **结果可测**：每个阶段都有明确的性能指标

### 优化目标
- **页面加载速度**：提升50-70%
- **视频播放流畅度**：提升60-80%  
- **内存使用效率**：降低30-40%
- **用户体验评分**：提升40-60%

---

## 🛡️ 第一阶段：准备工作

### 1.1 创建安全基线
```bash
# 创建性能优化分支
git checkout -b performance-optimization
git add .
git commit -m "🔒 性能优化前安全基线 - v1.1.1"
git tag -a v1.1.1-performance-baseline -m "性能优化安全基线"

# 核心文件备份
cp package.json package.json.backup
cp pnpm-lock.yaml pnpm-lock.yaml.backup
cp -r src src.backup
```

### 1.2 环境验证
```bash
# 验证当前状态
pnpm run build        # 构建成功
pnpm run typecheck    # 类型检查通过
pnpm run lint         # 代码检查通过
docker build -t moontv:baseline .  # Docker镜像构建成功
```

### 1.3 性能基准测试
```bash
# 记录基准性能指标
- 构建时间: ____ 秒
- 镜像大小: ____ MB  
- 首屏加载时间: ____ 秒
- 视频启动时间: ____ 秒
- 内存使用: ____ MB
```

---

## 🧹 第二阶段：依赖安全清理 (方案A)

### 2.1 依赖使用情况分析
```bash
# 自动化依赖检查
npx depcheck

# 手动验证关键依赖使用情况
grep -r "react-icons" src/          # 检查是否使用
grep -r "media-icons" src/         # 检查是否使用  
grep -r "swiper" src/              # 检查轮播使用

# 统计lucide-react实际使用图标
grep -r "from 'lucide-react'" src/  # 统计导入的图标
```

### 2.2 安全清理清单
```json
// ✅ 可安全清理（需验证）
{
  "候选清理": [
    "react-icons": "^5.4.0",      // 如果确认未使用
    "media-icons": "^1.1.5",      // 如果确认未使用
    "swiper": "^11.2.8"            // 如果轮播组件未使用
  ]
}

// ❌ 绝对保留
{
  "核心保留": [
    "artplayer", "hls.js", "@vidstack/react", "vidstack",  // 播放核心
    "lucide-react", "@heroicons/react",                   // 图标系统
    "framer-motion", "@headlessui/react",               // UI系统
    "next-themes", "next-pwa",                          // Next.js特性
    "zod", "sweetalert2",                             // 工具库
  ]
}
```

### 2.3 渐进式清理流程
```bash
# 每次清理一个依赖，完整测试循环
for dep in "react-icons" "media-icons" "swiper"; do
  echo "=== 测试清理 $dep ==="
  
  # 1. 备份
  cp package.json package.json.pre-$dep
  
  # 2. 清理
  pnpm uninstall $dep
  
  # 3. 测试
  pnpm run build && pnpm run typecheck && pnpm run lint
  
  # 4. Docker测试
  docker build -t moontv-test-$dep . && \
  docker run --rm moontv-test-$dep
  
  # 5. 成功则继续，失败则恢复
  if [ $? -eq 0 ]; then
    echo "✅ $dep 清理成功"
  else
    echo "❌ $dep 清理失败，恢复中..."
    cp package.json.pre-$dep package.json
    pnpm install
  fi
done
```

### 2.4 阶段验证
- **构建成功** ✅
- **类型检查通过** ✅  
- **Docker镜像正常** ✅
- **核心功能正常** ✅
- **性能提升记录**：____%

---

## 🖼️ 第三阶段：图片和构建优化

### 3.1 启用Next.js图片优化
```javascript
// next.config.js
const nextConfig = {
  reactStrictMode: true,  // 启用严格模式
  images: {
    unoptimized: false,     // ✅ 启用图片优化
    domains: [
      'images.example.com',  // ✅ 配置域名白名单
      'picsum.photos',
      'via.placeholder.com'
    ],
    formats: ['image/webp', 'image/avif'],  // ✅ 现代格式
  },
  // ... 其他配置
}
```

### 3.2 图片格式优化策略
```bash
# 添加现代图片格式支持
# WebP: 比JPEG小25-35%
# AVIF: 比WebP小20-50%

# 自动化图片优化脚本
find public/images -name "*.jpg" -exec convert {} {}.webp \;
find public/images -name "*.png" -exec convert {} {}.webp \;
```

### 3.3 构建配置优化
```javascript
// next.config.js 继续优化
const nextConfig = {
  compress: true,                    // 启用压缩
  poweredByHeader: false,            // 移除X-Powered-By
  generateEtags: false,              // 禁用ETags
  httpAgentOptions: {                // HTTP代理优化
    keepAlive: true,
  },
  experimental: {
    serverActions: true,              // Server Actions
    optimizePackageImports: ['lucide-react', 'framer-motion'],  // 导入优化
  },
}
```

### 3.4 阶段验证
- **图片加载速度**：提升____%
- **构建体积**：减少____%  
- **Lighthouse评分**：提升____分
- **所有页面正常显示** ✅

---

## ⚡ 第四阶段：代码分割和懒加载

### 4.1 路由级代码分割
```typescript
// app/page.tsx
import dynamic from 'next/dynamic';

// 懒加载大型组件
const VideoPlayer = dynamic(() => import('@/components/VideoPlayer'), {
  loading: () => <div>播放器加载中...</div>,
  ssr: false  // 客户端渲染
});

const AdminPanel = dynamic(() => import('@/components/AdminPanel'), {
  loading: () => <div>管理面板加载中...</div>,
  ssr: false
});
```

### 4.2 组件级懒加载
```typescript
// components/LazyComponents.tsx
export const LazyVideoCard = dynamic(() => import('./VideoCard'), {
  loading: () => <VideoCardSkeleton />
});

export const LazySearchResults = dynamic(() => import('./SearchResults'), {
  loading: () => <SearchResultsSkeleton />
});
```

### 4.3 第三方库按需加载
```typescript
// lib/lazy-load.ts
export const loadFramerMotion = () => import('framer-motion');
export const loadSweetAlert = () => import('sweetalert2');

// 使用时
const { motion } = await loadFramerMotion();
```

### 4.4 阶段验证
- **初始包大小**：减少____%
- **首屏时间**：缩短____%
- **懒加载组件正常工作** ✅
- **无白屏闪烁** ✅

---

## 🎬 第五阶段：视频播放性能优化

### 5.1 视频源优选算法
```typescript
// lib/video-source-optimizer.ts
interface VideoSource {
  url: string;
  quality: '360p' | '720p' | '1080p' | '4k';
  bandwidth: number;
  cdn: string;
}

export class VideoSourceOptimizer {
  private sources: VideoSource[] = [];
  
  async selectOptimalSource(): Promise<VideoSource> {
    // 1. 测试CDN延迟
    const pingResults = await this.testCDNs();
    
    // 2. 检测用户带宽
    const userBandwidth = await this.detectBandwidth();
    
    // 3. 综合评分选择最优源
    return this.sources
      .filter(source => source.bandwidth <= userBandwidth)
      .sort((a, b) => this.calculateScore(a, b, pingResults))[0];
  }
}
```

### 5.2 HLS播放器优化
```typescript
// components/OptimizedVideoPlayer.tsx
import Hls from 'hls.js';

export const OptimizedVideoPlayer = ({ src }) => {
  const videoRef = useRef<HTMLVideoElement>();  
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const hls = new Hls({
        enableWorker: true,        // 启用Web Worker
        lowLatencyMode: true,      // 低延迟模式
        backBufferLength: 90,       // 后缓冲优化
        maxBufferLength: 30,        // 前缓冲优化
      });
      
      // 自适应配置
      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        hls.currentLevel = hls.levels.length - 1; // 默认最高质量
      });
    }
  }, []);
};
```

### 5.3 预加载策略
```typescript
// lib/video-preloader.ts
export class VideoPreloader {
  private preloadQueue: string[] = [];
  
  addToPreload(videoId: string) {
    if (this.preloadQueue.length < 3) {  // 最多预加载3个
      this.preloadQueue.push(videoId);
      this.startPreload(videoId);
    }
  }
  
  private async startPreload(videoId: string) {
    const videoUrl = await this.getVideoUrl(videoId);
    const link = document.createElement('link');
    link.rel = 'preload';
    link.as = 'video';
    link.href = videoUrl;
    document.head.appendChild(link);
  }
}
```

### 5.4 阶段验证
- **视频启动时间**：减少____%
- **卡顿频率**：降低____%
- **带宽使用效率**：提升____%
- **多清晰度切换**：流畅 ✅

---

## ⚡ 第六阶段：React和运行时优化

### 6.1 React性能优化
```typescript
// 使用React.memo优化
export const MemoizedVideoCard = React.memo(VideoCard, (prev, next) => {
  return prev.id === next.id && prev.thumbnail === next.thumbnail;
});

// 虚拟滚动实现
import { FixedSizeList as List } from 'react-window';

export const VirtualizedVideoList = ({ videos }) => (
  <List
    height={600}
    itemCount={videos.length}
    itemSize={200}
    width="100%"
  >
    {({ index, style }) => (
      <div style={style}>
        <MemoizedVideoCard video={videos[index]} />
      </div>
    )}
  </List>
);
```

### 6.2 缓存策略优化
```typescript
// app/api/[...]/route.ts
export const revalidate = 3600; // 1小时重新验证

// 增量静态生成
export const generateStaticParams = async () => {
  const posts = await getPosts();
  return posts.slice(0, 100); // 生成前100个页面
};
```

### 6.3 性能监控系统
```typescript
// lib/performance-monitor.ts
export class PerformanceMonitor {
  static trackPageLoad() {
    if (typeof window !== 'undefined') {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          this.sendMetrics(entry);
        }
      });
      
      observer.observe({ entryTypes: ['navigation', 'resource'] });
    }
  }
}
```

### 6.4 阶段验证
- **React渲染性能**：提升____%
- **内存使用**：降低____%
- **缓存命中率**：提升____%
- **性能监控正常** ✅

---

## 📊 第七阶段：全面验证和监控

### 7.1 性能基准对比
| 指标 | 优化前 | 优化后 | 提升幅度 | 状态 |
|------|--------|--------|----------|------|
| **构建时间** | ____ | ____ | ____% | ✅/❌ |
| **镜像大小** | ____ | ____ | ____% | ✅/❌ |
| **首屏加载** | ____ | ____ | ____% | ✅/❌ |
| **视频启动** | ____ | ____ | ____% | ✅/❌ |
| **内存使用** | ____ | ____ | ____% | ✅/❌ |
| **Lighthouse** | ____ | ____ | ____分 | ✅/❌ |

### 7.2 功能完整性测试
- [ ] 用户登录/登出功能正常
- [ ] 视频搜索功能正常
- [ ] 视频播放功能正常（多源）
- [ ] 收藏功能正常
- [ ] PWA功能正常
- [ ] 管理员后台正常
- [ ] 响应式布局正常
- [ ] 深色/浅色主题切换正常

### 7.3 最终验证
```bash
# 完整测试套件
pnpm run build && pnpm run typecheck && pnpm run lint
docker build -t moontv:optimized .
docker run --name moontv-final-test -d -p 9001:3000 moontv:optimized

# 性能测试
curl -w "Time: %{time_total}s\nSize: %{size_download}bytes\n" -o /dev/null -s http://localhost:9001/
```

---

## 🚨 紧急恢复预案

### 立即恢复命令
```bash
# 一键恢复到安全基线
git reset --hard v1.1.1-performance-baseline
cp package.json.backup package.json
cp pnpm-lock.yaml.backup pnpm-lock.yaml
pnpm install

# 清理失败镜像
docker rmi moontv:optimized moontv-test-*

# 重新构建基线镜像
docker build -t moontv:safe .
```

### 分阶段回退策略
- **第2阶段失败**：恢复package.json，重新install
- **第3阶段失败**：恢复next.config.js备份
- **第4阶段失败**：恢复所有dynamic导入
- **第5阶段失败**：恢复原始播放器组件
- **第6阶段失败**：恢复React组件优化

---

## 📋 执行时间表

| 阶段 | 计划时间 | 验证时间 | 风险等级 | 状态 |
|------|----------|----------|----------|------|
| **准备阶段** | 0.5天 | 0.5天 | 🟢 低 | ⏳ 待执行 |
| **依赖清理** | 1天 | 1天 | 🟡 中 | ⏳ 待执行 |
| **图片优化** | 0.5天 | 0.5天 | 🟢 低 | ⏳ 待执行 |
| **代码分割** | 1天 | 1天 | 🟡 中 | ⏳ 待执行 |
| **视频优化** | 2天 | 1天 | 🟡 中 | ⏳ 待执行 |
| **React优化** | 1天 | 1天 | 🟢 低 | ⏳ 待执行 |
| **全面验证** | 0.5天 | 0.5天 | 🟢 低 | ⏳ 待执行 |

**总计工期**：约**8天**
**缓冲时间**：+2天（应对意外情况）

---

## 📝 执行检查清单

### 执行前确认
- [ ] 已阅读并理解整个优化计划
- [ ] 确认当前项目处于稳定状态 (v1.1.1)
- [ ] 备份所有重要文件和配置
- [ ] 准备好充足的测试时间

### 执行中监控
- 每个阶段完成后都要更新此记忆文件
- 记录实际的性能提升数据
- 记录遇到的问题和解决方案
- 及时更新风险等级和状态

### 执行后总结
- 对比预期目标与实际效果
- 总结经验教训
- 提出后续优化建议

---

## 🎯 关键成功因素

### 技术保障
1. **严格按阶段执行**：不跳步骤，不并行处理
2. **充分验证每个阶段**：确保功能正常才继续
3. **及时备份和恢复**：异常情况立即回退
4. **详细记录过程**：为后续优化提供参考

### 风险控制
1. **依赖清理谨慎**：只清理明确未使用的依赖
2. **核心功能保护**：视频播放、搜索等核心功能优先保证
3. **Docker镜像验证**：每次修改后都要测试镜像构建
4. **用户体验优先**：性能优化不能影响功能完整性

### 质量保证
1. **性能指标量化**：每个阶段都要有具体的性能数据
2. **功能完整性**：优化前后所有功能都要正常工作
3. **代码质量**：优化不能降低代码质量和可维护性
4. **安全性**：优化不能引入新的安全风险

---

**下次对话时，只需说"开始按计划执行"，我将自动获取此计划并从第一阶段开始执行。**

计划制定完成时间：2025-09-14  
下次执行时请确认：当前Git提交为 2712ac0，版本为 v1.1.1