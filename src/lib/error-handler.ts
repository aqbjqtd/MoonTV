import { NextResponse } from 'next/server';

import { createModuleLogger,logger } from './logger';

import type { ApiResponse } from '@/types/api';

interface DebugApiResponse extends ApiResponse {
  error?: {
    type: string;
    stack?: string;
    context?: Record<string, unknown>;
  };
}

const errorLogger = createModuleLogger('error');

export interface ErrorContext extends Record<string, unknown> {
  userId?: string;
  requestId?: string;
  userAgent?: string;
  ip?: string;
  path?: string;
  method?: string;
  params?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
}

export class AppError extends Error {
  public readonly code: number;
  public readonly isOperational: boolean;
  public readonly context?: ErrorContext;

  constructor(
    message: string,
    code = 500,
    isOperational = true,
    context?: ErrorContext
  ) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.isOperational = isOperational;
    this.context = context;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string, context?: ErrorContext) {
    super(message, 400, true, context);
    this.name = 'ValidationError';
  }
}

export class AuthenticationError extends AppError {
  constructor(message = 'Authentication required', context?: ErrorContext) {
    super(message, 401, true, context);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends AppError {
  constructor(message = 'Insufficient permissions', context?: ErrorContext) {
    super(message, 403, true, context);
    this.name = 'AuthorizationError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource = 'Resource', context?: ErrorContext) {
    super(`${resource} not found`, 404, true, context);
    this.name = 'NotFoundError';
  }
}

export class RateLimitError extends AppError {
  constructor(message = 'Rate limit exceeded', context?: ErrorContext) {
    super(message, 429, true, context);
    this.name = 'RateLimitError';
  }
}

export class ExternalServiceError extends AppError {
  constructor(service: string, message?: string, context?: ErrorContext) {
    super(message || `${service} service unavailable`, 502, true, context);
    this.name = 'ExternalServiceError';
  }
}

export function handleError(error: unknown, context?: ErrorContext): NextResponse<ApiResponse> {
  // 确保error是Error类型
  const err = error instanceof Error ? error : new Error(String(error));
  
  let statusCode = 500;
  let message = 'Internal Server Error';
  let errorCode = 'INTERNAL_ERROR';

  if (error instanceof AppError) {
    statusCode = error.code;
    message = error.message;
    errorCode = error.name.replace('Error', '').toUpperCase();
    
    // 合并错误上下文
    const combinedContext = { ...context, ...error.context };
    
    if (error.isOperational) {
      errorLogger.warn(`Operational error: ${error.name}`, {
        message: error.message,
        code: error.code,
        context: combinedContext,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      });
    } else {
      errorLogger.error(`Programming error: ${error.name}`, err, combinedContext);
    }
  } else if (err.name === 'ZodError') {
    // Zod验证错误
    statusCode = 400;
    message = 'Validation failed';
    errorCode = 'VALIDATION_ERROR';
    
    errorLogger.warn('Zod validation error', {
      message: err.message,
      context,
    });
  } else {
    // 未知错误
    errorLogger.error('Unhandled error', err, context);
  }

  const response: DebugApiResponse = {
    code: statusCode,
    message,
    data: null,
    timestamp: Date.now(),
  };

  // 在开发环境中包含更多错误信息
  if (process.env.NODE_ENV === 'development') {
    response.error = {
      type: errorCode,
      stack: err.stack,
      context,
    };
  }

  return NextResponse.json(response, { status: statusCode });
}

export function withErrorHandler<T extends unknown[]>(
  handler: (...args: T) => Promise<NextResponse>
) {
  return async (...args: T): Promise<NextResponse> => {
    try {
      return await handler(...args);
    } catch (error) {
      return handleError(error);
    }
  };
}

export function createErrorReporter(module: string) {
  const moduleLogger = createModuleLogger(`error:${module}`);
  
  return {
    reportError: (error: Error, context?: ErrorContext) => {
      moduleLogger.error(`${module} error`, error, context);
    },
    
    reportWarning: (message: string, context?: Record<string, unknown>) => {
      moduleLogger.warn(`${module} warning`, context);
    },
    
    reportInfo: (message: string, context?: Record<string, unknown>) => {
      moduleLogger.info(`${module} info`, context);
    },
  };
}

// 全局错误处理器（用于捕获未处理的Promise拒绝）
if (typeof window === 'undefined') {
  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Promise Rejection', new Error(String(reason)), {
      reason: String(reason),
      promise: String(promise),
    });
  });

  process.on('uncaughtException', (error) => {
    logger.fatal('Uncaught Exception', error);
    process.exit(1);
  });
}