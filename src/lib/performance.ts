/**
 * 性能监控工具
 * 用于监控应用性能指标
 */

// 性能指标类型
interface PerformanceMetrics {
  // 核心Web指标
  fcp?: number; // First Contentful Paint
  lcp?: number; // Largest Contentful Paint
  fid?: number; // First Input Delay
  cls?: number; // Cumulative Layout Shift

  // 自定义指标
  pageLoadTime?: number;
  apiResponseTime?: number;
  bundleSize?: number;

  // 内存使用
  memoryUsage?: {
    used: number;
    total: number;
  };
}

// 性能数据收集器
class PerformanceMonitor {
  private metrics: PerformanceMetrics = {};
  private observers: PerformanceObserver[] = [];

  constructor() {
    this.init();
  }

  private init() {
    if (typeof window !== 'undefined' && 'performance' in window) {
      this.observeWebVitals();
      this.measurePageLoadTime();
    }
  }

  // 观察 Web Vitals
  private observeWebVitals() {
    try {
      // FCP (First Contentful Paint)
      this.observePerformanceEntry('paint', (entries) => {
        const fcpEntry = entries.find(
          (entry) => entry.name === 'first-contentful-paint',
        );
        if (fcpEntry) {
          this.metrics.fcp = fcpEntry.startTime;
        }
      });

      // LCP (Largest Contentful Paint)
      this.observePerformanceEntry('largest-contentful-paint', (entries) => {
        const lastEntry = entries[entries.length - 1];
        if (lastEntry) {
          this.metrics.lcp = lastEntry.startTime;
        }
      });

      // FID (First Input Delay)
      this.observePerformanceEntry('first-input', (entries) => {
        const fidEntry = entries[0];
        if (fidEntry) {
          this.metrics.fid = fidEntry.processingStart - fidEntry.startTime;
        }
      });

      // CLS (Cumulative Layout Shift)
      let clsValue = 0;
      this.observePerformanceEntry('layout-shift', (entries) => {
        entries.forEach((entry) => {
          if (!(entry as any).hadRecentInput) {
            clsValue += (entry as any).value;
          }
        });
        this.metrics.cls = clsValue;
      });
    } catch (error) {
      console.warn('Performance monitoring not fully supported:', error);
    }
  }

  private observePerformanceEntry(
    type: string,
    callback: (entries: any[]) => void,
  ) {
    try {
      const observer = new PerformanceObserver((list) => {
        callback(list.getEntries());
      });
      observer.observe({ type, buffered: true });
      this.observers.push(observer);
    } catch (error) {
      console.warn(`Failed to observe ${type}:`, error);
    }
  }

  // 测量页面加载时间
  private measurePageLoadTime() {
    window.addEventListener('load', () => {
      const navigation = performance.getEntriesByType(
        'navigation',
      )[0] as PerformanceNavigationTiming;
      if (navigation) {
        this.metrics.pageLoadTime =
          navigation.loadEventEnd - navigation.fetchStart;
      }
    });
  }

  // 测量API响应时间
  measureApiResponseTime(apiCall: () => Promise<any>): Promise<number> {
    const startTime = performance.now();

    return apiCall().finally(() => {
      const endTime = performance.now();
      const responseTime = endTime - startTime;

      if (
        !this.metrics.apiResponseTime ||
        responseTime > this.metrics.apiResponseTime
      ) {
        this.metrics.apiResponseTime = responseTime;
      }

      return responseTime;
    });
  }

  // 获取内存使用情况
  getMemoryUsage(): PerformanceMetrics['memoryUsage'] | null {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      return {
        used: memory.usedJSHeapSize,
        total: memory.totalJSHeapSize,
      };
    }
    return null;
  }

  // 获取所有性能指标
  getMetrics(): PerformanceMetrics {
    const memoryUsage = this.getMemoryUsage();
    return {
      ...this.metrics,
      memoryUsage: memoryUsage || undefined,
    };
  }

  // 清理观察者
  disconnect() {
    this.observers.forEach((observer) => observer.disconnect());
    this.observers = [];
  }
}

