# MoonTV 运维指南

**记忆类型**: 运维指南  
**创建时间**: 2025-12-12  
**最后更新**: 2025-12-12  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 部署配置, 技术架构, 项目概览  
**语义标签**: 运维管理, 监控告警, 故障排除, 安全维护, 性能优化  
**索引关键词**: 运维, 监控, 故障处理, 安全, 备份, 性能调优, 日志分析

## 概述

MoonTV 项目的运维管理指南，包括系统监控、故障排除、安全维护、性能优化、备份恢复等运维相关的最佳实践和操作流程，确保系统稳定、安全、高效运行。

## 运维体系架构

### 运维层级结构

```
┌─────────────────────────────────────────────────────┐
│                   监控告警层                        │
│       系统监控 │ 业务监控 │ 安全监控 │ 日志监控     │
├─────────────────────────────────────────────────────┤
│                   运维操作层                        │
│       日常维护 │ 故障处理 │ 性能优化 │ 安全运维     │
├─────────────────────────────────────────────────────┤
│                   基础设施层                        │
│       计算资源 │ 存储资源 │ 网络资源 │ 安全资源     │
└─────────────────────────────────────────────────────┘
```

### 运维职责划分

#### 1. 系统运维

- 服务器和资源管理
- 系统监控和性能调优
- 备份和恢复管理
- 容量规划和扩展

#### 2. 应用运维

- 应用部署和发布
- 应用监控和日志管理
- 故障诊断和处理
- 配置管理和变更控制

#### 3. 安全运维

- 安全监控和漏洞管理
- 访问控制和权限管理
- 安全事件响应
- 合规性检查

#### 4. 数据运维

- 数据备份和恢复
- 数据库性能优化
- 数据迁移和同步
- 数据安全和隐私保护

## 监控系统配置

### 监控指标分类

#### 系统层监控

```yaml
# 系统资源监控
cpu_usage:
  threshold: 80%
  alert_level: warning
  collection_interval: 60s

memory_usage:
  threshold: 85%
  alert_level: warning
  collection_interval: 60s

disk_usage:
  threshold: 90%
  alert_level: critical
  collection_interval: 300s

network_io:
  threshold: 100MB/s
  alert_level: warning
  collection_interval: 30s
```

#### 应用层监控

```yaml
# 应用性能监控
response_time:
  p95_threshold: 1000ms
  alert_level: warning
  collection_interval: 30s

error_rate:
  threshold: 1%
  alert_level: critical
  collection_interval: 60s

throughput:
  threshold: 1000rps
  alert_level: warning
  collection_interval: 30s

availability:
  threshold: 99.9%
  alert_level: critical
  collection_interval: 300s
```

#### 业务层监控

```yaml
# 业务指标监控
active_users:
  threshold: 1000
  alert_level: info
  collection_interval: 300s

search_requests:
  threshold: 100/min
  alert_level: warning
  collection_interval: 60s

play_requests:
  threshold: 500/min
  alert_level: warning
  collection_interval: 60s

concurrent_connections:
  threshold: 1000
  alert_level: critical
  collection_interval: 30s
```

### 监控工具配置

#### 使用 Prometheus + Grafana

```yaml
# prometheus.yml 配置示例
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'moontv-app'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/api/metrics'

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:6379']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
```

#### 监控面板配置

```javascript
// Grafana 面板配置
const dashboard = {
  title: 'MoonTV 监控面板',
  panels: [
    {
      title: 'CPU 使用率',
      type: 'graph',
      targets: [
        {
          expr: '100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)',
        },
      ],
      thresholds: [80, 90],
    },
    {
      title: '内存使用率',
      type: 'graph',
      targets: [
        {
          expr: '(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100',
        },
      ],
      thresholds: [85, 95],
    },
    {
      title: '应用响应时间',
      type: 'graph',
      targets: [
        {
          expr: 'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))',
        },
      ],
      unit: 's',
    },
  ],
};
```

### 日志监控配置

#### 日志级别配置

```typescript
// 日志级别配置
const logLevels = {
  development: 'debug',
  test: 'info',
  production: 'warn',
};

// 结构化日志输出
const loggerConfig = {
  level: logLevels[process.env.NODE_ENV] || 'info',
  format: process.env.NODE_ENV === 'production' ? 'json' : 'pretty',
  transports: [
    new transports.Console(),
    new transports.File({ filename: 'logs/error.log', level: 'error' }),
    new transports.File({ filename: 'logs/combined.log' }),
  ],
};
```

