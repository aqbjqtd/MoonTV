/**
 * 存储相关类型定义
 * 用于替换存储操作中的 any 类型
 */

import { AdminConfig } from './admin.types';
import { Favorite, PlayRecord, SkipConfig } from './types';

// ===== 存储接口扩展方法定义 =====
export interface StorageMethods {
  // 播放记录相关
  getPlayRecord(userName: string, key: string): Promise<PlayRecord | null>;
  setPlayRecord(
    userName: string,
    key: string,
    record: PlayRecord
  ): Promise<void>;
  getAllPlayRecords(userName: string): Promise<Record<string, PlayRecord>>;
  deletePlayRecord(userName: string, key: string): Promise<void>;

  // 收藏相关
  getFavorite(userName: string, key: string): Promise<Favorite | null>;
  setFavorite(userName: string, key: string, favorite: Favorite): Promise<void>;
  getAllFavorites(userName: string): Promise<Record<string, Favorite>>;
  deleteFavorite(userName: string, key: string): Promise<void>;

  // 用户相关
  registerUser(userName: string, password: string): Promise<void>;
  verifyUser(userName: string, password: string): Promise<boolean>;
  checkUserExist(userName: string): Promise<boolean>;
  changePassword(userName: string, newPassword: string): Promise<void>;
  deleteUser(userName: string): Promise<void>;

  // 搜索历史相关
  getSearchHistory(userName: string): Promise<string[]>;
  addSearchHistory(userName: string, keyword: string): Promise<void>;
  deleteSearchHistory(userName: string, keyword?: string): Promise<void>;

  // 用户列表
  getAllUsers(): Promise<string[]>;

  // 管理员配置相关
  getAdminConfig(): Promise<AdminConfig | null>;
  setAdminConfig(config: AdminConfig): Promise<void>;

  // 跳过片头片尾配置相关
  getSkipConfig(
    userName: string,
    source: string,
    id: string
  ): Promise<SkipConfig | null>;
  setSkipConfig(
    userName: string,
    source: string,
    id: string,
    config: SkipConfig
  ): Promise<void>;
  deleteSkipConfig(userName: string, source: string, id: string): Promise<void>;
  getAllSkipConfigs(userName: string): Promise<Record<string, SkipConfig>>;

  // 数据清理
  clearAllData(): Promise<void>;
}

// ===== 动态存储接口类型 =====
export interface DynamicStorage extends StorageMethods {
  [key: string]: unknown;
}

// ===== 存储方法名称联合类型 =====
export type StorageMethodNames = keyof StorageMethods;

// ===== 存储方法参数类型映射 =====
export interface StorageMethodParameters {
  getAdminConfig: [];
  setAdminConfig: [config: AdminConfig];
  getAllUsers: [];
  checkUserExist: [userName: string];
  verifyUser: [userName: string, password: string];
  registerUser: [userName: string, password: string];
  changePassword: [userName: string, newPassword: string];
  deleteUser: [userName: string];
  getPlayRecord: [userName: string, key: string];
  setPlayRecord: [userName: string, key: string, record: PlayRecord];
  getAllPlayRecords: [userName: string];
  deletePlayRecord: [userName: string, key: string];
  getFavorite: [userName: string, key: string];
  setFavorite: [userName: string, key: string, favorite: Favorite];
  getAllFavorites: [userName: string];
  deleteFavorite: [userName: string, key: string];
  getSearchHistory: [userName: string];
  addSearchHistory: [userName: string, keyword: string];
  deleteSearchHistory: [userName: string, keyword?: string];
  getSkipConfig: [userName: string, source: string, id: string];
  setSkipConfig: [
    userName: string,
    source: string,
    id: string,
    config: SkipConfig
  ];
  deleteSkipConfig: [userName: string, source: string, id: string];
  getAllSkipConfigs: [userName: string];
  clearAllData: [];
}

