# MoonTV 性能优化与监控系统指南 (v3.2.0-fixed)
**最后更新**: 2025-10-06
**维护专家**: 性能工程师
**适用版本**: v3.2.0-fixed及以上

## 🎯 性能目标与指标

### 核心性能指标 (KPIs)
```yaml
页面性能指标:
  首屏加载时间 (FCP): <1.5s (目标: <1.0s)
  最大内容绘制 (LCP): <2.5s (目标: <1.8s)
  首次输入延迟 (FID): <100ms (目标: <50ms)
  累积布局偏移 (CLS): <0.1 (目标: <0.05)

API性能指标:
  平均响应时间: <100ms (目标: <50ms)
  95%分位响应时间: <300ms (目标: <150ms)
  错误率: <0.1% (目标: <0.05%)
  吞吐量: >1000 RPS (目标: >2000 RPS)

资源性能指标:
  内存使用: <512MB (目标: <256MB)
  CPU使用率: <50% (目标: <30%)
  网络延迟: <50ms (目标: <20ms)
  缓存命中率: >85% (目标: >95%)

用户体验指标:
  页面跳出率: <30% (目标: <20%)
  平均会话时长: >5min (目标: >10min)
  用户满意度: >4.0/5.0 (目标: >4.5/5.0)
```

### 性能预算
```yaml
构建产物大小:
  JavaScript包: <250KB (gzipped)
  CSS包: <50KB (gzipped)
  图片资源: 平均<100KB
  字体文件: <200KB

网络传输:
  首屏资源: <1MB
  总页面大小: <3MB
  请求数量: <50个
  HTTP/2多路复用: 启用

运行时性能:
  初始JavaScript执行时间: <200ms
  渲染时间: <100ms
  交互响应时间: <50ms
  内存泄漏: 0个已知泄漏
```

## 🏗️ 前端性能优化

### 1. 代码分割与懒加载

#### 路由级代码分割
```typescript
// src/app/layout.tsx - 动态导入优化
import dynamic from 'next/dynamic'
import { Suspense } from 'react'

// 懒加载重型组件
const AdminPanel = dynamic(() => import('@/components/admin/AdminPanel'), {
  loading: () => <div>加载管理面板中...</div>,
  ssr: false // 客户端渲染以减少服务器负载
})

const VideoPlayer = dynamic(() => import('@/components/video/VideoPlayer'), {
  loading: () => <div>加载播放器中...</div>,
  ssr: true // 播放器需要SSR以支持SEO
})

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN">
      <body>
        <Suspense fallback={<div>加载中...</div>}>
          {children}
        </Suspense>
      </body>
    </html>
  )
}
```

#### 组件级懒加载
```typescript
// src/components/LazyComponents.tsx
import { lazy, ComponentType } from 'react'

// 创建懒加载工厂函数
export const createLazyComponent = <T extends ComponentType<any>>(
  importFunc: () => Promise<{ default: T }>,
  fallback: React.ComponentType = () => <div>加载中...</div>
) => {
  return lazy(importFunc)
}

// 懒加载组件定义
export const LazyVideoCard = createLazyComponent(
  () => import('@/components/video/VideoCard'),
  () => <div className="animate-pulse bg-gray-200 h-48 rounded-lg"></div>
)

export const LazySearchSuggestions = createLazyComponent(
  () => import('@/components/search/SearchSuggestions'),
  () => <div className="animate-pulse h-32 bg-gray-100 rounded"></div>
)

export const LazyUserMenu = createLazyComponent(
  () => import('@/components/auth/UserMenu'),
  () => <div className="animate-pulse w-8 h-8 bg-gray-300 rounded-full"></div>
)
```

### 2. 图片优化策略

#### 响应式图片组件
```typescript
// src/components/ui/OptimizedImage.tsx
import Image, { ImageProps } from 'next/image'
import { useState } from 'react'
import { cn } from '@/lib/utils'

interface OptimizedImageProps extends Omit<ImageProps, 'src' | 'alt'> {
  src: string
  alt: string
  fallbackSrc?: string
  blurDataURL?: string
}

export default function OptimizedImage({
  src,
  alt,
  fallbackSrc = '/images/placeholder.jpg',
  blurDataURL,
  className,
  ...props
}: OptimizedImageProps) {
  const [imgSrc, setImgSrc] = useState(src)
  const [isLoading, setIsLoading] = useState(true)

  return (
    <div className={cn("relative overflow-hidden", className)}>
      <Image
        {...props}
        src={imgSrc}
        alt={alt}
        placeholder={blurDataURL ? 'blur' : 'empty'}
        blurDataURL={blurDataURL}
        className={cn(
          "transition-opacity duration-300",
          isLoading ? "opacity-0" : "opacity-100"
        )}
        onLoad={() => setIsLoading(false)}
        onError={() => {
          setImgSrc(fallbackSrc)
          setIsLoading(false)
        }}
        sizes={props.sizes || "(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"}
      />
      {isLoading && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse" />
      )}
    </div>
  )
}
```

