# MoonTV 部署配置

**记忆类型**: 部署配置  
**创建时间**: 2025-12-12  
**最后更新**: 2025-12-12  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 技术架构, 项目概览, 运维指南  
**语义标签**: 环境变量, 部署指南, 平台兼容性, 配置管理  
**索引关键词**: 部署, 环境配置, Docker, Vercel, Cloudflare, 存储配置

## 概述

MoonTV 项目的部署配置指南，包括环境变量设置、各平台部署步骤、存储后端选择和运维配置，确保应用在各种环境下稳定运行。

## 环境变量配置

### 必需环境变量

#### 安全相关 (必须设置)

- `PASSWORD`: **管理员密码** - 生产环境必须设置，建议使用强密码
- `USERNAME`: 管理员用户名 - 非 localstorage 模式必需

#### 存储配置 (根据选择的存储类型设置)

- `NEXT_PUBLIC_STORAGE_TYPE`: 存储类型 (`localstorage`/`redis`/`upstash`/`d1`)
- `REDIS_URL`: Redis 连接 URL (Redis 存储时必需)
- `UPSTASH_URL`: Upstash Redis 连接 URL (Upstash 存储时必需)
- `UPSTASH_TOKEN`: Upstash Redis 连接 Token (Upstash 存储时必需)

### 功能配置

#### 基本配置

- `NEXT_PUBLIC_SITE_NAME`: 站点名称，默认 `MoonTV`
- `NEXT_PUBLIC_ENABLE_REGISTER`: 是否开放用户注册，默认 `false` (生产环境建议关闭)
- `NEXT_PUBLIC_SEARCH_MAX_PAGE`: 搜索最大页数限制，范围 1-50，默认 `3`

#### TVBox 集成

- `TVBOX_ENABLED`: TVBox 接口开关，默认 `true`
- `TVBOX_PASSWORD`: TVBox 接口访问密码 (可选，建议设置)

#### 豆瓣数据集成

- `NEXT_PUBLIC_DOUBAN_PROXY_TYPE`: 豆瓣数据源请求方式 (`none`/`custom`)
- `NEXT_PUBLIC_DOUBAN_PROXY`: 自定义豆瓣数据代理 URL
- `NEXT_PUBLIC_DOUBAN_IMAGE_PROXY_TYPE`: 豆瓣图片代理类型 (`none`/`custom`/`proxy`/`imgproxy`)
- `NEXT_PUBLIC_DOUBAN_IMAGE_PROXY`: 自定义豆瓣图片代理 URL

#### 弹幕功能

- `NEXT_PUBLIC_DANMU_API_BASE_URL`: 弹幕接口地址 (需自行部署弹幕后端)

### 环境变量示例

#### 本地开发环境

```bash
# .env.local
PASSWORD=your_admin_password
NEXT_PUBLIC_STORAGE_TYPE=localstorage
NEXT_PUBLIC_SITE_NAME=MoonTV Dev
NEXT_PUBLIC_ENABLE_REGISTER=true
TVBOX_ENABLED=true
```

#### 生产环境 (Redis 存储)

```bash
# .env.production
PASSWORD=strong_password_123!
USERNAME=admin
NEXT_PUBLIC_STORAGE_TYPE=redis
REDIS_URL=redis://localhost:6379
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_ENABLE_REGISTER=false
TVBOX_ENABLED=true
TVBOX_PASSWORD=tvbox_access_password
```

#### 生产环境 (Upstash 存储)

```bash
# .env.production
PASSWORD=strong_password_123!
USERNAME=admin
NEXT_PUBLIC_STORAGE_TYPE=upstash
UPSTASH_URL=https://your-upstash-url.upstash.io
UPSTASH_TOKEN=your_upstash_token
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_ENABLE_REGISTER=false
```

## 存储后端选择指南

### LocalStorage 后端

#### 适用场景

- 单用户、单设备使用
- 本地开发和测试
- 无需多端数据同步的场景

#### 配置要求

```bash
NEXT_PUBLIC_STORAGE_TYPE=localstorage
```

#### 优缺点

- ✅ 优点: 零配置，无需额外服务
- ❌ 缺点: 数据仅限当前浏览器，无法多端同步
- ⚠️ 限制: 不适合多用户生产环境

### Redis 后端

#### 适用场景

- 自托管多用户场景
- 需要高性能缓存的场景
- 需要数据持久化和备份

#### 配置要求

```bash
NEXT_PUBLIC_STORAGE_TYPE=redis
REDIS_URL=redis://username:password@host:port/database
```

#### Redis 安装和配置

