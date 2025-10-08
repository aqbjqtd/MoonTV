# MoonTV 企业级监控告警体系 v4.0.0

> 本文档为 MoonTV 项目提供完整的生产级监控告警解决方案，涵盖应用性能、基础设施、业务指标和应急响应的全方位监控。

## 📋 目录

1. [监控架构设计](#监控架构设计)
2. [Prometheus 监控配置](#prometheus监控配置)
3. [Grafana 仪表板](#grafana仪表板)
4. [应用性能监控(APM)](#应用性能监控apm)
5. [日志聚合系统](#日志聚合系统)
6. [告警规则配置](#告警规则配置)
7. [故障排查手册](#故障排查手册)
8. [实施步骤指南](#实施步骤指南)

## 🏗️ 监控架构设计

### 整体架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MoonTV App    │───▶│   Prometheus    │───▶│    Grafana      │
│   (Next.js)     │    │   (Metrics)     │    │ (Visualization) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌─────────────────┐              │
         │              │  AlertManager   │              │
         │              │   (Alerting)    │              │
         │              └─────────────────┘              │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Loki/ELK      │    │   Node Exporter │    │   cAdvisor      │
│   (Logging)     │    │  (Host Metrics) │    │ (Container Met.)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 监控层次

1. **应用层监控**：响应时间、错误率、业务指标
2. **容器层监控**：资源使用、健康状态
3. **基础设施监控**：主机性能、网络状态
4. **用户层监控**：用户体验、可用性

## 📊 Prometheus 监控配置

### 主配置文件：prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'moontv'
    environment: 'production'

rule_files:
  - '/etc/prometheus/rules/*.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  # MoonTV应用监控
  - job_name: 'moontv-app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/api/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
    params:
      format: ['prometheus']

  # 容器监控
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s

  # 主机监控
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s

  # Redis监控（如果使用）
  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']
    scrape_interval: 15s

  # Prometheus自监控
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### Docker Compose 监控配置

```yaml
version: '3.8'

services:
  # MoonTV应用
  moontv:
    build: .
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=production
      - METRICS_ENABLED=true
    labels:
      - 'prometheus.scrape=true'
      - 'prometheus.port=3000'
      - 'prometheus.path=/api/metrics'

  # Prometheus监控
  prometheus:
    image: prom/prometheus:v2.40.0
    ports:
      - '9090:9090'
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    depends_on:
      - moontv

  # AlertManager
  alertmanager:
    image: prom/alertmanager:v0.25.0
    ports:
      - '9093:9093'
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'

  # Grafana仪表板
  grafana:
    image: grafana/grafana:9.3.0
    ports:
      - '3001:3000'
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards

  # 容器监控
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.46.0
    ports:
      - '8080:8080'
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    depends_on:
      - moontv

  # 主机监控
  node-exporter:
    image: prom/node-exporter:v1.5.0
    ports:
      - '9100:9100'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  # Redis监控（可选）
  redis-exporter:
    image: oliver006/redis_exporter:v1.44.0
    ports:
      - '9121:9121'
    environment:
      - REDIS_ADDR=redis://redis:6379
    depends_on:
      - redis

volumes:
  prometheus_data:
  alertmanager_data:
  grafana_data:
```

## 📈 Grafana 仪表板配置

### 应用概览仪表板：moontv-overview.json

```json
{
  "dashboard": {
    "id": null,
    "title": "MoonTV 应用监控概览",
    "tags": ["moontv", "overview"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "应用可用性",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"moontv-app\"}",
            "legendFormat": "{{job}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "mappings": [
              {
                "options": {
                  "0": {
                    "text": "DOWN",
                    "color": "red"
                  },
                  "1": {
                    "text": "UP",
                    "color": "green"
                  }
                },
                "type": "value"
              }
            ]
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "请求速率",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{job=\"moontv-app\"}[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ],
        "yAxes": [
          {
            "label": "请求/秒"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "响应时间分布",
        "type": "heatmap",
        "targets": [
          {
            "expr": "rate(http_request_duration_seconds_bucket{job=\"moontv-app\"}[5m])",
            "legendFormat": "{{le}}"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      },
      {
        "id": 4,
        "title": "错误率",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{job=\"moontv-app\",status=~\"5..\"}[5m]) / rate(http_requests_total{job=\"moontv-app\"}[5m])",
            "legendFormat": "5xx错误率"
          }
        ],
        "yAxes": [
          {
            "label": "错误率",
            "max": 1,
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 16
        }
      },
      {
        "id": 5,
        "title": "活跃用户数",
        "type": "stat",
        "targets": [
          {
            "expr": "active_users_total{job=\"moontv-app\"}",
            "legendFormat": "活跃用户"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 16
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

### 容器资源监控仪表板：moontv-containers.json

```json
{
  "dashboard": {
    "id": null,
    "title": "MoonTV 容器资源监控",
    "tags": ["moontv", "containers"],
    "panels": [
      {
        "id": 1,
        "title": "CPU使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"moontv\"}[5m]) * 100",
            "legendFormat": "CPU使用率"
          }
        ],
        "yAxes": [
          {
            "label": "CPU %",
            "max": 100,
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "内存使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "(container_memory_usage_bytes{name=\"moontv\"} / container_spec_memory_limit_bytes{name=\"moontv\"}) * 100",
            "legendFormat": "内存使用率"
          }
        ],
        "yAxes": [
          {
            "label": "内存 %",
            "max": 100,
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "网络I/O",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_network_receive_bytes_total{name=\"moontv\"}[5m])",
            "legendFormat": "网络流入"
          },
          {
            "expr": "rate(container_network_transmit_bytes_total{name=\"moontv\"}[5m])",
            "legendFormat": "网络流出"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      }
    ]
  }
}
```

## ⚡ 应用性能监控(APM)

### Next.js 应用指标集成

#### metrics.ts - 应用指标收集

```typescript
// src/lib/metrics.ts
import client from 'prom-client';

// 创建指标注册表
const register = new client.Registry();

// 默认指标
client.collectDefaultMetrics({ register });

// HTTP请求计数器
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'endpoint', 'status_code'],
  registers: [register],
});

// HTTP请求持续时间
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'endpoint', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register],
});

// 视频搜索相关指标
const videoSearchTotal = new client.Counter({
  name: 'video_search_total',
  help: 'Total number of video searches',
  labelNames: ['source', 'status'],
  registers: [register],
});

const videoSearchDuration = new client.Histogram({
  name: 'video_search_duration_seconds',
  help: 'Duration of video searches in seconds',
  labelNames: ['source'],
  buckets: [0.5, 1, 2, 5, 10, 20],
  registers: [register],
});

// 用户活跃度指标
const activeUsers = new client.Gauge({
  name: 'active_users_total',
  help: 'Number of active users',
  registers: [register],
});

// 数据库连接池指标
const dbConnectionsActive = new client.Gauge({
  name: 'db_connections_active',
  help: 'Number of active database connections',
  labelNames: ['storage_type'],
  registers: [register],
});

// 存储操作指标
const storageOperations = new client.Counter({
  name: 'storage_operations_total',
  help: 'Total number of storage operations',
  labelNames: ['operation', 'storage_type', 'status'],
  registers: [register],
});

// API源健康状态
const apiSourceHealth = new client.Gauge({
  name: 'api_source_health',
  help: 'Health status of API sources',
  labelNames: ['source_name'],
  registers: [register],
});

export {
  register,
  httpRequestsTotal,
  httpRequestDuration,
  videoSearchTotal,
  videoSearchDuration,
  activeUsers,
  dbConnectionsActive,
  storageOperations,
  apiSourceHealth,
};

// 指标中间件
export function metricsMiddleware() {
  return (req: Request, res: Response, next: Function) => {
    const start = Date.now();

    res.on('finish', () => {
      const duration = (Date.now() - start) / 1000;
      const labels = {
        method: req.method,
        endpoint: req.url || '/',
        status_code: res.statusCode.toString(),
      };

      httpRequestsTotal.inc(labels);
      httpRequestDuration.observe(labels, duration);
    });

    next();
  };
}
```

#### API 端点：/api/metrics/route.ts

```typescript
// src/app/api/metrics/route.ts
import { NextResponse } from 'next/server';
import { register } from '@/lib/metrics';

export const runtime = 'edge';

export async function GET() {
  try {
    const metrics = await register.metrics();
    return new NextResponse(metrics, {
      headers: {
        'Content-Type': register.contentType,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to collect metrics' },
      { status: 500 }
    );
  }
}
```

#### 业务指标集成示例

```typescript
// src/lib/downstream.ts (增强版)
import {
  videoSearchTotal,
  videoSearchDuration,
  apiSourceHealth,
} from './metrics';

export async function searchFromApiStream(
  api: ApiSite,
  keyword: string,
  page: number = 1
): Promise<SearchResult[]> {
  const start = Date.now();

  try {
    // 原有搜索逻辑
    const results = await performSearch(api, keyword, page);

    // 记录成功指标
    videoSearchTotal.inc({ source: api.key, status: 'success' });
    videoSearchDuration.observe(
      { source: api.key },
      (Date.now() - start) / 1000
    );
    apiSourceHealth.set({ source_name: api.key }, 1);

    return results;
  } catch (error) {
    // 记录失败指标
    videoSearchTotal.inc({ source: api.key, status: 'error' });
    apiSourceHealth.set({ source_name: api.key }, 0);

    throw error;
  }
}
```

## 📝 日志聚合系统

### Loki 配置文件：loki.yml

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h
  max_chunk_age: 1h
  chunk_target_size: 1048576
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
```

### Promtail 配置文件：promtail.yml

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # MoonTV应用日志
  - job_name: moontv-app
    static_configs:
      - targets:
          - localhost
        labels:
          job: moontv-app
          __path__: /var/log/moontv/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            timestamp: timestamp
            method: method
            url: url
            status: status
      - timestamp:
          source: timestamp
          format: RFC3339
      - labels:
          level:
          method:
          status:

  # Docker容器日志
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: container
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: stream
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            timestamp: time
      - timestamp:
          source: timestamp
          format: RFC3339
```

### 结构化日志实现

```typescript
// src/lib/logger.ts
export enum LogLevel {
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug',
}

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  method?: string;
  url?: string;
  status?: number;
  userId?: string;
  requestId?: string;
  duration?: number;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
  metadata?: Record<string, any>;
}

class Logger {
  private context: Record<string, any> = {};

  constructor(context: Record<string, any> = {}) {
    this.context = context;
  }

  private log(
    level: LogLevel,
    message: string,
    extra: Record<string, any> = {}
  ) {
    const logEntry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...this.context,
      ...extra,
    };

    if (process.env.NODE_ENV === 'production') {
      console.log(JSON.stringify(logEntry));
    } else {
      console.log(`[${level.toUpperCase()}] ${message}`, logEntry);
    }
  }

  error(message: string, error?: Error, metadata?: Record<string, any>) {
    this.log(LogLevel.ERROR, message, {
      error: error
        ? {
            name: error.name,
            message: error.message,
            stack: error.stack,
          }
        : undefined,
      ...metadata,
    });
  }

  warn(message: string, metadata?: Record<string, any>) {
    this.log(LogLevel.WARN, message, metadata);
  }

  info(message: string, metadata?: Record<string, any>) {
    this.log(LogLevel.INFO, message, metadata);
  }

  debug(message: string, metadata?: Record<string, any>) {
    this.log(LogLevel.DEBUG, message, metadata);
  }

  withContext(context: Record<string, any>): Logger {
    return new Logger({ ...this.context, ...context });
  }
}

export const logger = new Logger();

// 请求日志中间件
export function requestLogger() {
  return (req: Request, res: Response, next: Function) => {
    const requestId = Math.random().toString(36).substring(7);
    const start = Date.now();
    const requestLogger = logger.withContext({
      method: req.method,
      url: req.url,
      requestId,
    });

    requestLogger.info('Request started');

    res.on('finish', () => {
      const duration = Date.now() - start;
      requestLogger.info('Request completed', {
        status: res.statusCode,
        duration,
      });
    });

    next();
  };
}
```

## 🚨 告警规则配置

### 应用告警规则：application-alerts.yml

```yaml
groups:
  - name: moontv-application
    rules:
      # 应用可用性告警
      - alert: MoonTVAppDown
        expr: up{job="moontv-app"} == 0
        for: 30s
        labels:
          severity: critical
          service: moontv
        annotations:
          summary: 'MoonTV应用不可用'
          description: 'MoonTV应用在过去30秒内不可用，请立即检查应用状态'

      # 高错误率告警
      - alert: HighErrorRate
        expr: |
          (
            rate(http_requests_total{job="moontv-app",status=~"5.."}[5m]) 
            / 
            rate(http_requests_total{job="moontv-app"}[5m])
          ) > 0.05
        for: 2m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '应用错误率过高'
          description: '应用5xx错误率在过去5分钟内超过5%，当前值: {{ $value | humanizePercentage }}'

      # 响应时间过长告警
      - alert: HighResponseTime
        expr: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket{job="moontv-app"}[5m])
          ) > 2
        for: 3m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '应用响应时间过长'
          description: '95%的请求响应时间超过2秒，当前值: {{ $value }}秒'

      # 内存使用率过高
      - alert: HighMemoryUsage
        expr: |
          (container_memory_usage_bytes{name="moontv"} / 
           container_spec_memory_limit_bytes{name="moontv"}) * 100 > 85
        for: 5m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '容器内存使用率过高'
          description: 'MoonTV容器内存使用率超过85%，当前值: {{ $value }}%'

      # CPU使用率过高
      - alert: HighCpuUsage
        expr: |
          rate(container_cpu_usage_seconds_total{name="moontv"}[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '容器CPU使用率过高'
          description: 'MoonTV容器CPU使用率超过80%，当前值: {{ $value }}%'

      # 磁盘空间不足
      - alert: LowDiskSpace
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} / 
           node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 1m
        labels:
          severity: critical
          service: moontv
        annotations:
          summary: '磁盘空间不足'
          description: '根分区可用空间少于10%，当前值: {{ $value }}%'

      # API源健康状态告警
      - alert: ApiSourceDown
        expr: api_source_health == 0
        for: 2m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: 'API源不可用'
          description: 'API源 {{ $labels.source_name }} 在过去2分钟内不可用'

      # 数据库连接告警
      - alert: DatabaseConnectionFailure
        expr: db_connections_active == 0
        for: 1m
        labels:
          severity: critical
          service: moontv
        annotations:
          summary: '数据库连接失败'
          description: '存储类型 {{ $labels.storage_type }} 的数据库连接为0'
```

### 业务指标告警：business-alerts.yml

```yaml
groups:
  - name: moontv-business
    rules:
      # 搜索失败率过高
      - alert: HighSearchFailureRate
        expr: |
          (
            rate(video_search_total{status="error"}[5m]) /
            rate(video_search_total[5m])
          ) > 0.1
        for: 3m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '视频搜索失败率过高'
          description: '视频搜索失败率在过去5分钟内超过10%，当前值: {{ $value | humanizePercentage }}'

      # 搜索响应时间过长
      - alert: SlowVideoSearch
        expr: |
          histogram_quantile(0.95,
            rate(video_search_duration_seconds_bucket[5m])
          ) > 10
        for: 5m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '视频搜索响应时间过长'
          description: '95%的视频搜索响应时间超过10秒，当前值: {{ $value }}秒'

      # 活跃用户数异常下降
      - alert: ActiveUsersDrop
        expr: |
          (
            active_users_total offset 1h
            -
            active_users_total
          ) / active_users_total offset 1h > 0.5
        for: 10m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '活跃用户数异常下降'
          description: '活跃用户数在过去1小时内下降超过50%，当前值: {{ $value }}'

      # 存储操作失败率过高
      - alert: HighStorageFailureRate
        expr: |
          (
            rate(storage_operations_total{status="error"}[5m]) /
            rate(storage_operations_total[5m])
          ) > 0.05
        for: 2m
        labels:
          severity: warning
          service: moontv
        annotations:
          summary: '存储操作失败率过高'
          description: '存储操作失败率在过去5分钟内超过5%，存储类型: {{ $labels.storage_type }}'
```

### AlertManager 配置：alertmanager.yml

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@moontv.com'
  smtp_auth_username: 'alerts@moontv.com'
  smtp_auth_password: 'your-app-password'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
    # 关键告警立即发送
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      repeat_interval: 5m

    # 警告级别告警聚合发送
    - match:
        severity: warning
      receiver: 'warning-alerts'
      group_wait: 30s
      repeat_interval: 2h

receivers:
  # Webhook接收器（用于钉钉、企业微信等）
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

  # 关键告警接收器
  - name: 'critical-alerts'
    email_configs:
      - to: 'ops-team@moontv.com'
        subject: '[CRITICAL] MoonTV告警: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          告警名称: {{ .Annotations.summary }}
          告警描述: {{ .Annotations.description }}
          告警级别: {{ .Labels.severity }}
          服务名称: {{ .Labels.service }}
          开始时间: {{ .StartsAt }}
          {{ end }}
    webhook_configs:
      - url: 'https://oapi.dingtalk.com/robot/send?access_token=your-token'
        message: |
          {
            "msgtype": "markdown",
            "markdown": {
              "title": "MoonTV关键告警",
              "text": "## MoonTV关键告警\n\n{{ range .Alerts }}**告警名称**: {{ .Annotations.summary }}\n\n**告警描述**: {{ .Annotations.description }}\n\n**服务名称**: {{ .Labels.service }}\n\n**开始时间**: {{ .StartsAt }}\n\n---\n{{ end }}"
            }
          }

  # 警告告警接收器
  - name: 'warning-alerts'
    email_configs:
      - to: 'dev-team@moontv.com'
        subject: '[WARNING] MoonTV告警: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          告警名称: {{ .Annotations.summary }}
          告警描述: {{ .Annotations.description }}
          告警级别: {{ .Labels.severity }}
          服务名称: {{ .Labels.service }}
          开始时间: {{ .StartsAt }}
          {{ end }}

inhibit_rules:
  # 如果应用已下线，抑制其他相关告警
  - source_match:
      alertname: MoonTVAppDown
    target_match:
      service: moontv
    equal: ['service']
```

## 🔧 故障排查手册

### 1. 应用不可用故障排查

**症状**: MoonTVAppDown 告警触发

**排查步骤**:

```bash
# 1. 检查容器状态
docker ps | grep moontv

# 2. 查看容器日志
docker logs moontv --tail 100

# 3. 检查应用健康状态
curl -f http://localhost:3000/api/health

# 4. 检查端口占用
netstat -tlnp | grep :3000

# 5. 检查系统资源
docker stats moontv

# 6. 重启应用（如果需要）
docker restart moontv
```

**常见原因及解决方案**:

1. **内存溢出**: 检查内存限制，增加容器内存
2. **端口冲突**: 修改端口映射或停止冲突服务
3. **配置错误**: 检查环境变量和配置文件
4. **依赖服务不可用**: 检查 Redis、数据库等依赖

### 2. 高错误率故障排查

**症状**: HighErrorRate 告警触发

**排查步骤**:

```bash
# 1. 查看应用错误日志
docker logs moontv 2>&1 | grep ERROR | tail -20

# 2. 检查最近的错误状态码
curl -s "http://localhost:9090/api/v1/query?query=rate(http_requests_total{job=\"moontv-app\",status=~\"5..\"}[5m])"

# 3. 分析具体的错误端点
curl -s "http://localhost:9090/api/v1/query?query=topk(10,rate(http_requests_total{job=\"moontv-app\",status=~\"5..\"}[5m]))"

# 4. 检查数据库连接
curl -s "http://localhost:3000/api/health"

# 5. 检查外部API源状态
curl -I $(grep -o '"api":"[^"]*"' config.json | cut -d'"' -f4 | head -1)
```

### 3. 性能问题排查

**症状**: HighResponseTime 或 SlowVideoSearch 告警

**排查步骤**:

```bash
# 1. 检查容器资源使用
docker stats moontv --no-stream

# 2. 分析慢查询日志
grep "slow" docker logs moontv 2>&1 | tail -10

# 3. 检查网络延迟
ping -c 3 $(echo $REDIS_URL | cut -d'/' -f3 | cut -d':' -f1)

# 4. 分析搜索性能
curl -s "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(video_search_duration_seconds_bucket[5m]))"

# 5. 检查并发连接数
curl -s "http://localhost:9090/api/v1/query?query=active_users_total"
```

### 4. 存储问题排查

**症状**: DatabaseConnectionFailure 或 HighStorageFailureRate

**排查步骤**:

```bash
# Redis连接测试
redis-cli -u $REDIS_URL ping

# 检查Redis内存使用
redis-cli -u $REDIS_URL info memory

# 检查Redis连接数
redis-cli -u $REDIS_URL info clients

# 分析存储操作错误
grep "storage" docker logs moontv 2>&1 | grep ERROR | tail -10
```

### 应急响应预案

#### 级别 1: 关键告警（5 分钟内响应）

1. **应用不可用**

   - 立即检查容器状态
   - 必要时重启应用
   - 通知运维团队

2. **磁盘空间不足**
   - 清理临时文件和日志
   - 检查数据增长趋势
   - 考虑扩容

#### 级别 2: 警告告警（30 分钟内响应）

1. **高错误率**

   - 分析错误日志
   - 检查外部依赖
   - 评估影响范围

2. **性能问题**
   - 监控资源使用
   - 分析慢查询
   - 优化配置参数

#### 级别 3: 信息告警（2 小时内响应）

1. **业务指标异常**
   - 分析用户行为
   - 检查数据质量
   - 制定优化计划

## 📋 实施步骤指南

### 阶段 1: 基础监控部署（第 1-2 天）

1. **部署监控系统**

```bash
# 创建监控配置目录
mkdir -p monitoring/{rules,grafana/{provisioning,dashboards}}

# 复制配置文件
cp prometheus.yml monitoring/
cp alertmanager.yml monitoring/
cp loki.yml monitoring/
cp promtail.yml monitoring/

# 启动监控系统
docker-compose -f monitoring/docker-compose.yml up -d
```

2. **集成应用指标**

```bash
# 安装prom-client
npm install prom-client

# 创建metrics模块
# src/lib/metrics.ts
# src/app/api/metrics/route.ts
```

3. **配置 Grafana 仪表板**

```bash
# 导入仪表板配置
curl -X POST \
  http://admin:admin123@localhost:3001/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @monitoring/grafana/dashboards/moontv-overview.json
```

### 阶段 2: 日志聚合配置（第 3-4 天）

1. **部署 Loki 日志系统**

```bash
# 启动Loki和Promtail
docker-compose -f monitoring/docker-compose.logging.yml up -d
```

2. **集成结构化日志**

```bash
# 更新应用日志模块
# src/lib/logger.ts
# 在关键路径添加日志记录
```

3. **配置日志告警**

```yaml
# monitoring/rules/log-alerts.yml
groups:
  - name: moontv-logs
    rules:
      - alert: HighErrorLogs
        expr: |
          (
            rate(log_messages_total{level="error"}[5m]) /
            rate(log_messages_total[5m])
          ) > 0.05
        for: 2m
```

### 阶段 3: 告警规则优化（第 5-7 天）

1. **调整告警阈值**

```bash
# 根据历史数据调整阈值
# 测试告警触发和恢复
```

2. **配置通知渠道**

```bash
# 配置邮件通知
# 配置钉钉/企业微信机器人
# 测试消息发送
```

3. **创建值班表**

```bash
# 配置告警路由规则
# 设置值班人员轮换
```

### 阶段 4: 性能优化（第 8-14 天）

1. **优化指标收集**

```typescript
// 减少高频指标收集频率
// 增加业务指标维度
// 优化标签使用
```

2. **优化日志聚合**

```yaml
# 配置日志采样
# 设置日志保留策略
# 优化日志解析规则
```

3. **优化告警规则**

```yaml
# 减少告警噪音
# 增加告警聚合
# 优化告警描述
```

### 阶段 5: 文档和培训（第 15-21 天）

1. **完善文档**

   - 更新操作手册
   - 创建故障处理流程图
   - 编写值班指南

2. **团队培训**

   - 监控系统使用培训
   - 故障排查演练
   - 告警处理流程培训

3. **持续改进**
   - 定期评估监控效果
   - 根据反馈调整策略
   - 引入新的监控技术

## 📊 监控指标清单

### 应用层指标

| 指标名称                      | 类型      | 描述              | 告警阈值       |
| ----------------------------- | --------- | ----------------- | -------------- |
| http_requests_total           | Counter   | HTTP 请求总数     | -              |
| http_request_duration_seconds | Histogram | HTTP 请求持续时间 | P95 > 2s       |
| video_search_total            | Counter   | 视频搜索次数      | -              |
| video_search_duration_seconds | Histogram | 搜索持续时间      | P95 > 10s      |
| active_users_total            | Gauge     | 活跃用户数        | 同比下降 > 50% |
| api_source_health             | Gauge     | API 源健康状态    | 0 (不可用)     |

### 系统层指标

| 指标名称               | 类型  | 描述             | 告警阈值     |
| ---------------------- | ----- | ---------------- | ------------ |
| container_cpu_usage    | Gauge | 容器 CPU 使用率  | > 80%        |
| container_memory_usage | Gauge | 容器内存使用率   | > 85%        |
| node_filesystem_avail  | Gauge | 磁盘可用空间     | < 10%        |
| node_load1             | Gauge | 系统负载         | > CPU 核心数 |
| db_connections_active  | Gauge | 数据库活跃连接数 | = 0          |

### 业务层指标

| 指标名称                 | 类型      | 描述           | 告警阈值    |
| ------------------------ | --------- | -------------- | ----------- |
| search_success_rate      | Gauge     | 搜索成功率     | < 90%       |
| user_session_duration    | Histogram | 用户会话时长   | 异常下降    |
| video_play_success_rate  | Gauge     | 视频播放成功率 | < 95%       |
| storage_operations_total | Counter   | 存储操作总数   | 错误率 > 5% |

## 🎯 最佳实践建议

### 1. 指标设计原则

- **有意义**: 只收集对业务有价值的指标
- **可操作**: 每个指标都应该有对应的行动方案
- **一致性**: 在整个系统中保持指标定义一致
- **高效性**: 避免过度收集影响性能

### 2. 告警设计原则

- **准确性**: 避免误报和漏报
- **及时性**: 快速发现和通知问题
- **可读性**: 告警信息清晰易懂
- **可操作**: 提供明确的处理建议

### 3. 可视化设计原则

- **层次化**: 从概览到详细的层次结构
- **相关性**: 相关指标放在同一仪表板
- **时效性**: 数据刷新频率适中
- **美观性**: 配色和布局清晰易读

### 4. 运维流程原则

- **标准化**: 建立标准化的操作流程
- **自动化**: 尽可能自动化故障处理
- **文档化**: 完善的文档和知识库
- **持续改进**: 定期回顾和优化监控体系

## 🔄 维护和升级计划

### 月度维护任务

1. **检查监控系统健康状态**
2. **更新监控配置和告警规则**
3. **分析历史数据和趋势**
4. **清理过期的监控数据和日志**

### 季度升级任务

1. **升级监控工具版本**
2. **优化监控架构设计**
3. **增加新的监控指标**
4. **更新告警通知配置**

### 年度评估任务

1. **评估监控体系整体效果**
2. **制定下一年度监控计划**
3. **引入新的监控技术和工具**
4. **培训团队成员使用新功能**

---

**文档版本**: v4.0.0  
**最后更新**: 2025-10-08  
**维护人员**: MoonTV 运维团队  
**联系邮箱**: ops@moontv.com

本监控系统为 MoonTV 项目提供全方位的监控告警能力，确保系统的稳定性和可靠性。