#### 日志收集和分析

```bash
# 使用 ELK 栈进行日志收集
# Filebeat 配置
filebeat.inputs:
- type: log
  paths:
    - /var/log/moontv/*.log
  json.keys_under_root: true
  json.add_error_key: true

output.elasticsearch:
  hosts: ["localhost:9200"]
  index: "moontv-logs-%{+yyyy.MM.dd}"
```

## 日常维护操作

### 每日检查清单

#### 系统健康检查

```bash
# 1. 系统资源检查
top -bn1 | head -20
free -h
df -h

# 2. 服务状态检查
systemctl status moontv
systemctl status redis
systemctl status nginx

# 3. 应用健康检查
curl -f http://localhost:3000/api/health
curl -f http://localhost:3000/api/health/db
curl -f http://localhost:3000/api/health/redis

# 4. 日志检查
tail -100 /var/log/moontv/error.log
tail -100 /var/log/moontv/access.log
```

#### 业务指标检查

```bash
# 1. 用户活跃度检查
redis-cli GET stats:daily_active_users

# 2. 搜索量检查
redis-cli GET stats:daily_search_count

# 3. 播放量检查
redis-cli GET stats:daily_play_count

# 4. 错误率检查
grep -c "ERROR" /var/log/moontv/error.log
```

### 每周维护任务

#### 系统维护

```bash
# 1. 系统更新
sudo apt update
sudo apt upgrade -y

# 2. 安全补丁
sudo unattended-upgrade --dry-run

# 3. 日志轮转和清理
logrotate -f /etc/logrotate.d/moontv
find /var/log/moontv -name "*.log.*" -mtime +30 -delete

# 4. 备份验证
./scripts/verify-backup.sh
```

#### 应用维护

```bash
# 1. 依赖包更新检查
npm outdated
pnpm outdated

# 2. 数据库优化
redis-cli --stat
redis-cli INFO memory

# 3. 缓存清理
redis-cli FLUSHDB  # 谨慎使用

# 4. 性能分析
node --prof app.js
node --prof-process isolate-0x*.log > processed.txt
```

### 每月维护任务

#### 深度检查和优化

```bash
# 1. 安全审计
npm audit
snyk test

# 2. 性能基准测试
ab -n 1000 -c 100 http://localhost:3000/
siege -c 100 -t 60S http://localhost:3000/

# 3. 容量规划分析
./scripts/analyze-capacity.sh

# 4. 备份策略审查
./scripts/review-backup-policy.sh
```

#### 数据维护

```bash
# 1. 数据库优化
redis-cli BGREWRITEAOF
redis-cli BGSAVE

# 2. 数据归档
./scripts/archive-old-data.sh

# 3. 统计报告生成
./scripts/generate-monthly-report.sh

# 4. 用户数据清理
./scripts/cleanup-inactive-users.sh
```

## 故障排除指南

### 常见故障分类

#### 1. 系统级故障

- 服务器宕机或重启
- 磁盘空间不足
- 内存泄漏或溢出
- 网络连接问题

#### 2. 应用级故障

- 应用崩溃或无法启动
- 服务响应缓慢
- 功能异常或错误
- 数据不一致问题

#### 3. 数据级故障

- 数据库连接失败
- 数据丢失或损坏
- 缓存失效或过期
- 数据同步问题

#### 4. 安全级故障

- 未授权访问
- 数据泄露风险
- 恶意攻击
- 配置错误导致的安全漏洞

### 故障诊断流程

#### 第一步：问题识别

```bash
# 快速检查命令
./scripts/quick-check.sh

# 输出包含：
# 1. 系统状态
# 2. 服务状态
# 3. 网络状态
# 4. 磁盘状态
# 5. 内存状态
```

#### 第二步：日志分析

```bash
# 查看应用日志
tail -200 /var/log/moontv/error.log
tail -200 /var/log/moontv/access.log

# 查看系统日志
journalctl -u moontv --since "10 minutes ago"
journalctl -u redis --since "10 minutes ago"

# 查看网络日志
tail -100 /var/log/nginx/error.log
tail -100 /var/log/nginx/access.log
```

#### 第三步：性能分析

```bash
# CPU 使用分析
top -p $(pgrep -f "node.*moontv")
htop

# 内存使用分析
pmap -x $(pgrep -f "node.*moontv")
cat /proc/$(pgrep -f "node.*moontv")/status | grep -E "Vm|Rss"

# 网络连接分析
netstat -anp | grep :3000
ss -tulpn | grep :3000

# 磁盘IO分析
iotop -p $(pgrep -f "node.*moontv")
iostat -x 1
```

