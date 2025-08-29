/**
 * API响应类型定义
 * 标准化的API响应格式，确保前后端数据交互的一致性
 */

export interface ApiResponse<T = unknown> {
  /**
   * 状态码
   * - 200: 成功
   * - 400: 客户端错误
   * - 401: 未授权
   * - 403: 禁止访问
   * - 404: 资源不存在
   * - 500: 服务器错误
   */
  code: number;
  
  /**
   * 响应数据
   */
  data: T;
  
  /**
   * 响应消息
   */
  message: string;
  
  /**
   * 时间戳（毫秒）
   */
  timestamp?: number;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  /**
   * 分页信息
   */
  pagination: {
    /**
     * 当前页码（从1开始）
     */
    page: number;
    
    /**
     * 每页数量
     */
    limit: number;
    
    /**
     * 总记录数
     */
    total: number;
    
    /**
     * 是否有更多数据
     */
    hasMore: boolean;
  };
}

/**
 * 空数据响应
 */
export type EmptyResponse = ApiResponse<null>;

/**
 * 错误响应
 */
export interface ErrorResponse extends ApiResponse<null> {
  /**
   * 错误详情（开发环境）
   */
  details?: string;
  
  /**
   * 错误代码
   */
  errorCode?: string;
}

/**
 * 成功响应工具函数
 */
export function successResponse<T>(data: T, message = '成功'): ApiResponse<T> {
  return {
    code: 200,
    data,
    message,
    timestamp: Date.now(),
  };
}

/**
 * 分页成功响应工具函数
 */
export function paginatedResponse<T>(
  data: T[],
  pagination: Omit<PaginatedResponse<T>['pagination'], 'hasMore'>,
  message = '成功'
): PaginatedResponse<T> {
  const hasMore = pagination.page * pagination.limit < pagination.total;
  
  return {
    code: 200,
    data,
    message,
    timestamp: Date.now(),
    pagination: {
      ...pagination,
      hasMore,
    },
  };
}

/**
 * 错误响应工具函数
 */
export function errorResponse(
  code: number,
  message: string,
  options: {
    details?: string;
    errorCode?: string;
  } = {}
): ErrorResponse {
  return {
    code,
    data: null,
    message,
    timestamp: Date.now(),
    ...options,
  };
}

/**
 * 常见的错误响应
 */
export const CommonErrors = {
  /**
   * 未授权错误
   */
  unauthorized: (message = '未授权访问'): ErrorResponse =>
    errorResponse(401, message),

  /**
   * 禁止访问错误
   */
  forbidden: (message = '禁止访问'): ErrorResponse =>
    errorResponse(403, message),

  /**
   * 资源不存在错误
   */
  notFound: (message = '资源不存在'): ErrorResponse =>
    errorResponse(404, message),

  /**
   * 服务器错误
   */
  serverError: (message = '服务器内部错误'): ErrorResponse =>
    errorResponse(500, message, { errorCode: 'INTERNAL_SERVER_ERROR' }),

  /**
   * 参数验证错误
   */
  validationError: (message = '参数验证失败'): ErrorResponse =>
    errorResponse(400, message, { errorCode: 'VALIDATION_ERROR' }),
} as const;