// 性能报告生成器
export class PerformanceReporter {
  static generateReport(metrics: PerformanceMetrics): string {
    const report = [
      '🔍 性能监控报告',
      '='.repeat(30),
      '',
      '📊 Core Web Vitals:',
    ];

    if (metrics.fcp !== undefined) {
      report.push(
        `   FCP (First Contentful Paint): ${metrics.fcp.toFixed(2)}ms ${this.getFCPRating(metrics.fcp)}`,
      );
    }

    if (metrics.lcp !== undefined) {
      report.push(
        `   LCP (Largest Contentful Paint): ${metrics.lcp.toFixed(2)}ms ${this.getLCPRating(metrics.lcp)}`,
      );
    }

    if (metrics.fid !== undefined) {
      report.push(
        `   FID (First Input Delay): ${metrics.fid.toFixed(2)}ms ${this.getFIDRating(metrics.fid)}`,
      );
    }

    if (metrics.cls !== undefined) {
      report.push(
        `   CLS (Cumulative Layout Shift): ${metrics.cls.toFixed(4)} ${this.getCLSRating(metrics.cls)}`,
      );
    }

    report.push('', '⚡ 自定义指标:');

    if (metrics.pageLoadTime !== undefined) {
      report.push(`   页面加载时间: ${metrics.pageLoadTime.toFixed(2)}ms`);
    }

    if (metrics.apiResponseTime !== undefined) {
      report.push(`   API响应时间: ${metrics.apiResponseTime.toFixed(2)}ms`);
    }

    if (metrics.memoryUsage) {
      const usedMB = (metrics.memoryUsage.used / 1024 / 1024).toFixed(2);
      const totalMB = (metrics.memoryUsage.total / 1024 / 1024).toFixed(2);
      report.push(`   内存使用: ${usedMB}MB / ${totalMB}MB`);
    }

    report.push('', '💡 优化建议:');
    report.push(...this.getOptimizationSuggestions(metrics));

    return report.join('\n');
  }

  private static getFCPRating(fcp: number): string {
    if (fcp < 1800) return '✅ 良好';
    if (fcp < 3000) return '⚠️ 需要改进';
    return '❌ 较差';
  }

  private static getLCPRating(lcp: number): string {
    if (lcp < 2500) return '✅ 良好';
    if (lcp < 4000) return '⚠️ 需要改进';
    return '❌ 较差';
  }

  private static getFIDRating(fid: number): string {
    if (fid < 100) return '✅ 良好';
    if (fid < 300) return '⚠️ 需要改进';
    return '❌ 较差';
  }

  private static getCLSRating(cls: number): string {
    if (cls < 0.1) return '✅ 良好';
    if (cls < 0.25) return '⚠️ 需要改进';
    return '❌ 较差';
  }

  private static getOptimizationSuggestions(
    metrics: PerformanceMetrics,
  ): string[] {
    const suggestions: string[] = [];

    if (metrics.fcp && metrics.fcp > 1800) {
      suggestions.push('   - 优化服务器响应时间');
      suggestions.push('   - 减少渲染阻塞资源');
    }

    if (metrics.lcp && metrics.lcp > 2500) {
      suggestions.push('   - 优化图片加载（使用现代格式、懒加载）');
      suggestions.push('   - 预加载关键资源');
    }

    if (metrics.fid && metrics.fid > 100) {
      suggestions.push('   - 减少JavaScript执行时间');
      suggestions.push('   - 代码分割和懒加载');
    }

    if (metrics.cls && metrics.cls > 0.1) {
      suggestions.push('   - 为图片和广告设置明确的尺寸');
      suggestions.push('   - 避免动态插入内容');
    }

    if (metrics.pageLoadTime && metrics.pageLoadTime > 3000) {
      suggestions.push('   - 启用压缩和缓存');
      suggestions.push('   - 使用CDN加速');
    }

    if (suggestions.length === 0) {
      suggestions.push('   - 性能表现良好，继续保持！');
    }

    return suggestions;
  }
}

// 全局性能监控实例
export const performanceMonitor = new PerformanceMonitor();

// 性能监控Hook
export function usePerformanceMonitor() {
  const getReport = () => {
    const metrics = performanceMonitor.getMetrics();
    return PerformanceReporter.generateReport(metrics);
  };

  const measureAPI = (apiCall: () => Promise<any>) => {
    return performanceMonitor.measureApiResponseTime(apiCall);
  };

  return {
    getMetrics: performanceMonitor.getMetrics.bind(performanceMonitor),
    getReport,
    measureAPI,
  };
}

// 导出类型
export type { PerformanceMetrics };