#### 图片预加载策略
```typescript
// src/hooks/useImagePreload.ts
import { useEffect, useState } from 'react'

export function useImagePreload(urls: string[]) {
  const [loadedImages, setLoadedImages] = useState<Set<string>>(new Set())
  const [loadingImages, setLoadingImages] = useState<Set<string>>(new Set())

  useEffect(() => {
    urls.forEach(url => {
      if (!loadedImages.has(url) && !loadingImages.has(url)) {
        setLoadingImages(prev => new Set(prev).add(url))
        
        const img = new Image()
        img.onload = () => {
          setLoadedImages(prev => new Set(prev).add(url))
          setLoadingImages(prev => {
            const newSet = new Set(prev)
            newSet.delete(url)
            return newSet
          })
        }
        img.onerror = () => {
          setLoadingImages(prev => {
            const newSet = new Set(prev)
            newSet.delete(url)
            return newSet
          })
        }
        img.src = url
      }
    })
  }, [urls])

  return { loadedImages, loadingImages }
}

// 使用示例
function VideoCard({ video }: { video: VideoInfo }) {
  const { loadedImages } = useImagePreload([video.pic])
  
  return (
    <div>
      <OptimizedImage
        src={video.pic}
        alt={video.name}
        width={300}
        height={200}
        className={loadedImages.has(video.pic) ? 'loaded' : 'loading'}
      />
    </div>
  )
}
```

### 3. 缓存优化策略

#### React Query集成
```typescript
// src/lib/react-query.ts
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function createQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 5 * 60 * 1000, // 5分钟
        cacheTime: 10 * 60 * 1000, // 10分钟
        retry: 3,
        retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
        refetchOnWindowFocus: false,
        refetchOnReconnect: true,
      },
      mutations: {
        retry: 1,
      },
    },
  })
}

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => createQueryClient())
  
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === 'development' && (
        <ReactQueryDevtools initialIsOpen={false} />
      )}
    </QueryClientProvider>
  )
}
```

#### 搜索结果缓存
```typescript
// src/hooks/useSearchWithCache.ts
import { useQuery } from '@tanstack/react-query'
import { searchFromApi } from '@/lib/fetchVideoDetail'
import { debounce } from 'lodash-es'

interface SearchOptions {
  keyword: string
  page?: number
  type?: string
  source?: string
}

// 防抖搜索函数
const debouncedSearch = debounce(
  async (options: SearchOptions) => {
    return await searchFromApi(options.keyword, {
      maxPage: options.page || 1,
      timeout: 5000,
      type: options.type,
      source: options.source,
    })
  },
  300
)

export function useSearchWithCache(options: SearchOptions) {
  return useQuery({
    queryKey: ['search', options],
    queryFn: () => debouncedSearch(options),
    enabled: !!options.keyword && options.keyword.length >= 2,
    staleTime: 2 * 60 * 1000, // 搜索结果2分钟内认为新鲜
    cacheTime: 5 * 60 * 1000, // 5分钟后清除缓存
    keepPreviousData: true, // 保持上一次的数据直到新数据加载完成
  })
}
```

### 4. 状态管理优化

