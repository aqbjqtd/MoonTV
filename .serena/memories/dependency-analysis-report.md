# MoonTV 项目依赖结构深度分析报告

## 执行摘要

通过对 MoonTV 项目的依赖结构进行深入分析，发现了导致镜像体积巨大的根本原因。当前 node_modules 目录大小为 922MB，其中存在大量未使用或冗余的依赖项，总计可优化空间约为**100-150MB**。

## 依赖体积分析

### 大体积依赖排序（已使用）

| 依赖          | 体积  | 使用状态  | 文件数    |
| ------------- | ----- | --------- | --------- |
| lucide-react  | 28MB  | ✅ 已使用 | 13 个文件 |
| hls.js        | 24MB  | ✅ 已使用 | 2 个文件  |
| artplayer     | 664KB | ✅ 已使用 | 1 个文件  |
| @dnd-kit 系列 | ~5MB  | ✅ 已使用 | 1 个文件  |
| sweetalert2   | ~1MB  | ✅ 已使用 | 2 个文件  |

### 未使用依赖（可移除）

| 依赖              | 体积  | 使用状态  | 优先级 |
| ----------------- | ----- | --------- | ------ |
| react-icons       | 83MB  | ❌ 未使用 | 🔴 高  |
| @heroicons/react  | 11MB  | ❌ 未使用 | 🟡 中  |
| swiper            | 3.7MB | ❌ 未使用 | 🟡 中  |
| framer-motion     | 2.6MB | ❌ 未使用 | 🟡 中  |
| @vidstack/react   | 2.5MB | ❌ 未使用 | 🟡 中  |
| @headlessui/react | 1.2MB | ❌ 未使用 | 🟡 中  |

## 详细分析结果

### 1. 图标库依赖分析

**发现的问题：**

- 项目安装了 3 个图标库：`lucide-react`、`@heroicons/react`、`react-icons`
- 实际只使用了`lucide-react`（13 个文件）
- `react-icons`（83MB）和`@heroicons/react`（11MB）完全未使用

**使用的 lucide-react 图标：**

- AlertCircle, CheckCircle（登录页面）
- ArrowLeft（返回按钮）
- Cat, Clover, Film, Home, Menu, Search, Star, Tv（导航）
- ChevronLeft, ChevronRight（滚动）
- ChevronRight（主页）
- ChevronUp, Search, X（搜索页面）
- GripVertical（管理页面）
- Heart（播放页面、视频卡片）
- Heart, Link, PlayCircleIcon, Trash2（视频卡片）
- Moon, Sun（主题切换）

### 2. 媒体播放依赖分析

**使用情况：**

- `artplayer`（664KB）✅ 已使用 - 主要播放器
- `hls.js`（24MB）✅ 已使用 - HLS 流媒体支持
- `@vidstack/react`（2.5MB）❌ 未使用 - 冗余播放器库
- `vidstack`（615KB）❌ 未使用 - 冗余播放器库

**优化建议：**

- 移除未使用的`@vidstack/react`和`vidstack`
- 考虑 hls.js 是否可以按需加载或使用更轻量的替代方案

### 3. 动画和 UI 库分析

**使用情况：**

- `@dnd-kit`系列（~5MB）✅ 已使用 - 管理页面拖拽排序
- `framer-motion`（2.6MB）❌ 未使用 - 动画库
- `@headlessui/react`（1.2MB）❌ 未使用 - 无头 UI 组件
- `swiper`（3.7MB）❌ 未使用 - 轮播组件

### 4. 其他依赖分析

**未使用的依赖：**

- `media-icons`（1.1MB）❌ 未使用 - 媒体图标库
- `clsx`和`tailwind-merge` - 样式工具，但代码中未发现使用

## 优化建议

### 高优先级优化（预计减少 100MB+）

#### 1. 移除未使用的图标库

```bash
# 移除 react-icons (83MB) 和 @heroicons/react (11MB)
pnpm remove react-icons @heroicons/react
```

**优化效果：** 减少 94MB

#### 2. 移除未使用的媒体播放库

```bash
# 移除 @vidstack/react (2.5MB) 和 vidstack (615KB)
pnpm remove @vidstack/react vidstack
```

**优化效果：** 减少 3.1MB

#### 3. 移除未使用的 UI 库

```bash
# 移除 framer-motion, @headlessui/react, swiper
pnpm remove framer-motion @headlessui/react swiper
```

**优化效果：** 减少 7.5MB

### 中优先级优化（预计减少 20-30MB）

#### 4. 优化图标库使用

**当前问题：** 虽然只使用 lucide-react，但导入了整个库（28MB）

**解决方案：**

- 使用`lucide-react/icons`按需导入
- 或使用 SVG sprite 方案
- 考虑自定义 SVG 图标组件

**实现方式：**

```typescript
// 替换当前导入方式
import { Heart } from 'lucide-react';
// 改为按需导入
import Heart from 'lucide-react/icons/heart';
```

#### 5. 优化 hls.js 使用

**当前问题：** hls.js 体积较大（24MB），可能存在未使用的功能

**解决方案：**

- 检查是否可以使用 hls.js 的 light 版本
- 考虑动态导入，减少初始包大小
- 评估是否可以使用浏览器原生支持替代

#### 6. 移除其他未使用依赖

```bash
pnpm remove media-icons clsx tailwind-merge
```

**优化效果：** 减少 1-2MB

### 低优先级优化（长期维护）

#### 7. 依赖版本优化

- 检查是否存在更轻量的替代品
- 评估@dnd-kit 是否可以简化为原生拖拽实现
- 考虑 sweetalert2 是否可以用更轻量的 toast 库替代

#### 8. 构建优化

- 启用 Next.js 的代码分割
- 优化 bundle 分析
- 考虑使用微前端架构分离功能模块

## 实施计划

### 第一阶段：快速优化（减少 120MB+）

1. 移除所有未使用的依赖包
2. 清理 package.json 中的冗余依赖
3. 重新构建并测试功能完整性

### 第二阶段：按需优化（减少 20-30MB）

1. 实施图标库按需导入
2. 优化 hls.js 的使用方式
3. 检查其他可以按需加载的依赖

### 第三阶段：架构优化（长期）

1. 评估更轻量的替代方案
2. 实施代码分割和懒加载
3. 考虑微前端架构

## 风险评估

### 低风险操作

- 移除未使用的依赖包
- 图标库按需导入优化

### 中等风险操作

- hls.js 优化（需要充分测试播放功能）
- UI 库替换（需要重新实现部分功能）

### 高风险操作

- 架构级重构
- 核心播放器更换

## 预期效果

实施上述优化后，预期效果：

- **node_modules 体积：** 从 922MB 减少到 700-750MB
- **Docker 镜像大小：** 从 1.53GB 减少到 1.2-1.3GB
- **构建时间：** 减少 20-30%
- **部署包大小：** 显著减小

## 后续监控建议

1. 定期进行依赖审计
2. 使用`bundle-analyzer`监控包大小变化
3. 建立依赖使用的代码规范
4. 在 CI/CD 流程中添加依赖检查