// ===== 存储方法返回值类型映射 =====
export interface StorageMethodReturnTypes {
  getAdminConfig: Promise<AdminConfig | null>;
  setAdminConfig: Promise<void>;
  getAllUsers: Promise<string[]>;
  checkUserExist: Promise<boolean>;
  verifyUser: Promise<boolean>;
  registerUser: Promise<void>;
  changePassword: Promise<void>;
  deleteUser: Promise<void>;
  getPlayRecord: Promise<PlayRecord | null>;
  setPlayRecord: Promise<void>;
  getAllPlayRecords: Promise<Record<string, PlayRecord>>;
  deletePlayRecord: Promise<void>;
  getFavorite: Promise<Favorite | null>;
  setFavorite: Promise<void>;
  getAllFavorites: Promise<Record<string, Favorite>>;
  deleteFavorite: Promise<void>;
  getSearchHistory: Promise<string[]>;
  addSearchHistory: Promise<void>;
  deleteSearchHistory: Promise<void>;
  getSkipConfig: Promise<SkipConfig | null>;
  setSkipConfig: Promise<void>;
  deleteSkipConfig: Promise<void>;
  getAllSkipConfigs: Promise<Record<string, SkipConfig>>;
  clearAllData: Promise<void>;
}

// ===== 类型安全的存储方法调用器 =====
export function isStorageMethod(
  obj: unknown,
  methodName: string
): obj is DynamicStorage {
  return (
    obj != null &&
    typeof obj === 'object' &&
    methodName in obj &&
    typeof (obj as Record<string, unknown>)[methodName] === 'function'
  );
}

export function callStorageMethod<K extends StorageMethodNames>(
  storage: unknown,
  methodName: K,
  ...args: StorageMethodParameters[K]
): StorageMethodReturnTypes[K] {
  if (!isStorageMethod(storage, methodName)) {
    throw new Error(`Storage method ${methodName} is not available`);
  }

  const method = storage[methodName] as (...args: unknown[]) => unknown;
  return method(...args) as StorageMethodReturnTypes[K];
}

// ===== 存储包装器 =====
export class StorageWrapper {
  constructor(private storage: DynamicStorage) {}

  // 播放记录相关
  async getPlayRecord(
    userName: string,
    key: string
  ): Promise<PlayRecord | null> {
    return callStorageMethod(this.storage, 'getPlayRecord', userName, key);
  }

  async setPlayRecord(
    userName: string,
    key: string,
    record: PlayRecord
  ): Promise<void> {
    return callStorageMethod(
      this.storage,
      'setPlayRecord',
      userName,
      key,
      record
    );
  }

  async getAllPlayRecords(
    userName: string
  ): Promise<Record<string, PlayRecord>> {
    return callStorageMethod(this.storage, 'getAllPlayRecords', userName);
  }

  async deletePlayRecord(userName: string, key: string): Promise<void> {
    return callStorageMethod(this.storage, 'deletePlayRecord', userName, key);
  }

  // 用户相关
  async getAllUsers(): Promise<string[]> {
    return callStorageMethod(this.storage, 'getAllUsers');
  }

  async getAdminConfig(): Promise<AdminConfig | null> {
    return callStorageMethod(this.storage, 'getAdminConfig');
  }

  async setAdminConfig(config: AdminConfig): Promise<void> {
    return callStorageMethod(this.storage, 'setAdminConfig', config);
  }

  // 搜索历史相关
  async getSearchHistory(userName: string): Promise<string[]> {
    return callStorageMethod(this.storage, 'getSearchHistory', userName);
  }

  async addSearchHistory(userName: string, keyword: string): Promise<void> {
    return callStorageMethod(
      this.storage,
      'addSearchHistory',
      userName,
      keyword
    );
  }

  async deleteSearchHistory(userName: string, keyword?: string): Promise<void> {
    return callStorageMethod(
      this.storage,
      'deleteSearchHistory',
      userName,
      keyword
    );
  }
}
