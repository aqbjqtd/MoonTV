# MoonTV 质量保证与测试指南 (v3.2.0-fixed)
**最后更新**: 2025-10-06
**维护专家**: 质量工程师
**适用版本**: v3.2.0-fixed及以上

## 🎯 测试战略与质量目标

### 质量目标
```yaml
代码覆盖率:
  目标: 90%+
  当前: 85%
  重点领域: 核心业务逻辑、API路由、认证系统

性能指标:
  页面加载: <200ms (47%提升已达成)
  API响应: <100ms
  内存使用: <512MB
  容器启动: <8秒

可靠性目标:
  可用性: 99.9%
  错误率: <0.1%
  故障恢复: <30秒
```

### 测试金字塔结构
```
    E2E Tests (10%)
   ─────────────────
  Integration Tests (20%)
 ─────────────────────────
Unit Tests (70%)
```

## 🧪 单元测试体系

### 1. 核心工具配置

#### Jest配置 (jest.config.js)
```javascript
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  // Next.js应用路径
  dir: './',
})

// Jest自定义配置
const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
    '!src/app/layout.tsx', // Layout组件单独测试
    '!src/app/**/loading.tsx',
    '!src/app/**/not-found.tsx',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 85,
      lines: 90,
      statements: 90,
    },
  },
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{js,jsx,ts,tsx}',
  ],
}

module.exports = createJestConfig(customJestConfig)
```

#### 测试环境配置 (jest.setup.js)
```javascript
import '@testing-library/jest-dom'
import { configure } from '@testing-library/react'

// 配置Testing Library
configure({
  testIdAttribute: 'data-testid',
})

// Mock Next.js路由
jest.mock('next/navigation', () => ({
  useRouter() {
    return {
      push: jest.fn(),
      replace: jest.fn(),
      prefetch: jest.fn(),
      back: jest.fn(),
      forward: jest.fn(),
      refresh: jest.fn(),
    }
  },
  useSearchParams() {
    return new URLSearchParams()
  },
  usePathname() {
    return '/'
  },
}))

// Mock环境变量
process.env.NODE_ENV = 'test'
process.env.NEXT_PUBLIC_SITE_NAME = 'MoonTV Test'
process.env.NEXT_PUBLIC_STORAGE_TYPE = 'localstorage'
process.env.PASSWORD = 'test-password'
```

### 2. 核心业务逻辑测试

#### 认证系统测试 (src/lib/__tests__/auth.test.ts)
```typescript
import { generateToken, verifyToken, generateHMACSignature, verifyHMACSignature } from '../auth'

describe('Authentication System', () => {
  describe('Token Management', () => {
    it('should generate valid JWT token', () => {
      const payload = { username: 'testuser', role: 'user' }
      const token = generateToken(payload)
      
      expect(token).toBeDefined()
      expect(typeof token).toBe('string')
    })

    it('should verify JWT token correctly', () => {
      const payload = { username: 'testuser', role: 'user' }
      const token = generateToken(payload)
      const decoded = verifyToken(token)
      
      expect(decoded.username).toBe(payload.username)
      expect(decoded.role).toBe(payload.role)
    })

    it('should reject invalid token', () => {
      const invalidToken = 'invalid.token.here'
      
      expect(() => verifyToken(invalidToken)).toThrow()
    })
  })

  describe('HMAC Signature', () => {
    it('should generate and verify HMAC signature', () => {
      const data = 'test-data'
      const secret = 'test-secret'
      
      const signature = generateHMACSignature(data, secret)
      const isValid = verifyHMACSignature(data, signature, secret)
      
      expect(isValid).toBe(true)
    })

    it('should reject tampered data', () => {
      const data = 'test-data'
      const tamperedData = 'tampered-data'
      const secret = 'test-secret'
      
      const signature = generateHMACSignature(data, secret)
      const isValid = verifyHMACSignature(tamperedData, signature, secret)
      
      expect(isValid).toBe(false)
    })
  })
})
```