```bash
# Docker安装Redis
docker run -d --name moontv-redis \
  -p 6379:6379 \
  -v redis_data:/data \
  redis:7-alpine redis-server --appendonly yes

# 或者使用系统包管理器
# Ubuntu/Debian
sudo apt update
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

#### 优缺点

- ✅ 优点: 高性能，支持多用户，数据持久化
- ❌ 缺点: 需要维护 Redis 实例
- 🔧 建议: 生产环境推荐使用

### Upstash Redis 后端

#### 适用场景

- 云部署，不想维护 Redis 实例
- 需要弹性扩展的场景
- Serverless 架构部署

#### 配置要求

```bash
NEXT_PUBLIC_STORAGE_TYPE=upstash
UPSTASH_URL=https://your-upstash-url.upstash.io
UPSTASH_TOKEN=your_upstash_token
```

#### Upstash 设置步骤

1. 注册 Upstash 账户 (https://upstash.com)
2. 创建 Redis 数据库
3. 获取连接 URL 和 Token
4. 配置环境变量

#### 优缺点

- ✅ 优点: 无需运维，自动扩展，高可用
- ❌ 缺点: 可能有费用产生 (免费额度通常足够)
- ☁️ 建议: 云部署推荐使用

### Cloudflare D1 后端

#### 适用场景

- Cloudflare Pages 部署
- 需要 SQLite 兼容性的场景
- Serverless SQL 数据库需求

#### 配置要求

```bash
NEXT_PUBLIC_STORAGE_TYPE=d1
```

#### D1 数据库设置

1. 在 Cloudflare Dashboard 创建 D1 数据库
2. 运行数据库初始化脚本
3. 绑定数据库到 Pages 项目

#### 优缺点

- ✅ 优点: 无缝 Cloudflare 集成，Serverless SQL
- ❌ 缺点: 仅限 Cloudflare 生态
- 🌐 建议: Cloudflare Pages 部署时使用

## 平台部署指南

### Vercel 部署

#### 部署步骤

1. **导入项目**

   - 登录 Vercel (https://vercel.com)
   - 点击 "New Project"
   - 导入 GitHub 仓库 `stardm0/MoonTV`

2. **配置项目**

   - 框架预设: Next.js
   - 根目录: `/` (默认)
   - 构建命令: `pnpm build` (或 `npm run build`)
   - 输出目录: `.next` (默认)

3. **环境变量配置**

   - 在项目设置中添加所有必需环境变量
   - 特别注意设置 `PASSWORD` 变量

4. **部署**
   - 点击 "Deploy"
   - 等待构建完成
   - 访问生成的 URL

#### Vercel 特定配置

```bash
# vercel.json 配置
{
  "buildCommand": "pnpm build",
  "devCommand": "pnpm dev",
  "installCommand": "pnpm install",
  "framework": "nextjs",
  "regions": ["hkg1"]  # 可选：选择区域
}
```

#### 优点

- ✅ 自动 HTTPS 和 CDN
- ✅ 自动预览部署
- ✅ 友好的开发者体验
- ✅ 与 Next.js 深度集成

### Docker 部署

#### Dockerfile 说明

项目提供优化的 Dockerfile，构建上下文已优化至 874KB。

#### 构建和运行

```bash
# 构建镜像
docker build -t moontv:latest .

# 运行容器 (LocalStorage模式)
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e PASSWORD=your_password \
  moontv:latest

# 运行容器 (Redis模式)
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e PASSWORD=your_password \
  -e NEXT_PUBLIC_STORAGE_TYPE=redis \
  -e REDIS_URL=redis://redis:6379 \
  --link redis:redis \
  moontv:latest

# 使用 Docker Compose
docker-compose up -d
```

#### Docker Compose 示例

```yaml
version: '3.8'

services:
  moontv:
    build: .
    ports:
      - '3000:3000'
    environment:
      - PASSWORD=${PASSWORD:-changeme}
      - NEXT_PUBLIC_STORAGE_TYPE=redis
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

#### 优化建议

- 使用多阶段构建减少镜像大小
- 设置合适的资源限制
- 配置健康检查
- 使用 .dockerignore 排除不必要的文件

### Cloudflare Pages 部署

#### 部署步骤

1. **准备项目**

   ```bash
   # 本地构建测试
   pnpm pages:build
   ```

2. **部署到 Cloudflare Pages**

   - 登录 Cloudflare Dashboard
   - 进入 Pages 页面
   - 创建新项目，连接 GitHub 仓库
   - 构建设置:
     - 框架预设: Next.js
     - 构建命令: `pnpm pages:build`
     - 构建输出目录: `.vercel/output/static`

3. **环境变量配置**

   - 在 Pages 设置中添加环境变量
   - 对于 D1 数据库，需要绑定数据库

4. **兼容性标志**
   - 设置 Node.js 兼容性标志
   - 启用必要的 Workers 功能

#### 注意事项

- 需要配置兼容性标志
- D1 数据库需要额外绑定
- 部分 Next.js 功能可能需要适配

### Netlify 部署

#### 部署步骤