#### Zustand轻量状态管理
```typescript
// src/store/useVideoStore.ts
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import { VideoInfo, PlayRecord } from '@/lib/types'

interface VideoState {
  // 播放状态
  currentVideo: VideoInfo | null
  isPlaying: boolean
  currentTime: number
  duration: number
  
  // 播放历史
  playHistory: PlayRecord[]
  
  // 收藏列表
  favorites: VideoInfo[]
  
  // Actions
  setCurrentVideo: (video: VideoInfo) => void
  setIsPlaying: (playing: boolean) => void
  setCurrentTime: (time: number) => void
  setDuration: (duration: number) => void
  addToPlayHistory: (record: PlayRecord) => void
  addToFavorites: (video: VideoInfo) => void
  removeFromFavorites: (videoId: string) => void
}

export const useVideoStore = create<VideoState>()(
  devtools(
    persist(
      (set, get) => ({
        // Initial state
        currentVideo: null,
        isPlaying: false,
        currentTime: 0,
        duration: 0,
        playHistory: [],
        favorites: [],

        // Actions
        setCurrentVideo: (video) => set({ currentVideo: video }),
        setIsPlaying: (playing) => set({ isPlaying: playing }),
        setCurrentTime: (time) => set({ currentTime: time }),
        setDuration: (duration) => set({ duration }),
        
        addToPlayHistory: (record) => set((state) => ({
          playHistory: [record, ...state.playHistory.slice(0, 99)] // 保持最近100条记录
        })),
        
        addToFavorites: (video) => set((state) => {
          const exists = state.favorites.some(v => v.video_id === video.video_id)
          if (!exists) {
            return { favorites: [...state.favorites, video] }
          }
          return state
        }),
        
        removeFromFavorites: (videoId) => set((state) => ({
          favorites: state.favorites.filter(v => v.video_id !== videoId)
        })),
      }),
      {
        name: 'video-store',
        partialize: (state) => ({
          playHistory: state.playHistory,
          favorites: state.favorites,
        }),
      }
    ),
    { name: 'video-store' }
  )
)
```

## 🚀 后端性能优化

### 1. API响应优化

#### 缓存策略实现
```typescript
// src/lib/cache.ts
import { cache } from 'react'

// 内存缓存装饰器
export function memoizeCache<T extends (...args: any[]) => any>(
  fn: T,
  ttl: number = 5 * 60 * 1000 // 5分钟默认TTL
): T {
  const cache = new Map<string, { value: ReturnType<T>; expiry: number }>()
  
  return ((...args: Parameters<T>) => {
    const key = JSON.stringify(args)
    const now = Date.now()
    const cached = cache.get(key)
    
    if (cached && cached.expiry > now) {
      return cached.value
    }
    
    const result = fn(...args)
    cache.set(key, { value: result, expiry: now + ttl })
    return result
  }) as T
}

// 搜索API缓存
export const cachedSearch = memoizeCache(
  async (keyword: string, options: any) => {
    return await searchFromApi(keyword, options)
  },
  2 * 60 * 1000 // 2分钟缓存
)

// 配置API缓存
export const cachedConfig = cache(async () => {
  return await getConfig()
})
```

#### 并发请求优化
```typescript
// src/lib/concurrent-search.ts
import { PromisePool } from '@supercharge/promise-pool'
import { searchFromSingleSource } from './fetchVideoDetail'

interface SearchOptions {
  keyword: string
  maxPage: number
  timeout: number
  sources: string[]
  concurrency?: number
}

export async function concurrentSearch(options: SearchOptions) {
  const { keyword, maxPage, timeout, sources, concurrency = 5 } = options
  
  // 使用PromisePool控制并发数量
  const { results, errors } = await PromisePool
    .for(sources)
    .withConcurrency(concurrency)
    .process(async (source) => {
      try {
        const result = await Promise.race([
          searchFromSingleSource(keyword, source, { maxPage }),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Timeout')), timeout)
          )
        ])
        return { source, result, success: true }
      } catch (error) {
        return { source, error: error.message, success: false }
      }
    })
  
  // 过滤成功结果并聚合
  const successfulResults = results
    .filter(r => r.success)
    .flatMap(r => (r as any).result)
  
  return {
    results: successfulResults,
    errors: errors.map(e => e.message),
    totalSources: sources.length,
    successfulSources: results.filter(r => r.success).length
  }
}
```

### 2. 数据库查询优化