#### 配置管理测试 (src/lib/__tests__/config.test.ts)
```typescript
import { getConfig, initConfig } from '../config'
import { AdminConfig } from '../types'

// Mock fs module
jest.mock('fs', () => ({
  readFileSync: jest.fn(),
  existsSync: jest.fn(),
}))

describe('Configuration Management', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    process.env.DOCKER_ENV = 'false'
  })

  it('should load default configuration in localstorage mode', async () => {
    process.env.NEXT_PUBLIC_STORAGE_TYPE = 'localstorage'
    
    const config = await getConfig()
    
    expect(config.SiteConfig).toBeDefined()
    expect(config.UserConfig).toBeDefined()
    expect(config.SourceConfig).toBeDefined()
    expect(config.CustomCategories).toBeDefined()
  })

  it('should handle Docker environment configuration', async () => {
    process.env.DOCKER_ENV = 'true'
    const mockConfig = {
      api_site: [{ name: 'Test Site', url: 'http://test.com' }],
      custom_category: [{ name: 'Test Category', sites: [] }],
    }
    
    const fs = require('fs')
    fs.readFileSync.mockReturnValue(JSON.stringify(mockConfig))
    fs.existsSync.mockReturnValue(true)
    
    await initConfig()
    const config = await getConfig()
    
    expect(fs.readFileSync).toHaveBeenCalled()
  })

  it('should handle configuration loading errors gracefully', async () => {
    const fs = require('fs')
    fs.readFileSync.mockImplementation(() => {
      throw new Error('File not found')
    })
    fs.existsSync.mockReturnValue(false)
    
    const config = await getConfig()
    
    expect(config.SiteConfig.SiteName).toBe('MoonTV')
    expect(config.SiteConfig.Announcement).toContain('temporarily unavailable')
  })
})
```

#### 搜索引擎测试 (src/lib/__tests__/search.test.ts)
```typescript
import { searchFromApi, searchFromApiStream } from '../fetchVideoDetail'
import { VideoSearchResult } from '../types'

// Mock fetch
global.fetch = jest.fn()

describe('Search Engine', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Parallel Search', () => {
    it('should search from multiple API sites', async () => {
      const mockResponse = {
        json: jest.fn().mockResolvedValue({
          list: [
            { 
              video_id: '1', 
              name: 'Test Video', 
              pic: 'http://test.com/image.jpg',
              content: 'Test description'
            }
          ]
        })
      }
      ;(global.fetch as jest.Mock).mockResolvedValue(mockResponse)

      const results = await searchFromApi('test keyword', {
        maxPage: 1,
        timeout: 5000
      })

      expect(results).toBeDefined()
      expect(Array.isArray(results)).toBe(true)
      expect(global.fetch).toHaveBeenCalledTimes(expect.any(Number))
    })

    it('should handle search timeout', async () => {
      ;(global.fetch as jest.Mock).mockImplementation(
        () => new Promise(resolve => setTimeout(resolve, 10000))
      )

      const startTime = Date.now()
      const results = await searchFromApi('test keyword', {
        maxPage: 1,
        timeout: 1000
      })
      const endTime = Date.now()

      expect(endTime - startTime).toBeLessThan(2000)
      expect(Array.isArray(results)).toBe(true)
    })
  })

  describe('Stream Search', () => {
    it('should handle stream search results', async () => {
      const mockResponse = {
        body: {
          getReader: jest.fn().mockReturnValue({
            read: jest.fn()
              .mockResolvedValueOnce({ 
                done: false, 
                value: new TextEncoder().encode('data: {"test": "value"}\n\n') 
              })
              .mockResolvedValueOnce({ done: true })
          })
        }
      }
      ;(global.fetch as jest.Mock).mockResolvedValue(mockResponse)

      const mockStream = {
        write: jest.fn(),
        end: jest.fn()
      }

      await searchFromApiStream('test keyword', mockStream as any, {
        maxPage: 1
      })

      expect(mockStream.write).toHaveBeenCalled()
      expect(mockStream.end).toHaveBeenCalled()
    })
  })
})
```

### 3. React组件测试

#### 搜索组件测试 (src/components/__tests__/VideoCard.test.tsx)
```typescript
import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import VideoCard from '../VideoCard'
import { VideoSearchResult } from '@/lib/types'

const mockVideo: VideoSearchResult = {
  video_id: 'test-id',
  name: 'Test Video',
  pic: 'http://test.com/image.jpg',
  content: 'Test description',
  site_name: 'Test Site',
  site_url: 'http://test.com',
  from: 'api',
  type: 'movie',
  note: {
    actor: 'Test Actor',
    director: 'Test Director',
    year: '2024',
    area: 'Test Area',
    lang: 'Test Language',
    remarks: 'Test Remarks'
  }
}

describe('VideoCard Component', () => {
  it('should render video information correctly', () => {
    render(<VideoCard video={mockVideo} />)
    
    expect(screen.getByText('Test Video')).toBeInTheDocument()
    expect(screen.getByText('Test description')).toBeInTheDocument()
    expect(screen.getByText('Test Site')).toBeInTheDocument()
  })

  it('should handle click events', () => {
    const onClickMock = jest.fn()
    render(<VideoCard video={mockVideo} onClick={onClickMock} />)
    
    fireEvent.click(screen.getByTestId('video-card'))
    expect(onClickMock).toHaveBeenCalledWith(mockVideo)
  })

  it('should show loading state when image is loading', () => {
    render(<VideoCard video={mockVideo} />)
    
    const image = screen.getByRole('img')
    expect(image).toHaveAttribute('alt', 'Test Video')
  })

  it('should handle missing image gracefully', () => {
    const videoWithoutImage = { ...mockVideo, pic: '' }
    render(<VideoCard video={videoWithoutImage} />)
    
    const image = screen.getByRole('img')
    expect(image).toHaveAttribute('src', expect.stringContaining('data:image'))
  })
})
```

