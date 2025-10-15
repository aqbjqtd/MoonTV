/**
 * 安全监控仪表板
 * 显示安全相关指标和日志
 */

'use client';

import React, { useState, useEffect } from 'react';
// 临时Card组件，因为ui/Card不存在
const Card: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className = '',
}) => {
  return (
    <div className={`bg-white rounded-lg shadow-md ${className}`}>
      {children}
    </div>
  );
};
import { SecurityLogger } from '@/lib/security';

interface SecurityMetrics {
  totalRequests: number;
  suspiciousRequests: number;
  rateLimitHits: number;
  errorCount: number;
  criticalEvents: number;
}

interface SecurityLog {
  timestamp: Date;
  level: 'info' | 'warning' | 'error' | 'critical';
  event: string;
  details: string;
}

export default function SecurityDashboard() {
  const [metrics, setMetrics] = useState<SecurityMetrics>({
    totalRequests: 0,
    suspiciousRequests: 0,
    rateLimitHits: 0,
    errorCount: 0,
    criticalEvents: 0,
  });

  const [logs, setLogs] = useState<SecurityLog[]>([]);
  const [autoRefresh, setAutoRefresh] = useState(false);

  // 加载安全数据
  const loadSecurityData = () => {
    try {
      const securityLogs = SecurityLogger.getRecentLogs(60); // 最近60分钟

      // 计算指标
      const calculatedMetrics: SecurityMetrics = {
        totalRequests: securityLogs.length,
        suspiciousRequests: securityLogs.filter(
          (log) =>
            log.event.includes('Suspicious') ||
            log.event.includes('Invalid origin'),
        ).length,
        rateLimitHits: securityLogs.filter((log) =>
          log.event.includes('Rate limit exceeded'),
        ).length,
        errorCount: securityLogs.filter((log) => log.level === 'error').length,
        criticalEvents: securityLogs.filter((log) => log.level === 'critical')
          .length,
      };

      setMetrics(calculatedMetrics);
      setLogs(securityLogs.slice(-20).reverse()); // 最近20条日志，倒序显示
    } catch (error) {
      console.error('Failed to load security data:', error);
    }
  };

  useEffect(() => {
    loadSecurityData();

    if (autoRefresh) {
      const interval = setInterval(loadSecurityData, 30000); // 每30秒刷新
      return () => clearInterval(interval);
    }
  }, [autoRefresh]);

  // 获取日志级别颜色
  const getLogLevelColor = (level: string) => {
    switch (level) {
      case 'info':
        return 'text-blue-600';
      case 'warning':
        return 'text-yellow-600';
      case 'error':
        return 'text-red-600';
      case 'critical':
        return 'text-red-800';
      default:
        return 'text-gray-600';
    }
  };

  // 获取日志级别图标
  const getLogLevelIcon = (level: string) => {
    switch (level) {
      case 'info':
        return 'ℹ️';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'critical':
        return '🚨';
      default:
        return '📝';
    }
  };

  // 格式化时间
  const formatTime = (timestamp: Date) => {
    return new Date(timestamp).toLocaleString('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  return (
    <div className='space-y-6 p-6'>
      {/* 标题和控制 */}
      <div className='flex justify-between items-center'>
        <h1 className='text-3xl font-bold text-gray-900'>🛡️ 安全监控</h1>
        <div className='flex items-center space-x-4'>
          <button
            onClick={loadSecurityData}
            className='px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors'
          >
            🔄 刷新数据
          </button>
          <label className='flex items-center space-x-2'>
            <input
              type='checkbox'
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className='rounded'
            />
            <span>自动刷新</span>
          </label>
        </div>
      </div>

      {/* 安全指标卡片 */}
      <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4'>
        <Card className='p-6'>
          <div className='flex items-center justify-between'>
            <div>
              <p className='text-sm text-gray-600'>总请求数</p>
              <p className='text-2xl font-bold text-gray-900'>
                {metrics.totalRequests}
              </p>
            </div>
            <div className='text-3xl'>📊</div>
          </div>
        </Card>

        <Card className='p-6'>
          <div className='flex items-center justify-between'>
            <div>
              <p className='text-sm text-gray-600'>可疑请求</p>
              <p
                className={`text-2xl font-bold ${metrics.suspiciousRequests > 0 ? 'text-red-600' : 'text-green-600'}`}
              >
                {metrics.suspiciousRequests}
              </p>
            </div>
            <div className='text-3xl'>🔍</div>
          </div>
        </Card>

        <Card className='p-6'>
          <div className='flex items-center justify-between'>
            <div>
              <p className='text-sm text-gray-600'>限流命中</p>
              <p
                className={`text-2xl font-bold ${metrics.rateLimitHits > 0 ? 'text-yellow-600' : 'text-green-600'}`}
              >
                {metrics.rateLimitHits}
              </p>
            </div>
            <div className='text-3xl'>⏱️</div>
          </div>
        </Card>

        <Card className='p-6'>
          <div className='flex items-center justify-between'>
            <div>
              <p className='text-sm text-gray-600'>错误数量</p>
              <p
                className={`text-2xl font-bold ${metrics.errorCount > 0 ? 'text-red-600' : 'text-green-600'}`}
              >
                {metrics.errorCount}
              </p>
            </div>
            <div className='text-3xl'>❌</div>
          </div>
        </Card>

        <Card className='p-6'>
          <div className='flex items-center justify-between'>
            <div>
              <p className='text-sm text-gray-600'>严重事件</p>
              <p
                className={`text-2xl font-bold ${metrics.criticalEvents > 0 ? 'text-red-800' : 'text-green-600'}`}
              >
                {metrics.criticalEvents}
              </p>
            </div>
            <div className='text-3xl'>🚨</div>
          </div>
        </Card>
      </div>

      {/* 安全状态摘要 */}
      <Card className='p-6'>
        <h2 className='text-xl font-semibold mb-4'>🔍 安全状态摘要</h2>
        <div className='grid grid-cols-1 md:grid-cols-3 gap-4'>
          <div className='flex items-center space-x-3'>
            <div
              className={`w-4 h-4 rounded-full ${metrics.suspiciousRequests === 0 ? 'bg-green-500' : 'bg-red-500'}`}
            ></div>
            <span className='text-sm'>
              可疑请求: {metrics.suspiciousRequests === 0 ? '正常' : '需要关注'}
            </span>
          </div>
          <div className='flex items-center space-x-3'>
            <div
              className={`w-4 h-4 rounded-full ${metrics.errorCount === 0 ? 'bg-green-500' : 'bg-yellow-500'}`}
            ></div>
            <span className='text-sm'>
              错误状态:{' '}
              {metrics.errorCount === 0
                ? '无错误'
                : `${metrics.errorCount} 个错误`}
            </span>
          </div>
          <div className='flex items-center space-x-3'>
            <div
              className={`w-4 h-4 rounded-full ${metrics.criticalEvents === 0 ? 'bg-green-500' : 'bg-red-500'}`}
            ></div>
            <span className='text-sm'>
              严重事件:{' '}
              {metrics.criticalEvents === 0
                ? '无严重事件'
                : `${metrics.criticalEvents} 个严重事件`}
            </span>
          </div>
        </div>
      </Card>

      {/* 安全日志 */}
      <Card className='p-6'>
        <div className='flex justify-between items-center mb-4'>
          <h2 className='text-xl font-semibold'>📝 最近安全日志</h2>
          <span className='text-sm text-gray-500'>显示最近20条记录</span>
        </div>

        <div className='space-y-2 max-h-96 overflow-y-auto'>
          {logs.length === 0 ? (
            <div className='text-center text-gray-500 py-8'>
              <div className='text-4xl mb-2'>📭</div>
              <p>暂无安全日志</p>
            </div>
          ) : (
            logs.map((log, index) => (
              <div
                key={index}
                className='p-3 bg-gray-50 rounded-lg border border-gray-200 hover:bg-gray-100 transition-colors'
              >
                <div className='flex items-start justify-between'>
                  <div className='flex items-start space-x-3 flex-1'>
                    <span className='text-lg'>
                      {getLogLevelIcon(log.level)}
                    </span>
                    <div className='flex-1'>
                      <div className='flex items-center space-x-2'>
                        <span
                          className={`text-sm font-medium ${getLogLevelColor(log.level)}`}
                        >
                          {log.level.toUpperCase()}
                        </span>
                        <span className='text-sm text-gray-600'>
                          {formatTime(log.timestamp)}
                        </span>
                      </div>
                      <p className='text-sm text-gray-900 mt-1'>{log.event}</p>
                      {log.details && (
                        <details className='mt-1'>
                          <summary className='text-xs text-gray-600 cursor-pointer hover:text-gray-800'>
                            查看详情
                          </summary>
                          <pre className='text-xs text-gray-700 mt-1 whitespace-pre-wrap bg-gray-100 p-2 rounded'>
                            {log.details}
                          </pre>
                        </details>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </Card>

      {/* 安全建议 */}
      <Card className='p-6'>
        <h2 className='text-xl font-semibold mb-4'>💡 安全建议</h2>
        <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
          <div className='space-y-2'>
            <h3 className='font-medium text-gray-900'>🔒 基础安全</h3>
            <ul className='text-sm text-gray-600 space-y-1'>
              <li>• 定期更新依赖包版本</li>
              <li>• 使用强密码策略</li>
              <li>• 启用HTTPS加密传输</li>
              <li>• 定期备份重要数据</li>
            </ul>
          </div>
          <div className='space-y-2'>
            <h3 className='font-medium text-gray-900'>🛡️ 高级防护</h3>
            <ul className='text-sm text-gray-600 space-y-1'>
              <li>• 配置WAF防火墙规则</li>
              <li>• 实施API访问限流</li>
              <li>• 监控异常访问模式</li>
              <li>• 定期进行安全审计</li>
            </ul>
          </div>
        </div>
      </Card>
    </div>
  );
}
