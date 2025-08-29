import { AdminConfig } from './admin.types';

// 用户认证数据类型
export interface UserAuthData {
  /**
   * 用户名
   */
  username: string;
  
  /**
   * 签名（HMAC-SHA256）
   */
  signature: string;
  
  /**
   * 时间戳（毫秒）
   */
  timestamp: number;
  
  /**
   * 用户角色
   */
  role: 'owner' | 'admin' | 'user';
}

// 登录凭据
export interface LoginCredentials {
  /**
   * 用户名
   */
  username: string;
  
  /**
   * 密码
   */
  password: string;
}

// 认证响应
export interface AuthResponse {
  /**
   * 认证是否成功
   */
  success: boolean;
  
  /**
   * 认证令牌（JWT或签名）
   */
  token?: string;
  
  /**
   * 用户信息
   */
  user?: {
    username: string;
    role: 'owner' | 'admin' | 'user';
  };
  
  /**
   * 错误信息
   */
  error?: string;
  
  /**
   * 错误代码
   */
  errorCode?: string;
}

// 用户基本信息
export interface UserProfile {
  /**
   * 用户名
   */
  username: string;
  
  /**
   * 用户角色
   */
  role: 'owner' | 'admin' | 'user';
  
  /**
   * 创建时间
   */
  createdAt: number;
  
  /**
   * 最后登录时间
   */
  lastLoginAt?: number;
  
  /**
   * 播放记录数量
   */
  playRecordsCount: number;
  
  /**
   * 收藏数量
   */
  favoritesCount: number;
}

// 播放记录数据结构
export interface PlayRecord {
  /**
   * 标题
   */
  title: string;
  
  /**
   * 来源名称
   */
  source_name: string;
  
  /**
   * 封面图片URL
   */
  cover: string;
  
  /**
   * 年份
   */
  year: string;
  
  /**
   * 第几集
   */
  index: number;
  
  /**
   * 总集数
   */
  total_episodes: number;
  
  /**
   * 播放进度（秒）
   */
  play_time: number;
  
  /**
   * 总进度（秒）
   */
  total_time: number;
  
  /**
   * 记录保存时间（时间戳）
   */
  save_time: number;
  
  /**
   * 搜索时使用的标题
   */
  search_title: string;
  
  /**
   * 资源ID
   */
  resource_id?: string;
  
  /**
   * 剧集标题
   */
  episode_title?: string;
}

// 收藏数据结构
export interface Favorite {
  /**
   * 来源名称
   */
  source_name: string;
  
  /**
   * 总集数
   */
  total_episodes: number;
  
  /**
   * 标题
   */
  title: string;
  
  /**
   * 年份
   */
  year: string;
  
  /**
   * 封面图片URL
   */
  cover: string;
  
  /**
   * 记录保存时间（时间戳）
   */
  save_time: number;
  
  /**
   * 搜索时使用的标题
   */
  search_title: string;
  
  /**
   * 资源ID
   */
  resource_id?: string;
  
  /**
   * 豆瓣ID
   */
  douban_id?: number;
  
  /**
   * 评分
   */
  rating?: number;
}

// 存储接口
export interface IStorage {
  // 播放记录相关
  getPlayRecord(userName: string, key: string): Promise<PlayRecord | null>;
  setPlayRecord(
    userName: string,
    key: string,
    record: PlayRecord
  ): Promise<void>;
  getAllPlayRecords(userName: string): Promise<{ [key: string]: PlayRecord }>;
  deletePlayRecord(userName: string, key: string): Promise<void>;

  // 收藏相关
  getFavorite(userName: string, key: string): Promise<Favorite | null>;
  setFavorite(userName: string, key: string, favorite: Favorite): Promise<void>;
  getAllFavorites(userName: string): Promise<{ [key: string]: Favorite }>;
  deleteFavorite(userName: string, key: string): Promise<void>;

  // 用户相关
  registerUser(userName: string, password: string): Promise<void>;
  verifyUser(userName: string, password: string): Promise<boolean>;
  // 检查用户是否存在（无需密码）
  checkUserExist(userName: string): Promise<boolean>;
  // 修改用户密码
  changePassword(userName: string, newPassword: string): Promise<void>;
  // 删除用户（包括密码、搜索历史、播放记录、收藏夹）
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
  getAllSkipConfigs(userName: string): Promise<{ [key: string]: SkipConfig }>;
}

// 搜索结果数据结构
export interface SearchResult {
  /**
   * 资源唯一标识
   */
  id: string;
  
  /**
   * 标题
   */
  title: string;
  
  /**
   * 海报图片URL
   */
  poster: string;
  
  /**
   * 剧集列表（播放URL）
   */
  episodes: string[];
  
  /**
   * 剧集标题列表
   */
  episodes_titles: string[];
  
  /**
   * 来源标识
   */
  source: string;
  
  /**
   * 来源名称
   */
  source_name: string;
  
  /**
   * 分类
   */
  class?: string;
  
  /**
   * 年份
   */
  year: string;
  
  /**
   * 描述
   */
  desc?: string;
  
  /**
   * 类型名称
   */
  type_name?: string;
  
  /**
   * 豆瓣ID
   */
  douban_id?: number;
  
  /**
   * 评分
   */
  rating?: number;
  
  /**
   * 导演
   */
  director?: string;
  
  /**
   * 演员列表
   */
  actors?: string[];
  
  /**
   * 地区
   */
  region?: string;
  
  /**
   * 语言
   */
  language?: string;
  
  /**
   * 更新时间
   */
  update_time?: string;
}

// 豆瓣数据结构
export interface DoubanItem {
  /**
   * 豆瓣ID
   */
  id: string;
  
  /**
   * 标题
   */
  title: string;
  
  /**
   * 海报图片URL
   */
  poster: string;
  
  /**
   * 评分
   */
  rate: string;
  
  /**
   * 年份
   */
  year: string;
  
  /**
   * 导演
   */
  director?: string;
  
  /**
   * 主演
   */
  cast?: string[];
  
  /**
   * 类型
   */
  genre?: string[];
  
  /**
   * 简介
   */
  summary?: string;
  
  /**
   * 片长
   */
  duration?: string;
  
  /**
   * 制片国家/地区
   */
  country?: string;
}

export interface DoubanResult {
  /**
   * 状态码
   */
  code: number;
  
  /**
   * 消息
   */
  message: string;
  
  /**
   * 数据列表
   */
  list: DoubanItem[];
  
  /**
   * 总数量
   */
  total?: number;
  
  /**
   * 当前页码
   */
  page?: number;
  
  /**
   * 每页数量
   */
  limit?: number;
}

// 跳过片头片尾配置数据结构
export interface SkipConfig {
  /**
   * 是否启用跳过片头片尾
   */
  enable: boolean;
  
  /**
   * 片头时间（秒）
   */
  intro_time: number;
  
  /**
   * 片尾时间（秒）
   */
  outro_time: number;
  
  /**
   * 配置创建时间
   */
  created_at?: number;
  
  /**
   * 配置更新时间
   */
  updated_at?: number;
}