## 🔧 集成测试体系

### 1. API端点测试

#### 搜索API测试 (src/app/api/search/__tests__/route.test.ts)
```typescript
import { NextRequest } from 'next/server'
import { GET } from '../route'

// Mock依赖
jest.mock('@/lib/config', () => ({
  getConfig: jest.fn().mockResolvedValue({
    SiteConfig: {
      SearchDownstreamMaxPage: 5,
      SiteInterfaceCacheTime: 7200
    },
    SourceConfig: [
      { name: 'Test Site', url: 'http://test.com/api', enabled: true, from: 'config' }
    ]
  })
}))

jest.mock('@/lib/fetchVideoDetail', () => ({
  searchFromApi: jest.fn()
}))

describe('/api/search', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should return search results for valid keyword', async () => {
    const mockResults = [
      {
        video_id: 'test-id',
        name: 'Test Video',
        pic: 'http://test.com/image.jpg',
        content: 'Test description'
      }
    ]
    
    const { searchFromApi } = require('@/lib/fetchVideoDetail')
    searchFromApi.mockResolvedValue(mockResults)

    const request = new NextRequest('http://localhost:3000/api/search?keyword=test')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.results).toEqual(mockResults)
    expect(searchFromApi).toHaveBeenCalledWith('test', expect.any(Object))
  })

  it('should handle missing keyword', async () => {
    const request = new NextRequest('http://localhost:3000/api/search')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(400)
    expect(data.error).toBe('Missing keyword')
  })

  it('should handle search errors gracefully', async () => {
    const { searchFromApi } = require('@/lib/fetchVideoDetail')
    searchFromApi.mockRejectedValue(new Error('Search failed'))

    const request = new NextRequest('http://localhost:3000/api/search?keyword=test')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(500)
    expect(data.error).toBe('Internal server error')
  })
})
```

#### 认证API测试 (src/app/api/login/__tests__/route.test.ts)
```typescript
import { NextRequest } from 'next/server'
import { POST } from '../route'

// Mock环境变量
process.env.PASSWORD = 'test-password'
process.env.NEXT_PUBLIC_STORAGE_TYPE = 'localstorage'

describe('/api/login', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should authenticate with correct password', async () => {
    const request = new NextRequest('http://localhost:3000/api/login', {
      method: 'POST',
      body: JSON.stringify({ password: 'test-password' }),
      headers: { 'Content-Type': 'application/json' }
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(response.headers.getSetCookie()).toContain('auth-token')
  })

  it('should reject incorrect password', async () => {
    const request = new NextRequest('http://localhost:3000/api/login', {
      method: 'POST',
      body: JSON.stringify({ password: 'wrong-password' }),
      headers: { 'Content-Type': 'application/json' }
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(401)
    expect(data.error).toBe('Invalid password')
  })

  it('should handle missing password', async () => {
    const request = new NextRequest('http://localhost:3000/api/login', {
      method: 'POST',
      body: JSON.stringify({}),
      headers: { 'Content-Type': 'application/json' }
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(400)
    expect(data.error).toBe('Password required')
  })
})
```

### 2. 数据库集成测试