1. **导入项目到 Netlify**

   - 登录 Netlify (https://netlify.com)
   - 点击 "New site from Git"
   - 选择 GitHub 仓库

2. **构建设置**

   - 构建命令: `pnpm build`
   - 发布目录: `out` (需要调整 Next.js 配置)
   - 环境变量: 在站点设置中添加

3. **Next.js 配置**
   ```javascript
   // next.config.js
   module.exports = {
     output: 'export', // 启用静态导出
     // 其他配置...
   };
   ```

#### 注意事项

- 可能需要启用静态导出
- 部分动态功能需要 Netlify Functions
- 环境变量配置方式略有不同

### 自托管部署

#### 系统要求

- **Node.js**: 20.x 或更高
- **内存**: 至少 512MB RAM
- **存储**: 至少 1GB 可用空间
- **网络**: 开放 3000 端口 (或配置反向代理)

#### 部署步骤

```bash
# 1. 克隆代码
git clone https://github.com/stardm0/MoonTV.git
cd MoonTV

# 2. 安装依赖
pnpm install

# 3. 配置环境变量
cp .env.example .env.production
vim .env.production  # 编辑配置

# 4. 构建项目
pnpm build

# 5. 使用进程管理器运行 (推荐使用PM2)
npm install -g pm2
pm2 start pnpm --name "moontv" -- start
pm2 save
pm2 startup

# 6. 配置反向代理 (Nginx示例)
sudo vim /etc/nginx/sites-available/moontv
```

#### Nginx 配置示例

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL证书
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 反向代理
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 平台兼容性矩阵

### 部署平台特性支持

| 平台           | Next.js 支持 | 存储后端   | PWA 支持 | TVBox 支持 | 自动部署 |
| -------------- | ------------ | ---------- | -------- | ---------- | -------- |
| **Vercel**     | ✅ 完整支持  | 所有类型   | ✅ 完整  | ✅ 完整    | ✅ 自动  |
| **Docker**     | ✅ 完整支持  | 所有类型   | ✅ 完整  | ✅ 完整    | 🔧 手动  |
| **Cloudflare** | ⚠️ 部分支持  | D1/Upstash | ✅ 完整  | ✅ 完整    | ✅ 自动  |
| **Netlify**    | ⚠️ 静态导出  | 所有类型   | ✅ 完整  | ✅ 完整    | ✅ 自动  |
| **自托管**     | ✅ 完整支持  | 所有类型   | ✅ 完整  | ✅ 完整    | 🔧 手动  |

### 存储后端平台兼容性

| 存储类型         | Vercel | Docker | Cloudflare | Netlify | 自托管 |
| ---------------- | ------ | ------ | ---------- | ------- | ------ |
| **LocalStorage** | ✅     | ✅     | ✅         | ✅      | ✅     |
| **Redis**        | ✅     | ✅     | ⚠️\*       | ✅      | ✅     |
| **Upstash**      | ✅     | ✅     | ✅         | ✅      | ✅     |
| **D1**           | ⚠️\*\* | ❌     | ✅         | ❌      | ❌     |

_注: Cloudflare 需要外部 Redis (如 Upstash)_  
\*_注: Vercel 需要额外配置_

## 安全部署指南

### 必须的安全配置

#### 1. 密码设置

- **必须设置** `PASSWORD` 环境变量
- 使用强密码: 至少 12 位，包含大小写字母、数字、特殊字符
- 定期更换密码
- 不同环境使用不同密码

#### 2. 用户注册控制

- 生产环境设置 `NEXT_PUBLIC_ENABLE_REGISTER=false`
- 如果需要开放注册，限制为内部用户
- 实现邀请码机制或审批流程

#### 3. 访问控制

- 限制管理界面访问 IP
- 设置 TVBox 接口密码 (`TVBOX_PASSWORD`)
- 配置适当的 CORS 策略
- 实现 API 速率限制

#### 4. 网络安全

- 强制使用 HTTPS
- 配置安全 HTTP 头部
- 启用 HSTS
- 定期更新 SSL 证书

### 生产环境检查清单

#### 部署前检查

- [ ] 所有环境变量正确配置
- [ ] 存储后端连接正常
- [ ] SSL 证书有效
- [ ] 域名解析正确
- [ ] 备份机制就绪

#### 安全检查

- [ ] 管理员密码已设置且足够强壮
- [ ] 用户注册功能已按需配置
- [ ] 安全 HTTP 头部已配置
- [ ] 访问日志已启用
- [ ] 错误信息不泄露敏感数据

#### 性能检查

- [ ] CDN 配置正确
- [ ] 缓存策略优化
- [ ] 图片和资源已优化
- [ ] 数据库索引合理

## 监控和维护

### 监控配置

#### 应用监控

- **性能监控**: 响应时间，错误率，吞吐量
- **业务监控**: 用户数，播放数，搜索数
- **资源监控**: CPU，内存，磁盘，网络

#### 日志配置

```bash
# 启用详细日志
NEXT_PUBLIC_LOG_LEVEL=debug

# 结构化日志输出
LOGGING_FORMAT=json
```

#### 健康检查端点

- `GET /api/health` - 应用健康状态
- `GET /api/health/db` - 数据库连接状态
- `GET /api/health/redis` - Redis 连接状态

### 维护任务

#### 日常维护

- 监控日志和错误报告
- 检查存储空间使用情况
- 验证备份完整性
- 更新依赖包 (安全更新)

#### 定期维护

- 清理过期缓存数据
- 优化数据库性能
- 更新 SSL 证书
- 审查安全配置

#### 故障处理

- 建立回滚计划
- 准备应急响应流程
- 文档化常见问题解决方案
- 定期进行恢复演练

## 故障排除指南

### 常见部署问题

#### 构建失败

```bash
# 清理构建缓存
rm -rf .next
rm -rf node_modules

# 重新安装依赖
pnpm install --force

# 重新构建
pnpm build
```

#### 启动失败

1. 检查端口是否被占用
2. 验证环境变量配置
3. 检查存储后端连接
4. 查看应用日志

#### 存储连接问题

- Redis: 检查网络连接和认证
- Upstash: 验证 URL 和 Token
- D1: 检查数据库绑定和权限

### 性能问题

#### 响应缓慢

1. 检查存储后端性能
2. 优化数据库查询
3. 启用 CDN 缓存
4. 调整缓存策略

#### 内存泄漏

1. 监控内存使用情况
2. 分析堆内存快照
3. 检查未释放的资源
4. 调整 Node.js 内存限制

### 安全事件响应

#### 疑似攻击

1. 立即启用详细日志
2. 检查异常访问模式
3. 临时限制可疑 IP
4. 审查最近更改

#### 数据泄露

1. 立即重置所有密码
2. 审查访问日志
3. 评估影响范围
4. 通知相关用户

## 更新和升级

### 版本升级步骤

1. **备份当前版本**

   ```bash
   # 备份数据
   docker exec moontv-redis redis-cli SAVE
   cp -r redis_data redis_data_backup_$(date +%Y%m%d)

   # 备份配置文件
   cp .env .env.backup.$(date +%Y%m%d)
   ```

2. **测试环境验证**

   ```bash
   # 在测试环境部署新版本
   git checkout v3.6.2
   pnpm install
   pnpm build
   pnpm test
   ```

3. **生产环境部署**

   ```bash
   # 逐步部署，监控指标
   docker-compose pull
   docker-compose up -d --scale moontv=2
   # 验证新版本运行正常后，停止旧版本
   ```

4. **回滚计划**
   ```bash
   # 如果需要回滚
   git checkout previous_version
   docker-compose up -d
   ```

### 破坏性变更处理

#### 数据库迁移

```sql
-- 执行迁移脚本前备份
-- 提供回滚脚本
-- 在低流量时段执行
```

#### API 变更

- 保持向后兼容性
- 提供迁移指南
- 设置弃用期
- 更新 API 文档

## 最佳实践

### 部署最佳实践

1. **环境分离**: 严格区分开发、测试、生产环境
2. **配置外部化**: 所有配置通过环境变量管理
3. **基础设施即代码**: 使用 Docker Compose 或 Terraform
4. **自动化部署**: 实现 CI/CD 流水线
5. **监控先行**: 部署前配置好监控和告警

### 安全最佳实践

1. **最小权限原则**: 仅授予必要的权限
2. **深度防御**: 多层安全防护
3. **定期审计**: 定期审查安全配置
4. **及时更新**: 及时应用安全补丁
5. **员工培训**: 提高团队成员安全意识

### 性能最佳实践

1. **缓存策略**: 合理使用多级缓存
2. **CDN 加速**: 静态资源使用 CDN
3. **数据库优化**: 索引优化和查询优化
4. **代码优化**: 避免性能瓶颈
5. **容量规划**: 根据负载规划资源

## 相关资源

- **项目仓库**: https://github.com/stardm0/MoonTV
- **Docker Hub**: https://hub.docker.com/r/stardm0/moontv
- **Vercel 文档**: https://vercel.com/docs
- **Cloudflare 文档**: https://developers.cloudflare.com/pages
- **Redis 文档**: https://redis.io/documentation
- **Upstash 文档**: https://upstash.com/docs

## 更新历史

- 2025-12-12: 创建部署配置记忆文件，基于项目记忆管理器新规则重构
- 2025-12-09: 更新 Docker 构建优化，构建上下文从 1.5GB 减少到 874KB
- 2025-11-25: 修复 Docker 环境变量读取问题
- 2025-10-20: 完善多平台部署指南
- 2025-10-01: 建立基础部署配置框架
