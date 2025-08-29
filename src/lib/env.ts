/* eslint-disable no-console */

import { z } from 'zod';

/**
 * 环境变量验证配置
 * 使用Zod进行运行时环境变量验证
 */

// 存储类型枚举
const StorageTypeSchema = z.enum(['localstorage', 'redis', 'upstash', 'd1']);

export type StorageType = z.infer<typeof StorageTypeSchema>;

// 环境变量完整模式
const envSchema = z.object({
  // 基础配置
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  
  // 应用配置
  NEXT_PUBLIC_STORAGE_TYPE: StorageTypeSchema.default('localstorage'),
  NEXT_PUBLIC_SEARCH_MAX_PAGE: z.coerce.number().min(1).max(20).default(5),
  NEXT_PUBLIC_SITE_NAME: z.string().min(1).default('MoonTV'),
  NEXT_PUBLIC_BASE_URL: z.string().url().default('http://localhost:3000'),
  
  // 安全配置
  PASSWORD: z.string().min(6).optional(),
  JWT_SECRET: z.string().min(32).optional(),
  
  // 数据库配置
  REDIS_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_TOKEN: z.string().optional(),
  
  // 外部服务配置
  DOUBAN_API_KEY: z.string().optional(),
  
  // 部署配置
  VERCEL_URL: z.string().optional(),
  VERCEL_ENV: z.enum(['production', 'preview', 'development']).optional(),
});

/**
 * 验证后的环境变量类型
 */
export type Env = z.infer<typeof envSchema>;

/**
 * 获取验证后的环境变量
 * @returns 验证通过的环境变量对象
 * @throws {Error} 环境变量验证失败时抛出
 */
export function getEnv(): Env {
  try {
    // 构建环境变量对象
    const rawEnv = {
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_STORAGE_TYPE: process.env.NEXT_PUBLIC_STORAGE_TYPE,
      NEXT_PUBLIC_SEARCH_MAX_PAGE: process.env.NEXT_PUBLIC_SEARCH_MAX_PAGE,
      NEXT_PUBLIC_SITE_NAME: process.env.NEXT_PUBLIC_SITE_NAME,
      NEXT_PUBLIC_BASE_URL: process.env.NEXT_PUBLIC_BASE_URL,
      PASSWORD: process.env.PASSWORD,
      JWT_SECRET: process.env.JWT_SECRET,
      REDIS_URL: process.env.REDIS_URL,
      UPSTASH_REDIS_REST_URL: process.env.UPSTASH_REDIS_REST_URL,
      UPSTASH_REDIS_REST_TOKEN: process.env.UPSTASH_REDIS_REST_TOKEN,
      DOUBAN_API_KEY: process.env.DOUBAN_API_KEY,
      VERCEL_URL: process.env.VERCEL_URL,
      VERCEL_ENV: process.env.VERCEL_ENV,
    };

    return envSchema.parse(rawEnv);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMessages = error.errors.map(err => 
        `${err.path.join('.')}: ${err.message}`
      );
      
      throw new Error(`环境变量验证失败:\n${errorMessages.join('\n')}`);
    }
    
    throw error;
  }
}

/**
 * 安全地获取环境变量，提供默认值
 * @returns 环境变量对象，包含合理的默认值
 */
export function getSafeEnv(): Env {
  try {
    return getEnv();
  } catch (error) {
    console.warn('环境变量验证失败，使用安全默认值:', (error as Error).message);
    
    // 返回安全的默认值
    return {
      NODE_ENV: 'development',
      NEXT_PUBLIC_STORAGE_TYPE: 'localstorage',
      NEXT_PUBLIC_SEARCH_MAX_PAGE: 5,
      NEXT_PUBLIC_SITE_NAME: 'MoonTV',
      NEXT_PUBLIC_BASE_URL: 'http://localhost:3000',
      // 其他字段为undefined
    } as Env;
  }
}

/**
 * 验证特定环境变量的有效性
 * @param key 环境变量键名
 * @param value 环境变量值
 * @returns 验证结果
 */
export function validateEnvVariable(key: keyof Env, value: unknown): {
  isValid: boolean;
  error?: string;
} {
  try {
    const fieldSchema = envSchema.shape[key];
    if (!fieldSchema) {
      return { isValid: false, error: `未知的环境变量: ${key}` };
    }

    fieldSchema.parse(value);
    return { isValid: true };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return { isValid: false, error: error.errors[0]?.message };
    }
    return { isValid: false, error: '验证失败' };
  }
}

/**
 * 检查必需的环境变量是否已设置
 * @returns 缺失的必需环境变量列表
 */
export function checkRequiredEnvVariables(): string[] {
  const missing: string[] = [];
  
  // 根据当前存储类型检查必需的变量
  const env = getSafeEnv();
  
  if (env.NEXT_PUBLIC_STORAGE_TYPE === 'redis' && !env.REDIS_URL) {
    missing.push('REDIS_URL');
  }
  
  if (env.NEXT_PUBLIC_STORAGE_TYPE === 'upstash') {
    if (!env.UPSTASH_REDIS_REST_URL) missing.push('UPSTASH_REDIS_REST_URL');
    if (!env.UPSTASH_REDIS_REST_TOKEN) missing.push('UPSTASH_REDIS_REST_TOKEN');
  }
  
  // 密码是必需的（用于认证）
  if (!env.PASSWORD) {
    missing.push('PASSWORD');
  }
  
  return missing;
}

/**
 * 获取环境相关的配置
 * @returns 环境特定的配置对象
 */
export function getEnvConfig() {
  const env = getSafeEnv();
  
  return {
    isProduction: env.NODE_ENV === 'production',
    isDevelopment: env.NODE_ENV === 'development',
    isTest: env.NODE_ENV === 'test',
    
    // 存储配置
    storageType: env.NEXT_PUBLIC_STORAGE_TYPE,
    requiresExternalStorage: ['redis', 'upstash', 'd1'].includes(env.NEXT_PUBLIC_STORAGE_TYPE),
    
    // 搜索配置
    searchMaxPage: env.NEXT_PUBLIC_SEARCH_MAX_PAGE,
    
    // 应用信息
    siteName: env.NEXT_PUBLIC_SITE_NAME,
    baseUrl: env.NEXT_PUBLIC_BASE_URL,
  };
}

/**
 * 环境变量验证中间件
 * 用于在应用启动时验证环境变量
 */
export function validateEnvironment(): void {
  try {
    const env = getEnv();
    const missing = checkRequiredEnvVariables();
    
    if (missing.length > 0) {
      console.warn(`⚠️  缺少必需的环境变量: ${missing.join(', ')}`);
      console.warn('某些功能可能无法正常工作');
    }
    
    console.log('✅ 环境变量验证通过');
    console.log(`  环境: ${env.NODE_ENV}`);
    console.log(`  存储类型: ${env.NEXT_PUBLIC_STORAGE_TYPE}`);
    
  } catch (error) {
    console.error('❌ 环境变量验证失败:', (error as Error).message);
    
    // 在开发环境下继续运行，生产环境下应该失败
    if (process.env.NODE_ENV === 'production') {
      throw new Error('环境变量配置错误，请检查.env文件');
    }
  }
}

// 应用启动时自动验证环境变量
if (typeof window === 'undefined') {
  validateEnvironment();
}