#### 第四步：根本原因分析

```bash
# 错误追踪
node --inspect app.js  # 启用调试模式

# 内存分析
node --inspect --inspect-brk app.js
# 使用 Chrome DevTools 进行内存分析

# 性能剖析
node --prof app.js
node --prof-process isolate-0x*.log > processed.txt
```

### 常见故障解决方案

#### 故障 1：应用无法启动

##### 症状

- 应用进程不存在
- 端口未被占用
- 启动脚本执行失败

##### 诊断步骤

```bash
# 1. 检查启动命令
which node
node --version
pnpm --version

# 2. 检查依赖
pnpm install --frozen-lockfile
pnpm typecheck

# 3. 检查环境变量
env | grep -E "NEXT_|REDIS|UPSTASH"

# 4. 检查端口占用
netstat -tulpn | grep :3000
lsof -i :3000
```

##### 解决方案

```bash
# 1. 修复依赖问题
rm -rf node_modules
rm -f pnpm-lock.yaml
pnpm install

# 2. 修复配置问题
cp .env.example .env.local
# 编辑 .env.local 文件

# 3. 修复端口冲突
# 修改端口号或停止占用进程
export PORT=3001
# 或
kill -9 $(lsof -ti:3000)

# 4. 重新启动
pnpm build
pnpm start
```

#### 故障 2：应用响应缓慢

##### 症状

- 页面加载时间长
- API 响应延迟
- 用户操作卡顿

##### 诊断步骤

```bash
# 1. 系统资源检查
top -bn1 | head -20
free -h
df -h

# 2. 网络延迟检查
ping -c 10 localhost
curl -o /dev/null -s -w "%{time_total}\n" http://localhost:3000/

# 3. 数据库性能检查
redis-cli INFO stats
redis-cli SLOWLOG GET 10

# 4. 应用性能分析
curl http://localhost:3000/api/debug/profile
```

##### 解决方案

```bash
# 1. 优化数据库查询
# 分析慢查询日志
redis-cli SLOWLOG GET 10

# 2. 增加缓存策略
# 调整缓存时间和策略
export REDIS_CACHE_TTL=3600

# 3. 优化前端资源
# 启用压缩和CDN
export NEXT_COMPRESSION=true

# 4. 水平扩展
# 增加应用实例
docker-compose scale moontv=3
```

#### 故障 3：数据不一致

##### 症状

- 用户数据丢失
- 播放记录不同步
- 收藏内容不一致

##### 诊断步骤

```bash
# 1. 检查存储后端连接
redis-cli PING
curl -f http://localhost:3000/api/health/db

# 2. 检查数据同步状态
redis-cli INFO replication
redis-cli INFO persistence

# 3. 检查应用日志中的数据操作错误
grep -E "data.*error|sync.*failed" /var/log/moontv/error.log

# 4. 数据完整性检查
./scripts/check-data-integrity.sh
```

##### 解决方案

```bash
# 1. 修复数据同步
# 触发数据同步
curl -X POST http://localhost:3000/api/admin/sync/data

# 2. 恢复备份数据
./scripts/restore-backup.sh latest

# 3. 修复损坏的数据
./scripts/repair-corrupted-data.sh

# 4. 重建索引和缓存
redis-cli FLUSHDB
# 注意：此操作会清空所有数据
```

#### 故障 4：安全事件响应

##### 症状

- 异常访问日志
- 未授权访问尝试
- 数据泄露迹象
- 系统资源异常消耗

##### 诊断步骤

```bash
# 1. 分析访问日志
grep -E "401|403|404" /var/log/moontv/access.log | head -50
grep "failed.*login" /var/log/moontv/access.log

# 2. 检查系统日志中的安全事件
journalctl -u moontv --since "1 hour ago" | grep -i "security|auth|fail"

# 3. 网络连接分析
netstat -anp | grep ESTABLISHED
ss -tulpn | grep -E ":3000|:6379"

# 4. 资源使用异常检查
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

##### 解决方案

```bash
# 1. 立即响应措施
# 临时封禁可疑IP
iptables -A INPUT -s 1.2.3.4 -j DROP

# 2. 增强安全配置
# 更新防火墙规则
ufw enable
ufw allow 22/tcp
ufw allow 3000/tcp