#### Redis缓存层
```typescript
// src/lib/redis-cache.ts
import Redis from 'ioredis'

class RedisCache {
  private client: Redis
  
  constructor() {
    this.client = new Redis(process.env.REDIS_URL || 'redis://localhost:6379')
  }
  
  // 通用缓存方法
  async get<T>(key: string): Promise<T | null> {
    try {
      const value = await this.client.get(key)
      return value ? JSON.parse(value) : null
    } catch (error) {
      console.error('Redis get error:', error)
      return null
    }
  }
  
  async set(key: string, value: any, ttl: number = 3600): Promise<void> {
    try {
      await this.client.setex(key, ttl, JSON.stringify(value))
    } catch (error) {
      console.error('Redis set error:', error)
    }
  }
  
  async del(key: string): Promise<void> {
    try {
      await this.client.del(key)
    } catch (error) {
      console.error('Redis del error:', error)
    }
  }
  
  // 搜索结果缓存
  async cacheSearchResults(keyword: string, results: any[], ttl: number = 1800) {
    const key = `search:${encodeURIComponent(keyword)}`
    await this.set(key, results, ttl)
  }
  
  async getCachedSearchResults(keyword: string) {
    const key = `search:${encodeURIComponent(keyword)}`
    return await this.get(key)
  }
  
  // 用户会话缓存
  async cacheUserSession(username: string, sessionData: any, ttl: number = 86400) {
    const key = `session:${username}`
    await this.set(key, sessionData, ttl)
  }
  
  async getUserSession(username: string) {
    const key = `session:${username}`
    return await this.get(key)
  }
  
  // 配置缓存
  async cacheConfig(config: any, ttl: number = 3600) {
    const key = 'config:admin'
    await this.set(key, config, ttl)
  }
  
  async getCachedConfig() {
    const key = 'config:admin'
    return await this.get(key)
  }
  
  // 缓存失效
  async invalidatePattern(pattern: string) {
    try {
      const keys = await this.client.keys(pattern)
      if (keys.length > 0) {
        await this.client.del(...keys)
      }
    } catch (error) {
      console.error('Redis invalidate pattern error:', error)
    }
  }
}

export const redisCache = new RedisCache()
```

#### 数据库连接池优化
```typescript
// src/lib/db-pool.ts
import { Pool } from 'pg'

class DatabasePool {
  private pool: Pool
  
  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'moontv',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      max: 20, // 最大连接数
      idleTimeoutMillis: 30000, // 空闲超时
      connectionTimeoutMillis: 2000, // 连接超时
    })
  }
  
  async query<T = any>(text: string, params?: any[]): Promise<T[]> {
    const start = Date.now()
    try {
      const result = await this.pool.query(text, params)
      const duration = Date.now() - start
      console.log('Executed query', { text, duration, rows: result.rowCount })
      return result.rows
    } catch (error) {
      console.error('Database query error:', { text, error })
      throw error
    }
  }
  
  async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await this.pool.connect()
    try {
      await client.query('BEGIN')
      const result = await callback(client)
      await client.query('COMMIT')
      return result
    } catch (error) {
      await client.query('ROLLBACK')
      throw error
    } finally {
      client.release()
    }
  }
  
  async close() {
    await this.pool.end()
  }
}

export const dbPool = new DatabasePool()
```

### 3. 响应压缩优化

#### Next.js压缩配置
```javascript
// next.config.js
const nextConfig = {
  // 启用压缩
  compress: true,
  
  // 自定义压缩配置
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
  },
  
  // 图片优化
  images: {
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 86400, // 24小时
    dangerouslyAllowSVG: true,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
  
  // HTTP头优化
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
        ],
      },
      {
        source: '/api/(.*)',
        headers: [
          {
            key: 'Cache-Control',
            value: 's-maxage=300, stale-while-revalidate=600',
          },
        ],
      },
      {
        source: '/_next/static/(.*)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
    ]
  },
  
  // 重写规则优化
  async rewrites() {
    return [
      {
        source: '/sitemap.xml',
        destination: '/api/sitemap',
      },
    ]
  },
}

module.exports = nextConfig
```

## 📊 性能监控系统

### 1. 实时性能监控

