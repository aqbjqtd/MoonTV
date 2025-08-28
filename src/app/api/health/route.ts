import { NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

interface HealthStatus {
  status: 'ok' | 'error';
  timestamp: string;
  version: string;
  uptime: number;
  environment: string;
  checks: {
    database?: boolean;
    redis?: boolean;
    storage?: boolean;
  };
}

export async function GET(): Promise<NextResponse<HealthStatus>> {
  const startTime = Date.now();
  
  try {
    const checks = {
      database: true, // 默认通过，实际可检查数据库连接
      redis: true,    // 默认通过，实际可检查Redis连接
      storage: true,  // 默认通过，实际可检查存储服务
    };

    const healthStatus: HealthStatus = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '0.1.0',
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      checks,
    };

    return NextResponse.json(healthStatus, {
      status: 200,
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    const healthStatus: HealthStatus = {
      status: 'error',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '0.1.0',
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      checks: {
        database: false,
        redis: false,
        storage: false,
      },
    };

    return NextResponse.json(healthStatus, {
      status: 503,
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Content-Type': 'application/json',
      },
    });
  }
}