# 3. 重置受影响凭证
# 重置管理员密码
export PASSWORD=new_strong_password_123!

# 4. 启用额外监控
# 启用详细的安全日志
export SECURITY_LOG_LEVEL=debug
```

### 故障恢复流程

#### 标准恢复流程

```bash
# 恢复流程脚本
#!/bin/bash
# restore-procedure.sh

set -e

echo "开始故障恢复流程..."

# 1. 确认故障影响范围
echo "=== 步骤1: 评估故障影响 ==="
./scripts/assess-impact.sh

# 2. 执行紧急处理措施
echo "=== 步骤2: 执行紧急处理 ==="
./scripts/emergency-response.sh

# 3. 恢复服务和数据
echo "=== 步骤3: 恢复服务 ==="
./scripts/restore-service.sh

# 4. 验证恢复效果
echo "=== 步骤4: 验证恢复 ==="
./scripts/verify-recovery.sh

# 5. 记录故障和恢复过程
echo "=== 步骤5: 记录过程 ==="
./scripts/document-incident.sh

echo "故障恢复流程完成"
```

#### 灾难恢复计划

```yaml
# disaster-recovery-plan.yaml
recovery_objectives:
  rto: 4小时 # 恢复时间目标
  rpo: 1小时 # 恢复点目标

recovery_procedures:
  - phase: 立即响应
    actions:
      - 确认灾难范围
      - 启动应急团队
      - 通知相关人员

  - phase: 系统恢复
    actions:
      - 启动备用环境
      - 恢复最新备份
      - 验证系统功能

  - phase: 业务恢复
    actions:
      - 切换流量到恢复环境
      - 监控系统稳定性
      - 逐步恢复业务功能

  - phase: 事后处理
    actions:
      - 分析灾难原因
      - 改进预防措施
      - 更新恢复计划
```

## 安全运维指南

### 安全基线配置

#### 系统安全配置

```bash
# 1. 防火墙配置
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 3000/tcp # 应用端口
sudo ufw allow 80/tcp   # HTTP (如果使用Nginx)
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable

# 2. SSH安全配置
sudo vim /etc/ssh/sshd_config
# 修改以下配置：
# Port 2222                    # 修改默认端口
# PermitRootLogin no           # 禁止root登录
# PasswordAuthentication no    # 使用密钥认证
# MaxAuthTries 3              # 最大尝试次数
sudo systemctl restart sshd

# 3. 系统更新配置
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

#### 应用安全配置

```bash
# 1. 环境变量安全配置
# 生产环境必须设置的变量
export PASSWORD=strong_password_123!
export JWT_SECRET=random_jwt_secret_key
export ENCRYPTION_KEY=encryption_key_for_sensitive_data

# 2. 禁用不必要功能
export NEXT_PUBLIC_ENABLE_REGISTER=false
export DEBUG=false
export NODE_ENV=production

# 3. 安全头部配置
# next.config.js 中的安全配置
headers: [
  {
    source: '/(.*)',
    headers: [
      { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'X-XSS-Protection', value: '1; mode=block' },
      { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' }
    ]
  }
]
```

### 安全监控和告警

#### 安全事件监控

```yaml
# 安全监控规则配置
security_monitoring:
  # 认证失败监控
  auth_failures:
    threshold: 10
    time_window: 5分钟
    alert_level: warning
    action: 临时封禁IP

  # 异常访问模式
  abnormal_access:
    threshold: 1000请求/分钟
    time_window: 1分钟
    alert_level: critical
    action: 立即调查

  # 数据泄露迹象
  data_leakage:
    patterns:
      - 'password.*exposed'
      - 'token.*leaked'
      - 'credentials.*public'
    alert_level: critical
    action: 立即响应
```

#### 安全日志配置

```typescript
// 安全日志记录配置
const securityLogger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'moontv-security' },
  transports: [
    new transports.File({
      filename: 'logs/security.log',
      level: 'info',
    }),
    new transports.File({
      filename: 'logs/security-error.log',
      level: 'error',
    }),
  ],
});

// 记录安全事件
function logSecurityEvent(event: SecurityEvent) {
  securityLogger.info('安全事件', {
    timestamp: new Date().toISOString(),
    eventType: event.type,
    severity: event.severity,
    sourceIp: event.sourceIp,
    userId: event.userId,
    details: event.details,
  });

  // 触发告警
  if (event.severity === 'critical') {
    sendSecurityAlert(event);
  }
}
```