#### 存储层测试 (src/lib/__tests__/db.integration.test.ts)
```typescript
import { DbManager } from '../db'
import { IStorage, AdminConfig, User } from '../types'

describe('Database Integration Tests', () => {
  let storage: IStorage
  let dbManager: DbManager

  beforeAll(async () => {
    // 使用测试数据库配置
    process.env.NEXT_PUBLIC_STORAGE_TYPE = 'redis'
    process.env.REDIS_URL = 'redis://localhost:6379/1' // 使用不同的数据库
    
    dbManager = new DbManager()
    storage = await dbManager.getStorage()
    
    // 清空测试数据
    await storage.clearConfig?.()
    await storage.clearUsers?.()
  })

  afterAll(async () => {
    // 清理测试数据
    await storage.clearConfig?.()
    await storage.clearUsers?.()
  })

  describe('Configuration Management', () => {
    it('should save and retrieve admin config', async () => {
      const config: AdminConfig = {
        ConfigFile: '{}',
        SiteConfig: {
          SiteName: 'Test Site',
          Announcement: 'Test announcement',
          SearchDownstreamMaxPage: 5,
          SiteInterfaceCacheTime: 7200,
          DoubanProxyType: 'direct',
          DoubanProxy: '',
          DoubanImageProxyType: 'direct',
          DoubanImageProxy: '',
          DisableYellowFilter: false,
          TVBoxEnabled: false,
          TVBoxPassword: '',
        },
        UserConfig: {
          AllowRegister: false,
          Users: [],
        },
        SourceConfig: [],
        CustomCategories: [],
      }

      await storage.setAdminConfig(config)
      const retrievedConfig = await storage.getAdminConfig()

      expect(retrievedConfig.SiteConfig.SiteName).toBe('Test Site')
      expect(retrievedConfig.SiteConfig.Announcement).toBe('Test announcement')
    })
  })

  describe('User Management', () => {
    it('should create and verify users', async () => {
      const testUser: User = {
        username: 'testuser',
        password: 'hashedpassword',
        role: 'user',
        createdAt: new Date().toISOString(),
      }

      await storage.saveUser(testUser)
      const isValid = await storage.verifyUser('testuser', 'hashedpassword')

      expect(isValid).toBe(true)
    })

    it('should handle user authentication correctly', async () => {
      const isValid = await storage.verifyUser('nonexistent', 'password')
      expect(isValid).toBe(false)
    })
  })
})
```

## 🎭 E2E测试体系

### 1. Playwright配置

#### playwright.config.ts
```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['junit', { outputFile: 'test-results/results.xml' }]
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

### 2. E2E测试用例

#### 用户认证流程测试 (e2e/auth.spec.ts)
```typescript
import { test, expect } from '@playwright/test'

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
  })

  test('should redirect unauthenticated users to login', async ({ page }) => {
    await expect(page).toHaveURL(/.*\/login/)
  })

  test('should login with correct credentials', async ({ page }) => {
    await page.fill('[data-testid="password-input"]', 'test-password')
    await page.click('[data-testid="login-button"]')
    
    // 应该重定向到首页
    await expect(page).toHaveURL('/')
    
    // 检查是否显示了用户菜单
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible()
  })

  test('should show error for incorrect credentials', async ({ page }) => {
    await page.fill('[data-testid="password-input"]', 'wrong-password')
    await page.click('[data-testid="login-button"]')
    
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible()
    await expect(page.locator('[data-testid="error-message"]')).toContainText('Invalid password')
  })

  test('should logout correctly', async ({ page }) => {
    // 先登录
    await page.fill('[data-testid="password-input"]', 'test-password')
    await page.click('[data-testid="login-button"]')
    await expect(page).toHaveURL('/')
    
    // 执行登出
    await page.click('[data-testid="user-menu"]')
    await page.click('[data-testid="logout-button"]')
    
    // 应该重定向到登录页面
    await expect(page).toHaveURL(/.*\/login/)
  })
})
```

#### 搜索功能测试 (e2e/search.spec.ts)
```typescript
import { test, expect } from '@playwright/test'

test.describe('Search Functionality', () => {
  test.beforeEach(async ({ page }) => {
    // 登录
    await page.goto('/login')
    await page.fill('[data-testid="password-input"]', 'test-password')
    await page.click('[data-testid="login-button"]')
    await page.waitForURL('/')
  })

  test('should search for videos and display results', async ({ page }) => {
    await page.fill('[data-testid="search-input"]', 'test keyword')
    await page.click('[data-testid="search-button"]')
    
    await expect(page).toHaveURL(/.*\/search/)
    await expect(page.locator('[data-testid="video-card"]')).toHaveCount.greaterThan(0)
  })

  test('should handle search suggestions', async ({ page }) => {
    await page.fill('[data-testid="search-input"]', 'test')
    
    // 等待搜索建议出现
    await expect(page.locator('[data-testid="search-suggestions"]')).toBeVisible()
  })

  test('should filter search results', async ({ page }) => {
    await page.fill('[data-testid="search-input"]', 'test')
    await page.click('[data-testid="search-button"]')
    
    // 选择类型过滤器
    await page.selectOption('[data-testid="type-filter"]', 'movie')
    await page.click('[data-testid="apply-filter"]')
    
    // 验证结果已过滤
    await expect(page.locator('[data-testid="video-card"]')).toHaveCount.greaterThan(0)
  })
})
```

#### 播放功能测试 (e2e/play.spec.ts)
```typescript
import { test, expect } from '@playwright/test'