#### 性能监控Hook
```typescript
// src/hooks/usePerformanceMonitor.ts
import { useEffect, useRef, useState } from 'react'

interface PerformanceMetrics {
  fcp: number | null
  lcp: number | null
  fid: number | null
  cls: number | null
  ttfb: number | null
  domContentLoaded: number | null
  loadComplete: number | null
}

export function usePerformanceMonitor() {
  const [metrics, setMetrics] = useState<PerformanceMetrics>({
    fcp: null,
    lcp: null,
    fid: null,
    cls: null,
    ttfb: null,
    domContentLoaded: null,
    loadComplete: null,
  })
  
  const observerRefs = useRef<{
    lcpObserver?: PerformanceObserver
    fidObserver?: PerformanceObserver
    clsObserver?: PerformanceObserver
  }>({})
  
  useEffect(() => {
    if (typeof window === 'undefined') return
    
    // FCP (First Contentful Paint)
    const fcpEntry = performance.getEntriesByName('first-contentful-paint')[0] as PerformanceEntry
    if (fcpEntry) {
      setMetrics(prev => ({ ...prev, fcp: fcpEntry.startTime }))
    }
    
    // TTFB (Time to First Byte)
    const navigationEntry = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming
    if (navigationEntry) {
      setMetrics(prev => ({
        ...prev,
        ttfb: navigationEntry.responseStart - navigationEntry.requestStart,
        domContentLoaded: navigationEntry.domContentLoadedEventEnd - navigationEntry.navigationStart,
        loadComplete: navigationEntry.loadEventEnd - navigationEntry.navigationStart,
      }))
    }
    
    // LCP (Largest Contentful Paint)
    try {
      observerRefs.current.lcpObserver = new PerformanceObserver((entryList) => {
        const entries = entryList.getEntries()
        const lastEntry = entries[entries.length - 1]
        setMetrics(prev => ({ ...prev, lcp: lastEntry.startTime }))
      })
      observerRefs.current.lcpObserver.observe({ entryTypes: ['largest-contentful-paint'] })
    } catch (error) {
      console.warn('LCP observation not supported')
    }
    
    // FID (First Input Delay)
    try {
      observerRefs.current.fidObserver = new PerformanceObserver((entryList) => {
        const entries = entryList.getEntries()
        entries.forEach((entry) => {
          if (entry instanceof PerformanceEventTiming) {
            setMetrics(prev => ({ ...prev, fid: entry.processingStart - entry.startTime }))
          }
        })
      })
      observerRefs.current.fidObserver.observe({ entryTypes: ['first-input'] })
    } catch (error) {
      console.warn('FID observation not supported')
    }
    
    // CLS (Cumulative Layout Shift)
    try {
      let clsValue = 0
      observerRefs.current.clsObserver = new PerformanceObserver((entryList) => {
        for (const entry of entryList.getEntries()) {
          if (!(entry as any).hadRecentInput) {
            clsValue += (entry as any).value
            setMetrics(prev => ({ ...prev, cls: clsValue }))
          }
        }
      })
      observerRefs.current.clsObserver.observe({ entryTypes: ['layout-shift'] })
    } catch (error) {
      console.warn('CLS observation not supported')
    }
    
    return () => {
      Object.values(observerRefs.current).forEach(observer => {
        observer?.disconnect()
      })
    }
  }, [])
  
  return metrics
}

// 性能报告组件
export function PerformanceReport() {
  const metrics = usePerformanceMonitor()
  
  const getGrade = (value: number | null, thresholds: { good: number; needsImprovement: number }) => {
    if (value === null) return 'unknown'
    if (value <= thresholds.good) return 'good'
    if (value <= thresholds.needsImprovement) return 'needs-improvement'
    return 'poor'
  }
  
  const fcpGrade = getGrade(metrics.fcp, { good: 1800, needsImprovement: 3000 })
  const lcpGrade = getGrade(metrics.lcp, { good: 2500, needsImprovement: 4000 })
  const fidGrade = getGrade(metrics.fid, { good: 100, needsImprovement: 300 })
  const clsGrade = getGrade(metrics.cls, { good: 0.1, needsImprovement: 0.25 })
  
  return (
    <div className="performance-report p-4 bg-gray-50 rounded-lg">
      <h3 className="text-lg font-semibold mb-4">性能指标</h3>
      
      <div className="grid grid-cols-2 gap-4">
        <div className="metric">
          <div className="text-sm text-gray-600">FCP (首屏绘制)</div>
          <div className={`text-lg font-medium ${fcpGrade}`}>{metrics.fcp?.toFixed(0)}ms</div>
        </div>
        
        <div className="metric">
          <div className="text-sm text-gray-600">LCP (最大内容绘制)</div>
          <div className={`text-lg font-medium ${lcpGrade}`}>{metrics.lcp?.toFixed(0)}ms</div>
        </div>
        
        <div className="metric">
          <div className="text-sm text-gray-600">FID (首次输入延迟)</div>
          <div className={`text-lg font-medium ${fidGrade}`}>{metrics.fid?.toFixed(0)}ms</div>
        </div>
        
        <div className="metric">
          <div className="text-sm text-gray-600">CLS (累积布局偏移)</div>
          <div className={`text-lg font-medium ${clsGrade}`}>{metrics.cls?.toFixed(3)}</div>
        </div>
      </div>
    </div>
  )
}
```