### 安全审计和合规

#### 定期安全审计

```bash
# 月度安全审计脚本
#!/bin/bash
# security-audit.sh

echo "开始月度安全审计..."

# 1. 漏洞扫描
echo "=== 漏洞扫描 ==="
npm audit
snyk test
trivy image moontv:latest

# 2. 配置审计
echo "=== 配置审计 ==="
./scripts/audit-config.sh
./scripts/check-permissions.sh

# 3. 日志审计
echo "=== 日志审计 ==="
./scripts/audit-logs.sh

# 4. 访问审计
echo "=== 访问审计 ==="
./scripts/audit-access.sh

# 5. 生成审计报告
echo "=== 生成报告 ==="
./scripts/generate-audit-report.sh

echo "安全审计完成"
```

#### 合规性检查

```bash
# GDPR合规性检查
./scripts/check-gdpr-compliance.sh

# 数据保护检查
./scripts/check-data-protection.sh

# 隐私政策检查
./scripts/check-privacy-policy.sh

# 用户数据处理检查
./scripts/check-user-data-handling.sh
```

## 性能优化指南

### 性能监控指标

#### 关键性能指标 (KPI)

```yaml
performance_kpis:
  # 前端性能指标
  frontend:
    first_contentful_paint:
      target: <1.5s
      threshold: 3s

    largest_contentful_paint:
      target: <2.5s
      threshold: 4s

    cumulative_layout_shift:
      target: <0.1
      threshold: 0.25

    first_input_delay:
      target: <100ms
      threshold: 300ms

  # 后端性能指标
  backend:
    api_response_time_p95:
      target: <200ms
      threshold: 500ms

    error_rate:
      target: <0.1%
      threshold: 1%

    throughput:
      target: >1000rps
      threshold: 100rps

    availability:
      target: >99.9%
      threshold: 99%
```

### 性能优化策略

#### 前端优化

```javascript
// Next.js 性能优化配置
// next.config.js
module.exports = {
  // 启用压缩
  compress: true,

  // 图片优化
  images: {
    formats: ['image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },

  // 脚本优化
  experimental: {
    optimizeCss: true,
    scrollRestoration: true,
  },

  // 缓存策略
  headers: async () => [
    {
      source: '/_next/static/:path*',
      headers: [
        { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
      ],
    },
  ],
};
```

#### 后端优化

```typescript
// 数据库优化策略
class DatabaseOptimizer {
  // 查询优化
  async optimizeQueries(): Promise<void> {
    // 1. 添加索引
    await this.addIndexes();

    // 2. 优化查询语句
    await this.optimizeQueryPatterns();

    // 3. 缓存策略优化
    await this.optimizeCacheStrategy();

    // 4. 连接池优化
    await this.optimizeConnectionPool();
  }

  // Redis优化
  async optimizeRedis(): Promise<void> {
    // 内存优化
    await redis.configSet('maxmemory-policy', 'allkeys-lru');

    // 持久化优化
    await redis.configSet('save', '900 1 300 10 60 10000');

    // 连接优化
    await redis.configSet('tcp-keepalive', '300');
  }
}
```

#### 网络优化

```nginx
# Nginx优化配置
# /etc/nginx/nginx.conf
http {
  # 基础优化
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;

  # Gzip压缩
  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types
    application/javascript
    application/json
    application/xml
    text/css
    text/javascript
    text/plain
    text/xml;

  # 缓存优化
  open_file_cache max=1000 inactive=20s;
  open_file_cache_valid 30s;
  open_file_cache_min_uses 2;
  open_file_cache_errors on;

  # 安全头部
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
}
```

### 容量规划和扩展

#### 容量评估指标

```yaml
capacity_metrics:
  # 用户容量
  user_capacity:
    concurrent_users: 1000
    daily_active_users: 10000
    storage_per_user: 10MB

  # 数据容量
  data_capacity:
    video_metadata: 100GB
    user_data: 50GB
    cache_data: 20GB

  # 性能容量
  performance_capacity:
    requests_per_second: 1000
    bandwidth: 100Mbps
    connections: 5000

  # 存储容量
  storage_capacity:
    total_disk: 200GB
    used_disk: 150GB
    free_disk: 50GB
```

#### 扩展策略

