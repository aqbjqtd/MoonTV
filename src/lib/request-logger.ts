import { NextRequest, NextResponse } from 'next/server';

import { createModuleLogger } from './logger';

const requestLogger = createModuleLogger('request');

export interface RequestMetrics {
  startTime: number;
  endTime?: number;
  duration?: number;
  method: string;
  path: string;
  userAgent?: string;
  ip?: string;
  statusCode?: number;
  responseSize?: number;
}

export function logRequest(request: NextRequest): RequestMetrics {
  const startTime = Date.now();
  const metrics: RequestMetrics = {
    startTime,
    method: request.method,
    path: request.nextUrl.pathname,
    userAgent: request.headers.get('user-agent') || undefined,
    ip: request.ip || request.headers.get('x-forwarded-for') || undefined,
  };

  requestLogger.info('Request started', {
    method: metrics.method,
    path: metrics.path,
    userAgent: metrics.userAgent,
    ip: metrics.ip,
  });

  return metrics;
}

export function logResponse(
  metrics: RequestMetrics,
  response: NextResponse,
  error?: Error
): void {
  const endTime = Date.now();
  const duration = endTime - metrics.startTime;

  const logData = {
    method: metrics.method,
    path: metrics.path,
    duration,
    statusCode: response.status,
    userAgent: metrics.userAgent,
    ip: metrics.ip,
  };

  if (error) {
    requestLogger.error('Request failed', error, logData);
  } else if (response.status >= 500) {
    requestLogger.error('Server error', new Error('Server error'), logData);
  } else if (response.status >= 400) {
    requestLogger.warn('Client error', logData);
  } else {
    requestLogger.info('Request completed', logData);
  }

  // 性能警告
  if (duration > 5000) {
    requestLogger.warn('Slow request detected', {
      ...logData,
      performance: 'slow',
      threshold: '5s',
    });
  }
}

export function withRequestLogging<T extends NextResponse>(
  handler: (request: NextRequest) => Promise<T>
) {
  return async (request: NextRequest): Promise<T> => {
    const metrics = logRequest(request);
    
    try {
      const response = await handler(request);
      logResponse(metrics, response);
      return response;
    } catch (error) {
      const errorResponse = NextResponse.json(
        { error: 'Internal Server Error' },
        { status: 500 }
      ) as T;
      
      logResponse(metrics, errorResponse, error as Error);
      throw error;
    }
  };
}

export function createApiLogger(apiName: string) {
  const apiLogger = createModuleLogger(`api:${apiName}`);
  
  return {
    logStart: (params?: Record<string, unknown>) => {
      apiLogger.info(`${apiName} API called`, params);
    },
    
    logSuccess: (result?: Record<string, unknown>, duration?: number) => {
      apiLogger.info(`${apiName} API success`, {
        ...result,
        ...(duration && { duration }),
      });
    },
    
    logError: (error: Error, params?: Record<string, unknown>) => {
      apiLogger.error(`${apiName} API error`, error, params);
    },
    
    logValidationError: (errors: Record<string, unknown>) => {
      apiLogger.warn(`${apiName} validation failed`, { errors });
    },
  };
}