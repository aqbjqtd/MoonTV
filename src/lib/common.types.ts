/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * 通用类型定义
 * 用于替换项目中的 any 类型，提高类型安全性
 */

// ===== 错误处理相关类型 =====
export interface BaseError {
  message: string;
  code?: string | number;
  stack?: string;
  details?: Record<string, unknown>;
}

export interface NetworkError extends BaseError {
  name: 'NetworkError';
  status?: number;
  statusText?: string;
}

export interface DatabaseError extends BaseError {
  name: 'DatabaseError';
  query?: string;
  params?: unknown[];
}

export interface ValidationError extends BaseError {
  name: 'ValidationError';
  field?: string;
  value?: unknown;
}

export type AppError = NetworkError | DatabaseError | ValidationError | Error;

// ===== API 响应相关类型 =====
export interface ApiResponse<T = unknown> {
  data?: T;
  error?: string;
  message?: string;
  success?: boolean;
  status?: number;
}

export interface PaginatedResponse<T = unknown> extends ApiResponse<T[]> {
  pagination?: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

// ===== 存储相关类型 =====
export interface StorageOperation {
  key: string;
  value?: unknown;
  timestamp?: number;
  ttl?: number;
}

export interface BatchStorageResult {
  succeeded: string[];
  failed: Array<{
    key: string;
    error: AppError;
  }>;
}

// ===== HLS.js 事件相关类型 =====
export interface HlsFragmentPayload {
  byteLength?: number;
  [key: string]: unknown;
}

export interface HlsFragmentData {
  frag?: {
    url: string;
    byteRange?: [number, number] | [];
    level: number;
    sn: number;
  };
  payload?: HlsFragmentPayload;
  stats?: {
    loaded: number;
    total: number;
    loading: number;
  };
}

export interface HlsErrorData {
  type: string;
  details: string;
  fatal: boolean;
  frag?: {
    url: string;
    byteRange?: [number, number] | [];
    level: number;
    sn: number;
  };
  level?: number;
}

// ===== 数据库操作相关类型 =====
export interface DatabaseQueryResult<T = unknown> {
  success: boolean;
  data?: T;
  error?: AppError;
  meta?: {
    changes?: number;
    lastInsertRowid?: number;
    duration?: number;
  };
}

export interface DatabaseBatchOperation<T = unknown> {
  query: string;
  params?: unknown[];
  result?: T;
}

// ===== 事件处理相关类型 =====
export interface CustomEventData<T = unknown> {
  type: string;
  detail: T;
  timestamp: number;
}

export interface EventCallback<T = unknown> {
  (event: CustomEventData<T>): void;
  (event: CustomEvent): void;
}

// ===== 配置相关类型 =====
export interface ConfigSection {
  [key: string]: unknown;
}

export interface RuntimeConfig {
  STORAGE_TYPE?: string;
  SITE_NAME?: string;
  [key: string]: unknown;
}

// ===== 工具类型 =====
export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
export type RequiredBy<T, K extends keyof T> = T & Required<Pick<T, K>>;
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

// ===== 类型断言辅助函数 =====
export function isNetworkError(error: unknown): error is NetworkError {
  return error instanceof Error && error.name === 'NetworkError';
}

export function isDatabaseError(error: unknown): error is DatabaseError {
  return error instanceof Error && error.name === 'DatabaseError';
}

export function isValidationError(error: unknown): error is ValidationError {
  return error instanceof Error && error.name === 'ValidationError';
}

// ===== 通用错误工厂函数 =====
export function createNetworkError(
  message: string,
  status?: number,
  statusText?: string
): NetworkError {
  const error = new Error(message) as NetworkError;
  error.name = 'NetworkError';
  error.status = status;
  error.statusText = statusText;
  return error;
}

export function createDatabaseError(
  message: string,
  query?: string,
  params?: unknown[]
): DatabaseError {
  const error = new Error(message) as DatabaseError;
  error.name = 'DatabaseError';
  error.query = query;
  error.params = params;
  return error;
}

export function createValidationError(
  message: string,
  field?: string,
  value?: unknown
): ValidationError {
  const error = new Error(message) as ValidationError;
  error.name = 'ValidationError';
  error.field = field;
  error.value = value;
  return error;
}