```bash
# 水平扩展脚本
#!/bin/bash
# scale-out.sh

set -e

echo "开始水平扩展..."

# 1. 评估当前负载
echo "=== 评估当前负载 ==="
load=$(uptime | awk '{print $10}' | tr -d ',')
echo "当前负载: $load"

# 2. 检查资源使用
echo "=== 检查资源使用 ==="
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%')
memory=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
echo "CPU使用率: ${cpu}%"
echo "内存使用率: ${memory}%"

# 3. 决定扩展策略
if [ $(echo "$load > 5" | bc) -eq 1 ] || [ $cpu -gt 80 ] || [ $memory -gt 80 ]; then
  echo "需要扩展"

  # 4. 执行扩展
  echo "=== 执行扩展 ==="
  docker-compose up -d --scale moontv=3

  # 5. 配置负载均衡
  echo "=== 配置负载均衡 ==="
  ./scripts/configure-load-balancer.sh

else
  echo "当前负载正常，无需扩展"
fi

echo "扩展操作完成"
```

## 备份和恢复策略

### 备份策略配置

#### 数据分类和备份频率

```yaml
backup_strategy:
  # 关键数据 - 频繁备份
  critical_data:
    - user_profiles
    - play_records
    - favorites
    backup_frequency: 每小时
    retention: 30天
    encryption: 启用

  # 重要数据 - 定期备份
  important_data:
    - video_metadata
    - source_configs
    - site_settings
    backup_frequency: 每天
    retention: 90天
    encryption: 启用

  # 一般数据 - 偶尔备份
  general_data:
    - cache_data
    - logs
    - temp_files
    backup_frequency: 每周
    retention: 180天
    encryption: 可选

  # 系统配置 - 变更时备份
  system_config:
    - environment_variables
    - nginx_config
    - docker_config
    backup_frequency: 变更时
    retention: 永久
    encryption: 启用
```

#### 备份脚本示例

```bash
#!/bin/bash
# backup.sh

set -e

# 配置
BACKUP_DIR="/backups/moontv"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

echo "开始备份 $(date)"

# 1. 创建备份目录
mkdir -p "$BACKUP_DIR/$DATE"

# 2. 备份Redis数据
echo "备份Redis数据..."
redis-cli SAVE
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/$DATE/redis_dump.rdb"

# 3. 备份用户数据
echo "备份用户数据..."
./scripts/export-user-data.sh > "$BACKUP_DIR/$DATE/user_data.json"

# 4. 备份配置
echo "备份配置..."
cp .env "$BACKUP_DIR/$DATE/env.backup"
cp config.json "$BACKUP_DIR/$DATE/config.json"

# 5. 备份日志（可选）
echo "备份重要日志..."
tar -czf "$BACKUP_DIR/$DATE/logs.tar.gz" /var/log/moontv/*.log

# 6. 创建备份清单
echo "创建备份清单..."
cat > "$BACKUP_DIR/$DATE/backup_manifest.json" << EOF
{
  "backup_date": "$(date -Iseconds)",
  "backup_type": "full",
  "components": ["redis", "user_data", "config", "logs"],
  "size": "$(du -sh "$BACKUP_DIR/$DATE" | cut -f1)"
}
EOF

# 7. 加密备份（可选）
if [ "$ENABLE_ENCRYPTION" = "true" ]; then
  echo "加密备份..."
  gpg --encrypt --recipient backup@moontv.com "$BACKUP_DIR/$DATE/backup_manifest.json"
fi

# 8. 清理旧备份
echo "清理旧备份..."
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "备份完成 $(date)"
```

### 恢复流程

#### 数据恢复脚本

