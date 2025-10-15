// 健康检查和监控
export interface HealthCheck {
  status: 'healthy' | 'unhealthy';
  timestamp: string;
  uptime: number;
  memory: NodeJS.MemoryUsage;
  version: string;
  environment: string;
}

export interface PerformanceMetrics {
  responseTime: number;
  memoryUsage: NodeJS.MemoryUsage;
  cpuUsage: NodeJS.CpuUsage;
  timestamp: string;
}

class HealthMonitor {
  private startTime: Date;
  private metrics: PerformanceMetrics[] = [];
  private maxMetricsCount: number = 100;

  constructor() {
    this.startTime = new Date();
  }

  getHealthCheck(): HealthCheck {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: process.env.npm_package_version || 'unknown',
      environment: process.env.NODE_ENV || 'development',
    };
  }

  recordPerformanceMetric(responseTime: number): void {
    const metric: PerformanceMetrics = {
      responseTime,
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage(),
      timestamp: new Date().toISOString(),
    };

    this.metrics.push(metric);

    // 保持最近100条记录
    if (this.metrics.length > this.maxMetricsCount) {
      this.metrics = this.metrics.slice(-this.maxMetricsCount);
    }
  }

  getAverageResponseTime(): number {
    if (this.metrics.length === 0) return 0;

    const total = this.metrics.reduce(
      (sum, metric) => sum + metric.responseTime,
      0,
    );
    return total / this.metrics.length;
  }

  getMemoryUsage(): NodeJS.MemoryUsage {
    return process.memoryUsage();
  }

  getUptime(): number {
    return process.uptime();
  }

  // 检查系统是否健康
  async checkSystemHealth(): Promise<
    HealthCheck & { checks: Record<string, boolean> }
  > {
    const health = this.getHealthCheck();

    const checks = {
      memory: this.checkMemoryUsage(),
      uptime: this.checkUptime(),
      responseTime: this.checkResponseTime(),
    };

    const isHealthy = Object.values(checks).every((check) => check);

    return {
      ...health,
      status: isHealthy ? 'healthy' : 'unhealthy',
      checks,
    };
  }

  private checkMemoryUsage(): boolean {
    const memory = process.memoryUsage();
    const memoryUsagePercent = memory.heapUsed / memory.heapTotal;
    return memoryUsagePercent < 0.9; // 内存使用率低于90%
  }

  private checkUptime(): boolean {
    return process.uptime() > 0;
  }

  private checkResponseTime(): boolean {
    const avgResponseTime = this.getAverageResponseTime();
    return avgResponseTime < 1000; // 平均响应时间低于1秒
  }

  // 获取性能报告
  getPerformanceReport(): {
    averageResponseTime: number;
    totalRequests: number;
    memoryUsage: NodeJS.MemoryUsage;
    uptime: number;
  } {
    return {
      averageResponseTime: this.getAverageResponseTime(),
      totalRequests: this.metrics.length,
      memoryUsage: this.getMemoryUsage(),
      uptime: this.getUptime(),
    };
  }
}

// 导出单例实例
export const healthMonitor = new HealthMonitor();