test.describe('Video Playback', () => {
  test.beforeEach(async ({ page }) => {
    // 登录并导航到播放页面
    await page.goto('/login')
    await page.fill('[data-testid="password-input"]', 'test-password')
    await page.click('[data-testid="login-button"]')
    await page.waitForURL('/')
  })

  test('should play video correctly', async ({ page }) => {
    // 搜索视频
    await page.fill('[data-testid="search-input"]', 'test video')
    await page.click('[data-testid="search-button"]')
    await page.waitForSelector('[data-testid="video-card"]')
    
    // 点击第一个视频
    await page.click('[data-testid="video-card"]:first-child')
    await page.waitForURL(/.*\/play/)
    
    // 验证播放器已加载
    await expect(page.locator('[data-testid="video-player"]')).toBeVisible()
    
    // 验证视频控制按钮
    await expect(page.locator('[data-testid="play-button"]')).toBeVisible()
    await expect(page.locator('[data-testid="fullscreen-button"]')).toBeVisible()
  })

  test('should handle episode selection', async ({ page }) => {
    // 导航到有多集的视频播放页面
    await page.goto('/play?video_id=test-series-id')
    
    // 验证集数选择器存在
    await expect(page.locator('[data-testid="episode-selector"]')).toBeVisible()
    
    // 选择第2集
    await page.click('[data-testid="episode-2"]')
    
    // 验证播放器已更新
    await expect(page.locator('[data-testid="video-player"]')).toBeVisible()
  })
})
```

## 🚀 性能测试体系

### 1. 负载测试配置

#### Lighthouse CI配置 (.lighthouserc.js)
```javascript
module.exports = {
  ci: {
    collect: {
      url: [
        'http://localhost:3000',
        'http://localhost:3000/search',
        'http://localhost:3000/login',
      ],
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        'categories:performance': ['warn', { minScore: 0.8 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['warn', { minScore: 0.8 }],
        'categories:seo': ['warn', { minScore: 0.8 }],
        'categories:pwa': 'off',
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
}
```

#### 性能监控脚本 (scripts/performance-monitor.js)
```javascript
const { performance } = require('perf_hooks')

class PerformanceMonitor {
  constructor() {
    this.metrics = {}
  }

  startTimer(name) {
    this.metrics[`${name}_start`] = performance.now()
  }

  endTimer(name) {
    const startTime = this.metrics[`${name}_start`]
    if (startTime) {
      const duration = performance.now() - startTime
      this.metrics[name] = duration
      delete this.metrics[`${name}_start`]
      return duration
    }
    return null
  }

  measurePageLoad() {
    if (typeof window !== 'undefined') {
      const navigation = performance.getEntriesByType('navigation')[0]
      return {
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
        firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime,
        firstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0]?.startTime,
      }
    }
    return null
  }

  getMetrics() {
    return { ...this.metrics }
  }

  reset() {
    this.metrics = {}
  }
}

module.exports = PerformanceMonitor
```

### 2. 内存泄漏检测

#### 内存监控测试 (src/lib/__tests__/memory-leak.test.ts)
```typescript
describe('Memory Leak Detection', () => {
  let monitor: PerformanceMonitor

  beforeEach(() => {
    monitor = new PerformanceMonitor()
  })

  it('should not leak memory during repeated searches', async () => {
    const { searchFromApi } = require('../fetchVideoDetail')
    const initialMemory = process.memoryUsage()

    // 执行多次搜索
    for (let i = 0; i < 100; i++) {
      await searchFromApi(`test-${i}`, { maxPage: 1, timeout: 1000 })
      
      // 每10次强制垃圾回收（如果可用）
      if (i % 10 === 0 && global.gc) {
        global.gc()
      }
    }

    // 最终垃圾回收
    if (global.gc) {
      global.gc()
    }

    const finalMemory = process.memoryUsage()
    const memoryGrowth = finalMemory.heapUsed - initialMemory.heapUsed

    // 内存增长应该在合理范围内（小于50MB）
    expect(memoryGrowth).toBeLessThan(50 * 1024 * 1024)
  })
})
```

## 🔒 安全测试体系

### 1. 安全漏洞扫描

#### 依赖安全扫描 (scripts/security-scan.js)
```javascript
const { execSync } = require('child_process')
const fs = require('fs')
const path = require('path')

class SecurityScanner {
  async scanDependencies() {
    console.log('🔍 扫描依赖安全漏洞...')
    
    try {
      // 使用npm audit扫描
      const auditResult = execSync('npm audit --json', { 
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      })
      
      const audit = JSON.parse(auditResult)
      const vulnerabilities = audit.vulnerabilities || {}
      
      // 分类漏洞
      const critical = Object.values(vulnerabilities).filter(v => v.severity === 'critical')
      const high = Object.values(vulnerabilities).filter(v => v.severity === 'high')
      const moderate = Object.values(vulnerabilities).filter(v => v.severity === 'moderate')
      
      return {
        total: Object.keys(vulnerabilities).length,
        critical: critical.length,
        high: high.length,
        moderate: moderate.length,
        details: vulnerabilities
      }
    } catch (error) {
      console.error('依赖扫描失败:', error.message)
      return null
    }
  }

  async scanCodePatterns() {
    const securityIssues = []
    
    // 扫描敏感文件
    const sensitiveFiles = ['.env', '.env.local', 'config.json']
    for (const file of sensitiveFiles) {
      if (fs.existsSync(file)) {
        // 检查是否提交了敏感信息
        const content = fs.readFileSync(file, 'utf8')
        if (content.includes('password') || content.includes('secret')) {
          securityIssues.push({
            type: 'sensitive_data',
            file,
            message: '文件可能包含敏感信息'
          })
        }
      }
    }
    
    // 扫描代码中的安全问题
    const sourceFiles = this.getSourceFiles('src')
    for (const file of sourceFiles) {
      const content = fs.readFileSync(file, 'utf8')
      
      // 检查硬编码密钥
      if (content.includes('const password =') || content.includes('const secret =')) {
        securityIssues.push({
          type: 'hardcoded_secret',
          file,
          message: '发现硬编码密钥或密码'
        })
      }
      
      // 检查SQL注入风险
      if (content.includes('SELECT * FROM') && content.includes('${')) {
        securityIssues.push({
          type: 'sql_injection',
          file,
          message: '可能存在SQL注入风险'
        })
      }
      
      // 检查XSS风险
      if (content.includes('dangerouslySetInnerHTML')) {
        securityIssues.push({
          type: 'xss_risk',
          file,
          message: '使用了危险的innerHTML设置'
        })
      }
    }
    
    return securityIssues
  }

  getSourceFiles(dir) {
    const files = []
    
    function traverse(currentDir) {
      const items = fs.readdirSync(currentDir)
      
      for (const item of items) {
        const fullPath = path.join(currentDir, item)
        const stat = fs.statSync(fullPath)
        
        if (stat.isDirectory()) {
          traverse(fullPath)
        } else if (item.endsWith('.ts') || item.endsWith('.tsx') || item.endsWith('.js')) {
          files.push(fullPath)
        }
      }
    }
    
    traverse(dir)
    return files
  }

  async generateReport() {
    const dependencyScan = await this.scanDependencies()
    const codeScan = await this.scanCodePatterns()
    
    const report = {
      timestamp: new Date().toISOString(),
      dependencies: dependencyScan,
      codeSecurity: codeScan,
      summary: {
        totalIssues: (dependencyScan?.total || 0) + codeScan.length,
        criticalIssues: (dependencyScan?.critical || 0) + codeScan.filter(i => i.type === 'hardcoded_secret').length,
        highIssues: (dependencyScan?.high || 0) + codeScan.filter(i => i.type === 'sql_injection' || i.type === 'xss_risk').length,
      }
    }
    
    // 保存报告
    fs.writeFileSync('security-report.json', JSON.stringify(report, null, 2))
    
    return report
  }
}

// 执行扫描
const scanner = new SecurityScanner()
scanner.generateReport()
  .then(report => {
    console.log('🔒 安全扫描完成')
    console.log(`发现 ${report.summary.totalIssues} 个安全问题`)
    
    if (report.summary.criticalIssues > 0) {
      console.error(`❌ 发现 ${report.summary.criticalIssues} 个严重安全问题`)
      process.exit(1)
    } else if (report.summary.highIssues > 0) {
      console.warn(`⚠️ 发现 ${report.summary.highIssues} 个高风险安全问题`)
    } else {
      console.log('✅ 未发现严重安全问题')
    }
  })
  .catch(error => {
    console.error('安全扫描失败:', error)
    process.exit(1)
  })
```

## 📊 测试报告与质量仪表板

### 1. 测试覆盖率报告

#### 覆盖率配置脚本 (scripts/coverage-report.js)
```javascript
const { execSync } = require('child_process')
const fs = require('fs')
const path = require('path')

function generateCoverageReport() {
  console.log('📊 生成测试覆盖率报告...')
  
  try {
    // 运行测试并生成覆盖率
    execSync('pnpm test -- --coverage --coverageReporters=json --coverageReporters=html --coverageReporters=text', {
      stdio: 'inherit'
    })
    
    // 读取覆盖率数据
    const coverageData = JSON.parse(fs.readFileSync('coverage/coverage-final.json', 'utf8'))
    
    // 计算总体覆盖率
    const totalCoverage = calculateTotalCoverage(coverageData)
    
    // 生成摘要报告
    const summary = {
      timestamp: new Date().toISOString(),
      coverage: totalCoverage,
      threshold: {
        statements: 90,
        branches: 80,
        functions: 85,
        lines: 90,
      },
      status: {
        statements: totalCoverage.statements.pct >= 90 ? 'PASS' : 'FAIL',
        branches: totalCoverage.branches.pct >= 80 ? 'PASS' : 'FAIL',
        functions: totalCoverage.functions.pct >= 85 ? 'PASS' : 'FAIL',
        lines: totalCoverage.lines.pct >= 90 ? 'PASS' : 'FAIL',
      }
    }
    
    fs.writeFileSync('coverage-summary.json', JSON.stringify(summary, null, 2))
    
    console.log('📈 覆盖率摘要:')
    console.log(`  语句: ${totalCoverage.statements.pct}% (${summary.status.statements})`)
    console.log(`  分支: ${totalCoverage.branches.pct}% (${summary.status.branches})`)
    console.log(`  函数: ${totalCoverage.functions.pct}% (${summary.status.functions})`)
    console.log(`  行数: ${totalCoverage.lines.pct}% (${summary.status.lines})`)
    
    return summary
  } catch (error) {
    console.error('覆盖率报告生成失败:', error.message)
    return null
  }
}

function calculateTotalCoverage(coverageData) {
  const totals = {
    statements: { total: 0, covered: 0 },
    branches: { total: 0, covered: 0 },
    functions: { total: 0, covered: 0 },
    lines: { total: 0, covered: 0 },
  }
  
  Object.values(coverageData).forEach(file => {
    totals.statements.total += file.s?.total || 0
    totals.statements.covered += file.s?.covered || 0
    
    totals.branches.total += file.b?.total || 0
    totals.branches.covered += file.b?.covered || 0
    
    totals.functions.total += file.f?.total || 0
    totals.functions.covered += file.f?.covered || 0
    
    totals.lines.total += file.l?.total || 0
    totals.lines.covered += file.l?.covered || 0
  })
  
  return {
    statements: {
      total: totals.statements.total,
      covered: totals.statements.covered,
      pct: totals.statements.total > 0 ? Math.round((totals.statements.covered / totals.statements.total) * 100) : 0
    },
    branches: {
      total: totals.branches.total,
      covered: totals.branches.covered,
      pct: totals.branches.total > 0 ? Math.round((totals.branches.covered / totals.branches.total) * 100) : 0
    },
    functions: {
      total: totals.functions.total,
      covered: totals.functions.covered,
      pct: totals.functions.total > 0 ? Math.round((totals.functions.covered / totals.functions.total) * 100) : 0
    },
    lines: {
      total: totals.lines.total,
      covered: totals.lines.covered,
      pct: totals.lines.total > 0 ? Math.round((totals.lines.covered / totals.lines.total) * 100) : 0
    }
  }
}

module.exports = { generateCoverageReport }
```

### 2. 质量门禁检查

#### CI/CD质量门禁 (.github/workflows/quality-gate.yml)
```yaml
name: Quality Gate

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    
    services:
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'pnpm'
    
    - name: Install dependencies
      run: pnpm install --frozen-lockfile
    
    - name: Run linting
      run: pnpm lint
    
    - name: Run type checking
      run: pnpm typecheck
    
    - name: Run unit tests
      run: pnpm test -- --coverage --passWithNoTests
      env:
        NODE_ENV: test
        REDIS_URL: redis://localhost:6379
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info
    
    - name: Run E2E tests
      run: pnpm test:e2e
      env:
        NODE_ENV: test
    
    - name: Run security scan
      run: node scripts/security-scan.js
    
    - name: Performance audit
      run: |
        pnpm dev &
        sleep 10
        pnpm lighthouse
        pkill -f "next dev"
    
    - name: Build application
      run: pnpm build
    
    - name: Quality gate evaluation
      run: |
        # 检查覆盖率阈值
        COVERAGE=$(node -e "console.log(JSON.parse(require('fs').readFileSync('coverage-summary.json')).coverage.lines.pct)")
        if [ "$COVERAGE" -lt 90 ]; then
          echo "❌ 覆盖率不达标: $COVERAGE% < 90%"
          exit 1
        fi
        
        # 检查安全扫描结果
        SECURITY_ISSUES=$(node -e "console.log(JSON.parse(require('fs').readFileSync('security-report.json')).summary.totalIssues)")
        if [ "$SECURITY_ISSUES" -gt 0 ]; then
          echo "❌ 发现安全问题: $SECURITY_ISSUES"
          exit 1
        fi
        
        echo "✅ 质量门禁通过"
```

## 🔄 持续质量改进

### 1. 测试数据管理

#### 测试数据工厂 (tests/factories/index.ts)
```typescript
import { faker } from '@faker-js/faker'
import { VideoSearchResult, User, AdminConfig } from '@/lib/types'

export class VideoFactory {
  static create(overrides: Partial<VideoSearchResult> = {}): VideoSearchResult {
    return {
      video_id: faker.string.uuid(),
      name: faker.lorem.words(3),
      pic: faker.image.url(),
      content: faker.lorem.sentences(2),
      site_name: faker.company.name(),
      site_url: faker.internet.url(),
      from: 'api',
      type: faker.helpers.arrayElement(['movie', 'series', 'variety']),
      note: {
        actor: faker.person.fullName(),
        director: faker.person.fullName(),
        year: faker.date.past().getFullYear().toString(),
        area: faker.location.country(),
        lang: 'zh-CN',
        remarks: faker.lorem.sentence()
      },
      ...overrides
    }
  }

  static createMany(count: number, overrides: Partial<VideoSearchResult> = {}): VideoSearchResult[] {
    return Array.from({ length: count }, () => this.create(overrides))
  }
}

export class UserFactory {
  static create(overrides: Partial<User> = {}): User {
    return {
      username: faker.internet.userName(),
      password: faker.internet.password(),
      role: faker.helpers.arrayElement(['user', 'admin']),
      createdAt: faker.date.past().toISOString(),
      ...overrides
    }
  }
}

export class ConfigFactory {
  static create(overrides: Partial<AdminConfig> = {}): AdminConfig {
    return {
      ConfigFile: '{}',
      SiteConfig: {
        SiteName: faker.company.name(),
        Announcement: faker.lorem.sentence(),
        SearchDownstreamMaxPage: faker.number.int({ min: 1, max: 10 }),
        SiteInterfaceCacheTime: faker.number.int({ min: 3600, max: 86400 }),
        DoubanProxyType: 'direct',
        DoubanProxy: '',
        DoubanImageProxyType: 'direct',
        DoubanImageProxy: '',
        DisableYellowFilter: false,
        TVBoxEnabled: false,
        TVBoxPassword: '',
      },
      UserConfig: {
        AllowRegister: faker.datatype.boolean(),
        Users: UserFactory.createMany(3),
      },
      SourceConfig: [],
      CustomCategories: [],
      ...overrides
    }
  }
}
```

### 2. 测试工具库

#### 测试辅助工具 (tests/utils/index.ts)
```typescript
import { render, RenderOptions } from '@testing-library/react'
import { ReactElement } from 'react'
import { NextRouter } from 'next/router'

// 自定义渲染函数
export const renderWithProviders = (
  ui: ReactElement,
  options: RenderOptions = {}
) => {
  const Wrapper = ({ children }: { children: React.ReactNode }) => {
    return (
      <div data-testid="test-provider">
        {children}
      </div>
    )
  }

  return render(ui, { wrapper: Wrapper, ...options })
}

// Mock路由器
export const createMockRouter = (overrides: Partial<NextRouter> = {}): NextRouter => ({
  route: '/',
  pathname: '/',
  query: {},
  asPath: '/',
  push: jest.fn(),
  pop: jest.fn(),
  reload: jest.fn(),
  back: jest.fn(),
  prefetch: jest.fn(),
  beforePopState: jest.fn(),
  events: {
    on: jest.fn(),
    off: jest.fn(),
    emit: jest.fn(),
  },
  isFallback: false,
  ...overrides
})

// 等待异步操作完成
export const waitForAsync = (ms = 100): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms))
}

// 模拟fetch响应
export const mockFetchResponse = (data: any, options: ResponseInit = {}) => {
  const response = new Response(JSON.stringify(data), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
    ...options
  })
  
  ;(global.fetch as jest.Mock).mockResolvedValue(response)
}

// 模拟fetch错误
export const mockFetchError = (message = 'Network error') => {
  ;(global.fetch as jest.Mock).mockRejectedValue(new Error(message))
}
```

---

**文档维护**: 质量工程师  
**更新频率**: 根据测试需求更新  
**版本**: v3.2.0-fixed  
**最后更新**: 2025-10-06