```bash
#!/bin/bash
# restore.sh

set -e

# 配置
BACKUP_DIR="/backups/moontv"
BACKUP_DATE="$1"  # 传入备份日期，如 20251212_120000

if [ -z "$BACKUP_DATE" ]; then
  echo "请指定备份日期"
  echo "用法: $0 <备份日期>"
  echo "可用备份:"
  ls "$BACKUP_DIR"
  exit 1
fi

BACKUP_PATH="$BACKUP_DIR/$BACKUP_DATE"

if [ ! -d "$BACKUP_PATH" ]; then
  echo "备份目录不存在: $BACKUP_PATH"
  exit 1
fi

echo "开始从备份恢复: $BACKUP_DATE"

# 1. 验证备份完整性
echo "=== 验证备份完整性 ==="
if [ -f "$BACKUP_PATH/backup_manifest.json.gpg" ]; then
  echo "验证加密备份..."
  gpg --verify "$BACKUP_PATH/backup_manifest.json.gpg"
fi

# 2. 停止服务
echo "=== 停止服务 ==="
docker-compose down

# 3. 恢复Redis数据
echo "=== 恢复Redis数据 ==="
if [ -f "$BACKUP_PATH/redis_dump.rdb" ]; then
  cp "$BACKUP_PATH/redis_dump.rdb" /var/lib/redis/dump.rdb
  chown redis:redis /var/lib/redis/dump.rdb
fi

# 4. 恢复用户数据
echo "=== 恢复用户数据 ==="
if [ -f "$BACKUP_PATH/user_data.json" ]; then
  ./scripts/import-user-data.sh < "$BACKUP_PATH/user_data.json"
fi

# 5. 恢复配置
echo "=== 恢复配置 ==="
if [ -f "$BACKUP_PATH/env.backup" ]; then
  cp "$BACKUP_PATH/env.backup" .env
fi
if [ -f "$BACKUP_PATH/config.json" ]; then
  cp "$BACKUP_PATH/config.json" config.json
fi

# 6. 启动服务
echo "=== 启动服务 ==="
docker-compose up -d

# 7. 验证恢复
echo "=== 验证恢复 ==="
sleep 10
curl -f http://localhost:3000/api/health
curl -f http://localhost:3000/api/health/db

echo "恢复完成"
```

## 运维自动化

### 自动化脚本库

#### 日常运维脚本

```bash
# scripts/ops/
# ├── daily-check.sh          # 每日检查
# ├── weekly-maintenance.sh   # 每周维护
# ├── monthly-audit.sh        # 每月审计
# ├── backup.sh              # 备份脚本
# ├── restore.sh             # 恢复脚本
# ├── scale-out.sh           # 扩展脚本
# ├── scale-in.sh            # 缩容脚本
# ├── monitor-alert.sh       # 监控告警
# └── security-scan.sh       # 安全扫描
```

#### 监控告警自动化

```bash
#!/bin/bash
# monitor-alert.sh

set -e

# 配置
ALERT_THRESHOLDS=(
  "cpu_usage 80"
  "memory_usage 85"
  "disk_usage 90"
  "error_rate 1"
  "response_time 1000"
)

ALERT_CHANNELS=("slack" "email")

# 获取监控指标
function get_metric() {
  case $1 in
    "cpu_usage")
      top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%'
      ;;
    "memory_usage")
      free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}'
      ;;
    "disk_usage")
      df / | tail -1 | awk '{print $5}' | tr -d '%'
      ;;
    "error_rate")
      # 从日志中计算错误率
      grep -c "ERROR" /var/log/moontv/error.log
      ;;
    "response_time")
      # 从监控系统获取响应时间
      curl -s http://localhost:9090/api/v1/query?query=http_request_duration_seconds:rate5m | jq '.data.result[0].value[1]'
      ;;
  esac
}

# 发送告警
function send_alert() {
  local metric=$1
  local value=$2
  local threshold=$3

  local message="🚨 监控告警
指标: $metric
当前值: $value
阈值: $threshold
时间: $(date)
主机: $(hostname)"

  # 发送到Slack
  if [[ " ${ALERT_CHANNELS[@]} " =~ " slack " ]]; then
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"$message\"}" \
      "$SLACK_WEBHOOK_URL"
  fi

  # 发送邮件
  if [[ " ${ALERT_CHANNELS[@]} " =~ " email " ]]; then
    echo "$message" | mail -s "MoonTV监控告警" "$ALERT_EMAIL"
  fi
}

# 主监控循环
for threshold in "${ALERT_THRESHOLDS[@]}"; do
  read metric threshold_value <<< "$threshold"
  current_value=$(get_metric "$metric")

  if [ $(echo "$current_value > $threshold_value" | bc) -eq 1 ]; then
    echo "告警: $metric = $current_value (阈值: $threshold_value)"
    send_alert "$metric" "$current_value" "$threshold_value"
  fi
done
```

### Git 操作方向的最佳实践

**拉取/同步** (从上游到本地)

- **含义**：本地 ← 上游
- **操作**：`git fetch upstream` 或 `git pull upstream`
- **目的**：让本地与上游保持一致
- **结果**：本地完全复制上游的状态

**推送** (从本地到远程)

- **含义**：上游/远程 ← 本地
- **操作**：`git push origin` 或 `git push upstream`
- **目的**：让远程与本地保持一致
- **结果**：远程完全复制本地的状态

**关键描述原则**：

