# 🔒 MoonTV 安全配置指南

## 快速启动

### 1. 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env.local

# 编辑配置文件
nano .env.local  # 或使用其他编辑器
```

### 2. 必须修改的配置

#### 🔑 PASSWORD (必须设置)
```bash
# 默认值 (必须修改!)
PASSWORD=your_secure_password_here

# 推荐格式 (至少12位，包含字母、数字、特殊字符)
PASSWORD=MoonTV2025!@#$
```

#### 👤 USERNAME (推荐设置)
```bash
# 管理员用户名
USERNAME=admin
```

### 3. 重启应用
```bash
# 开发环境
pnpm dev

# 生产环境
pnpm build && pnpm start
```

## 存储模式配置

### LocalStorage 模式 (默认)
```bash
NEXT_PUBLIC_STORAGE_TYPE=localstorage
PASSWORD=your_password  # 必须设置
```
- ✅ 简单快速
- ✅ 无需数据库
- ⚠️ 数据存储在浏览器本地

### Redis 模式
```bash
NEXT_PUBLIC_STORAGE_TYPE=redis
PASSWORD=your_password
USERNAME=admin
REDIS_URL=redis://localhost:6379
```
- ✅ 多用户支持
- ✅ 数据持久化
- ✅ 高性能

### Upstash 模式 (云端 Redis)
```bash
NEXT_PUBLIC_STORAGE_TYPE=upstash
PASSWORD=your_password
USERNAME=admin
UPSTASH_URL=your_upstash_url
UPSTASH_TOKEN=your_upstash_token
```
- ✅ 无需自建 Redis
- ✅ 全球分布式
- ✅ 零运维

## 安全最佳实践

### 1. 密码安全
- ✅ 使用强密码 (12+ 字符)
- ✅ 包含大小写字母、数字、特殊字符
- ✅ 定期更换密码
- ❌ 不要使用默认密码
- ❌ 不要在代码中硬编码密码

### 2. 访问控制
```bash
# 禁用注册 (推荐)
NEXT_PUBLIC_ENABLE_REGISTER=false

# 启用注册 (谨慎使用)
NEXT_PUBLIC_ENABLE_REGISTER=true
```

### 3. 环境变量安全
- ✅ `.env.local` 已在 `.gitignore` 中
- ✅ 不要提交环境变量到代码库
- ✅ 生产环境使用环境变量注入

### 4. 部署安全
```bash
# 生产环境
NODE_ENV=production

# HTTPS 推荐
# 使用反向代理 (Nginx/Caddy)
# 配置 SSL 证书
```

## 故障排除

### 问题：无法登录
1. 检查 PASSWORD 环境变量是否设置
2. 确认 `.env.local` 文件格式正确
3. 重启应用使配置生效

### 问题：重定向到警告页面
```bash
# 原因：未配置 PASSWORD
# 解决：设置 PASSWORD 环境变量
PASSWORD=your_secure_password
```

### 问题：数据库连接失败
```bash
# 检查 Redis/Upstash 配置
REDIS_URL=redis://localhost:6379
# 或
UPSTASH_URL=your_url
UPSTASH_TOKEN=your_token
```

## 环境变量说明

| 变量名 | 必须 | 说明 | 示例 |
|--------|------|------|------|
| `PASSWORD` | ✅ | 管理员密码 | `MoonTV2025!` |
| `USERNAME` | ⚠️ | 管理员用户名 | `admin` |
| `NEXT_PUBLIC_STORAGE_TYPE` | ⚠️ | 存储类型 | `localstorage` |
| `REDIS_URL` | ❌ | Redis 连接 | `redis://localhost:6379` |
| `UPSTASH_URL` | ❌ | Upstash 地址 | `https://xxx.upstash.io` |
| `UPSTASH_TOKEN` | ❌ | Upstash 令牌 | `AXXXxxxx` |

**图例：**
- ✅ 必须设置
- ⚠️ 推荐设置  
- ❌ 可选设置

## 更新日志

- **2025-08-28**: 创建安全配置指南
- **2025-08-28**: 添加环境变量模板和说明