#### API性能监控中间件
```typescript
// src/lib/api-performance.ts
import { NextRequest, NextResponse } from 'next/server'
import { performance } from 'perf_hooks'

interface PerformanceData {
  method: string
  url: string
  statusCode: number
  duration: number
  timestamp: number
  userAgent?: string
  ip?: string
}

class APIPerformanceMonitor {
  private performanceData: PerformanceData[] = []
  private maxRecords = 1000
  
  record(data: PerformanceData) {
    this.performanceData.push(data)
    
    // 保持最近1000条记录
    if (this.performanceData.length > this.maxRecords) {
      this.performanceData = this.performanceData.slice(-this.maxRecords)
    }
    
    // 异步发送到监控系统
    this.sendToMonitoring(data)
  }
  
  private async sendToMonitoring(data: PerformanceData) {
    try {
      // 发送到监控服务
      await fetch('/api/monitoring/performance', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }).catch(() => {
        // 忽略监控发送失败，不影响主业务
      })
    } catch (error) {
      console.error('Failed to send performance data:', error)
    }
  }
  
  getMetrics() {
    const recent = this.performanceData.slice(-100)
    
    const avgDuration = recent.reduce((sum, d) => sum + d.duration, 0) / recent.length
    const p95Duration = this.calculatePercentile(recent.map(d => d.duration), 0.95)
    const errorRate = recent.filter(d => d.statusCode >= 400).length / recent.length
    
    return {
      totalRequests: this.performanceData.length,
      avgDuration: Math.round(avgDuration),
      p95Duration: Math.round(p95Duration),
      errorRate: Math.round(errorRate * 100) / 100,
      recentRequests: recent.length,
    }
  }
  
  private calculatePercentile(values: number[], percentile: number): number {
    const sorted = values.sort((a, b) => a - b)
    const index = Math.ceil(sorted.length * percentile) - 1
    return sorted[index] || 0
  }
}

export const apiPerformanceMonitor = new APIPerformanceMonitor()

// API性能监控中间件
export function withPerformanceMonitoring(
  handler: (req: NextRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest): Promise<NextResponse> => {
    const start = performance.now()
    
    try {
      const response = await handler(req)
      const duration = performance.now() - start
      
      apiPerformanceMonitor.record({
        method: req.method,
        url: req.url,
        statusCode: response.status,
        duration,
        timestamp: Date.now(),
        userAgent: req.headers.get('user-agent') || undefined,
        ip: req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || undefined,
      })
      
      return response
    } catch (error) {
      const duration = performance.now() - start
      
      apiPerformanceMonitor.record({
        method: req.method,
        url: req.url,
        statusCode: 500,
        duration,
        timestamp: Date.now(),
      })
      
      throw error
    }
  }
}
```

### 2. 实时监控仪表板

#### 监控API端点
```typescript
// src/app/api/monitoring/performance/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { apiPerformanceMonitor } from '@/lib/api-performance'

export async function POST(request: NextRequest) {
  try {
    const data = await request.json()
    
    // 验证数据格式
    if (!data.method || !data.url || !data.duration) {
      return NextResponse.json({ error: 'Invalid performance data' }, { status: 400 })
    }
    
    // 记录性能数据
    apiPerformanceMonitor.record({
      ...data,
      timestamp: data.timestamp || Date.now(),
    })
    
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Performance monitoring error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function GET(request: NextRequest) {
  try {
    const metrics = apiPerformanceMonitor.getMetrics()
    
    return NextResponse.json({
      success: true,
      data: metrics,
      timestamp: Date.now(),
    })
  } catch (error) {
    console.error('Performance metrics error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
```