- "从上游同步到本地" - 正确
- "让本地与上游保持一致" - 正确
- "同步上游到本地" - 正确
- 避免使用可能引起方向混淆的描述

**示例操作记录**：

- 2025-12-17: 删除本地 dev 标签，然后从上游同步标签到本地，使本地标签与上游保持一致
- 正确描述："本地从上游同步标签"
- 错误描述："同步上游到本地"（方向模糊）

## CI/CD 流水线集成

#### GitHub Actions 配置

```yaml
# .github/workflows/deploy.yml
name: Deploy MoonTV

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: pnpm/action-setup@v2
        with:
          version: 10.14.0
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
      - run: pnpm build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            stardm0/moontv:latest
            stardm0/moontv:${{ github.sha }}

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster moontv-cluster \
            --service moontv-service \
            --force-new-deployment
```

## 运维文档管理

### 运维知识库结构

```
ops-knowledge-base/
├── incident-response/
│   ├── incident-001.md      # 故障事件记录
│   ├── incident-002.md
│   └── playbooks/           # 应急预案
├── procedures/
│   ├── deployment.md        # 部署流程
│   ├── backup-recovery.md   # 备份恢复流程
│   ├── scaling.md          # 扩缩容流程
│   └── maintenance.md      # 维护流程
├── monitoring/
│   ├── dashboards/         # 监控面板配置
│   ├── alerts/            # 告警规则
│   └── metrics/           # 监控指标定义
├── security/
│   ├── audit/             # 安全审计记录
│   ├── compliance/        # 合规性文档
│   └── policies/          # 安全策略
└── tools/
    ├── scripts/           # 运维脚本
    ├── templates/         # 配置模板
    └── cheatsheets/       # 快速参考手册
```

### 运维交接文档

```markdown
# 运维交接文档

## 系统概况

- **系统名称**: MoonTV
- **当前版本**: 3.6.2
- **部署环境**: 生产环境
- **服务状态**: 运行正常

## 关键信息

### 访问信息

- 管理后台: https://moontv.example.com/admin
- 管理员账号: admin
- TVBox 配置地址: https://moontv.example.com/api/tvbox/config

### 服务器信息

- 主机: moontv-prod-01 (192.168.1.100)
- SSH 端口: 2222
- SSH 密钥: ~/.ssh/moontv-prod.pem

### 数据库信息

- Redis: localhost:6379
- 密码: (存储在环境变量中)

## 日常运维任务

### 每日检查

1. 运行 `./scripts/daily-check.sh`
2. 检查监控面板
3. 查看错误日志

### 每周维护

1. 运行 `./scripts/weekly-maintenance.sh`
2. 更新系统补丁
3. 清理日志文件

### 每月任务

1. 运行 `./scripts/monthly-audit.sh`
2. 安全扫描
3. 性能优化

## 紧急联系人

### 技术支持

- 张三: 138-xxxx-xxxx (主要联系人)
- 李四: 139-xxxx-xxxx (备份联系人)

### 服务商

- 云服务商: AWS (工单系统)
- 域名服务商: Cloudflare
- CDN 服务商: Cloudflare CDN

## 故障处理流程

### 常见故障

1. 应用无法启动: 参考文档 `incident-response/incident-001.md`
2. 性能下降: 参考文档 `incident-response/incident-002.md`
3. 数据不一致: 参考文档 `incident-response/incident-003.md`

### 紧急恢复

1. 备份恢复: `./scripts/restore.sh latest`
2. 服务重启: `docker-compose restart`
3. 回滚版本: `git checkout v3.6.1 && docker-compose up -d`

## 变更记录

### 最近变更

- 2025-12-09: 升级到 v3.6.2
- 2025-12-06: 优化 Docker 构建配置
- 2025-12-05: 升级日志系统

### 计划变更

- 2025-12-20: 计划数据库迁移
- 2025-12-25: 计划安全审计
- 2026-01-01: 计划版本升级到 v3.7.0
```

## 更新历史

- 2025-12-12: 创建运维指南记忆文件，基于项目记忆管理器新规则重构
- 2025-12-09: 更新监控配置和告警规则
- 2025-12-06: 优化备份和恢复策略
- 2025-12-05: 完善性能优化指南
- 2025-11-25: 建立安全运维流程
- 2025-11-01: 创建日常维护检查清单
- 2025-10-20: 建立基础运维体系架构
- 2025-10-01: 制定初始运维规范和流程