#### 监控仪表板组件
```typescript
// src/components/monitoring/PerformanceDashboard.tsx
import { useState, useEffect } from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

interface PerformanceMetrics {
  timestamp: number
  avgDuration: number
  p95Duration: number
  errorRate: number
  requestCount: number
}

export function PerformanceDashboard() {
  const [metrics, setMetrics] = useState<PerformanceMetrics[]>([])
  const [isLoading, setIsLoading] = useState(true)
  
  useEffect(() => {
    const fetchMetrics = async () => {
      try {
        const response = await fetch('/api/monitoring/performance')
        const data = await response.json()
        
        if (data.success) {
          setMetrics(prev => {
            const newMetrics = {
              timestamp: Date.now(),
              ...data.data,
            }
            return [...prev.slice(-59), newMetrics] // 保持最近60个数据点
          })
        }
      } catch (error) {
        console.error('Failed to fetch performance metrics:', error)
      } finally {
        setIsLoading(false)
      }
    }
    
    // 立即获取一次数据
    fetchMetrics()
    
    // 每10秒更新一次
    const interval = setInterval(fetchMetrics, 10000)
    
    return () => clearInterval(interval)
  }, [])
  
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    )
  }
  
  const latestMetrics = metrics[metrics.length - 1]
  
  return (
    <div className="p-6 bg-white rounded-lg shadow-lg">
      <h2 className="text-xl font-semibold mb-6">实时性能监控</h2>
      
      {/* 实时指标卡片 */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <div className="bg-blue-50 p-4 rounded-lg">
          <div className="text-sm text-blue-600">平均响应时间</div>
          <div className="text-2xl font-bold text-blue-800">
            {latestMetrics?.avgDuration || 0}ms
          </div>
        </div>
        
        <div className="bg-green-50 p-4 rounded-lg">
          <div className="text-sm text-green-600">95%分位响应时间</div>
          <div className="text-2xl font-bold text-green-800">
            {latestMetrics?.p95Duration || 0}ms
          </div>
        </div>
        
        <div className="bg-yellow-50 p-4 rounded-lg">
          <div className="text-sm text-yellow-600">错误率</div>
          <div className="text-2xl font-bold text-yellow-800">
            {((latestMetrics?.errorRate || 0) * 100).toFixed(2)}%
          </div>
        </div>
        
        <div className="bg-purple-50 p-4 rounded-lg">
          <div className="text-sm text-purple-600">总请求数</div>
          <div className="text-2xl font-bold text-purple-800">
            {latestMetrics?.requestCount || 0}
          </div>
        </div>
      </div>
      
      {/* 性能趋势图表 */}
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={metrics}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis 
              dataKey="timestamp" 
              tickFormatter={(value) => new Date(value).toLocaleTimeString()}
            />
            <YAxis />
            <Tooltip 
              labelFormatter={(value) => new Date(value).toLocaleString()}
            />
            <Legend />
            <Line 
              type="monotone" 
              dataKey="avgDuration" 
              stroke="#3B82F6" 
              name="平均响应时间"
              strokeWidth={2}
            />
            <Line 
              type="monotone" 
              dataKey="p95Duration" 
              stroke="#10B981" 
              name="95%分位响应时间"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
```

## 📈 性能优化实施计划

### 阶段一：前端优化 (1-2周)
```yaml
第一周:
  - 代码分割和懒加载实施
  - 图片优化组件开发
  - 缓存策略集成
  - 性能监控部署

第二周:
  - 状态管理优化
  - 组件渲染优化
  - 打包体积优化
  - 性能测试验证
```

### 阶段二：后端优化 (2-3周)
```yaml
第三周:
  - API响应优化
  - Redis缓存层实施
  - 数据库查询优化
  - 并发处理优化

第四周:
  - 响应压缩配置
  - CDN集成优化
  - 负载均衡配置
  - 性能基准测试

第五周:
  - 监控系统完善
  - 告警机制配置
  - 性能报告生成
  - 优化效果验证
```

### 阶段三：系统优化 (1-2周)
```yaml
第六周:
  - Docker镜像优化
  - 容器资源调优
  - 网络优化配置
  - 安全性能平衡

第七周:
  - 性能自动化测试
  - 持续性能监控
  - 性能回归防护
  - 文档和培训完善
```

## 🔧 性能测试工具

### 1. Lighthouse CI配置
```yaml
# .lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: [
        'http://localhost:3000',
        'http://localhost:3000/search',
        'http://localhost:3000/login',
      ],
      numberOfRuns: 3,
      settings: {
        chromeFlags: '--no-sandbox --headless',
      },
    },
    assert: {
      assertions: {
        'categories:performance': ['warn', { minScore: 0.8 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['warn', { minScore: 0.8 }],
        'categories:seo': ['warn', { minScore: 0.8 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
}
```

### 2. 性能基准测试
```typescript
// scripts/performance-benchmark.js
const { performance } = require('perf_hooks')
const puppeteer = require('puppeteer')

class PerformanceBenchmark {
  constructor() {
    this.results = []
  }
  
  async runBenchmark(url, options = {}) {
    const browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    })
    
    try {
      const page = await browser.newPage()
      
      // 启用性能监控
      await page.coverage.startJSCoverage()
      
      const start = performance.now()
      await page.goto(url, { waitUntil: 'networkidle0' })
      const loadTime = performance.now() - start
      
      // 获取性能指标
      const metrics = await page.evaluate(() => {
        const navigation = performance.getEntriesByType('navigation')[0]
        return {
          fcp: performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
          lcp: performance.getEntriesByType('largest-contentful-paint')[0]?.startTime || 0,
          ttfb: navigation.responseStart - navigation.requestStart,
          domContentLoaded: navigation.domContentLoadedEventEnd - navigation.navigationStart,
          loadComplete: navigation.loadEventEnd - navigation.navigationStart,
        }
      })
      
      // 停止代码覆盖率收集
      const [jsCoverage] = await Promise.all([
        page.coverage.stopJSCoverage(),
      ])
      
      // 计算代码使用率
      const jsBytesUsed = jsCoverage.reduce((total, entry) => {
        return total + entry.ranges.reduce((sum, range) => {
          return sum + range.end - range.start
        }, 0)
      }, 0)
      
      const jsTotalBytes = jsCoverage.reduce((total, entry) => total + entry.text.length, 0)
      const jsUsagePercent = ((jsBytesUsed / jsTotalBytes) * 100).toFixed(2)
      
      const result = {
        url,
        loadTime: Math.round(loadTime),
        ...metrics,
        jsUsagePercent,
        timestamp: Date.now(),
      }
      
      this.results.push(result)
      console.log(`Benchmark completed for ${url}:`, result)
      
      await page.close()
    } catch (error) {
      console.error(`Benchmark failed for ${url}:`, error)
    } finally {
      await browser.close()
    }
  }
  
  async runMultipleBenchmarks(urls) {
    console.log('Starting performance benchmarks...')
    
    for (const url of urls) {
      await this.runBenchmark(url)
    }
    
    this.generateReport()
  }
  
  generateReport() {
    const avgLoadTime = this.results.reduce((sum, r) => sum + r.loadTime, 0) / this.results.length
    const avgFCP = this.results.reduce((sum, r) => sum + r.fcp, 0) / this.results.length
    const avgLCP = this.results.reduce((sum, r) => sum + r.lcp, 0) / this.results.length
    const avgJSUsage = this.results.reduce((sum, r) => sum + parseFloat(r.jsUsagePercent), 0) / this.results.length
    
    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        totalTests: this.results.length,
        avgLoadTime: Math.round(avgLoadTime),
        avgFCP: Math.round(avgFCP),
        avgLCP: Math.round(avgLCP),
        avgJSUsage: Math.round(avgJSUsage * 100) / 100,
      },
      results: this.results,
    }
    
    require('fs').writeFileSync('performance-benchmark-report.json', JSON.stringify(report, null, 2))
    console.log('Performance benchmark report generated:', report.summary)
  }
}

// 使用示例
const benchmark = new PerformanceBenchmark()
benchmark.runMultipleBenchmarks([
  'http://localhost:3000',
  'http://localhost:3000/search?keyword=test',
  'http://localhost:3000/login',
])
```

## 📋 性能检查清单

### 开发阶段检查
- [ ] 组件懒加载实施
- [ ] 图片优化配置
- [ ] 缓存策略集成
- [ ] 代码分割验证
- [ ] 打包分析完成
- [ ] 性能测试通过

### 部署前检查
- [ ] 生产构建验证
- [ ] Lighthouse评分达标
- [ ] API性能测试通过
- [ ] 缓存配置正确
- [ ] 监控系统部署
- [ ] 告警机制配置

### 运行时监控
- [ ] 性能指标正常
- [ ] 错误率在范围内
- [ ] 响应时间达标
- [ ] 资源使用合理
- [ ] 缓存命中率良好
- [ ] 用户反馈积极

---

**文档维护**: 性能工程师  
**更新频率**: 性能优化变更时更新  
**版本**: v3.2.0-fixed  
**最后更新**: 2025-10-06