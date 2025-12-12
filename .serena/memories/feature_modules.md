# MoonTV 功能模块

**记忆类型**: 功能模块  
**创建时间**: 2025-12-12  
**最后更新**: 2025-12-12  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 技术架构, 项目概览, 开发规范  
**语义标签**: 功能模块, API 接口, 组件库, 业务逻辑  
**索引关键词**: 搜索功能, 播放器, 用户系统, 管理面板, TVBox, 豆瓣集成

## 概述

MoonTV 项目的功能模块详细说明，包括各模块的业务逻辑、API 接口、组件设计和实现细节，提供完整的功能架构视图。

## 功能架构总览

### 核心功能模块

```
┌─────────────────────────────────────────────────────────────┐
│                    用户界面层                               │
│   ├── 搜索模块       ├── 播放模块       ├── 用户模块       │
│   └── 管理模块       └── TVBox模块      └── 豆瓣模块       │
├─────────────────────────────────────────────────────────────┤
│                    业务逻辑层                               │
│   ├── 搜索服务       ├── 播放服务       ├── 用户服务       │
│   └── 数据服务       └── 配置服务       └── 缓存服务       │
├─────────────────────────────────────────────────────────────┤
│                    数据访问层                               │
│       存储抽象接口 (LocalStorage/Redis/Upstash/D1)          │
└─────────────────────────────────────────────────────────────┘
```

### 模块依赖关系

```
搜索模块 → 播放模块 → 用户模块
    ↓          ↓          ↓
配置服务   数据服务   认证服务
    ↓          ↓          ↓
          存储抽象层
```

## 搜索模块

### 功能描述

多源视频搜索功能，支持批量搜索、单源搜索、搜索建议和实时搜索。

### 核心特性

- **多源并行搜索**: 同时搜索多个视频源
- **智能排序**: 根据相关性和质量排序结果
- **搜索建议**: 输入时提供搜索建议
- **结果缓存**: 搜索结果缓存提高性能
- **分页支持**: 支持搜索结果分页加载

### API 接口

#### 批量搜索

```
GET /api/search/batch
参数: keyword, page, size, sources[]
返回: 统一格式的搜索结果列表
```

#### 单源搜索

```
GET /api/search/single
参数: keyword, page, size, source
返回: 指定源的搜索结果
```

#### 搜索建议

```
GET /api/search/suggest
参数: keyword
返回: 搜索建议列表
```

#### WebSocket 实时搜索

```
WS /api/search/ws
消息: { type: "search", keyword: "电影" }
返回: 实时搜索结果流
```

### 组件设计

#### SearchPage 组件

```typescript
// 搜索页面主组件
interface SearchPageProps {
  initialKeyword?: string;
  initialResults?: SearchResult[];
}

const SearchPage: React.FC<SearchPageProps> = ({
  initialKeyword = '',
  initialResults = [],
}) => {
  const [keyword, setKeyword] = useState(initialKeyword);
  const [results, setResults] = useState(initialResults);
  const [loading, setLoading] = useState(false);

  const handleSearch = async (searchKeyword: string) => {
    setLoading(true);
    try {
      const data = await searchAPI.batchSearch(searchKeyword);
      setResults(data.results);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className='search-container'>
      <SearchBar
        keyword={keyword}
        onChange={setKeyword}
        onSearch={handleSearch}
      />
      <SearchSuggestions keyword={keyword} />
      {loading ? <LoadingSpinner /> : <SearchResults results={results} />}
    </div>
  );
};
```

#### SearchResults 组件

```typescript
// 搜索结果展示组件
interface SearchResultsProps {
  results: SearchResult[];
  onSelect?: (result: SearchResult) => void;
}

const SearchResults: React.FC<SearchResultsProps> = ({ results, onSelect }) => {
  return (
    <div className='results-grid'>
      {results.map((result) => (
        <VideoCard
          key={`${result.source}-${result.id}`}
          video={result}
          onClick={() => onSelect?.(result)}
        />
      ))}
    </div>
  );
};
```

### 业务逻辑

#### 搜索服务

```typescript
class SearchService {
  // 并行搜索多个源
  async batchSearch(
    keyword: string,
    sources?: string[]
  ): Promise<SearchResult[]> {
    const activeSources = sources || this.getActiveSources();
    const promises = activeSources.map((source) =>
      this.searchSingleSource(keyword, source)
    );

    const results = await Promise.allSettled(promises);
    return this.mergeAndSortResults(results);
  }

  // 搜索单个源
  private async searchSingleSource(
    keyword: string,
    source: string
  ): Promise<SearchResult[]> {
    const cacheKey = `search:${source}:${keyword}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const api = this.getSourceAPI(source);
    const results = await api.search(keyword);
    await cache.set(cacheKey, results, { ttl: 3600 }); // 缓存1小时
    return results;
  }

  // 合并和排序结果
  private mergeAndSortResults(
    results: PromiseSettledResult<SearchResult[]>[]
  ): SearchResult[] {
    // 实现结果去重、排序逻辑
  }
}
```

## 播放模块

### 功能描述

视频播放功能，支持多种播放器、播放记录、收藏功能和弹幕支持。

### 核心特性

- **多播放器支持**: ArtPlayer, Vidstack, 原生 video
- **播放记录**: 自动记录播放进度，多端同步
- **收藏功能**: 用户收藏喜欢的视频
- **弹幕集成**: 支持弹幕显示和发送
- **播放列表**: 创建和管理播放列表
- **画质选择**: 支持多种清晰度选择

### API 接口

#### 获取播放详情

```
GET /api/detail/{videoId}
参数: source, id
返回: 视频详情信息，包括剧集列表
```

#### 更新播放记录

```
POST /api/playrecord
参数: videoId, progress, duration, source
返回: 更新结果
```

#### 获取弹幕

```
GET /api/danmu/{videoId}
参数: time (时间点)
返回: 该时间点的弹幕列表
```

#### 发送弹幕

```
POST /api/danmu
参数: videoId, content, time, color
返回: 发送结果
```

### 组件设计

#### VideoPlayer 组件

```typescript
// 视频播放器组件
interface VideoPlayerProps {
  video: VideoDetail;
  episode?: Episode;
  autoplay?: boolean;
  onProgress?: (progress: number) => void;
  onEnded?: () => void;
}

const VideoPlayer: React.FC<VideoPlayerProps> = ({
  video,
  episode,
  autoplay = false,
  onProgress,
  onEnded,
}) => {
  const [player, setPlayer] = useState<Artplayer | null>(null);
  const [progress, setProgress] = useState(0);

  // 初始化播放器
  useEffect(() => {
    const art = new Artplayer({
      container: '.player-container',
      url: episode?.url || video.url,
      autoplay,
      volume: 0.7,
      // 其他配置...
    });

    art.on('video:timeupdate', () => {
      const current = art.currentTime;
      const duration = art.duration;
      const progress = duration > 0 ? current / duration : 0;
      setProgress(progress);
      onProgress?.(progress);
    });

    art.on('video:ended', () => {
      onEnded?.();
    });

    setPlayer(art);

    return () => {
      art.destroy();
    };
  }, [video, episode]);

  return <div className='player-container' />;
};
```

#### EpisodeSelector 组件

```typescript
// 剧集选择器组件
interface EpisodeSelectorProps {
  episodes: Episode[];
  currentEpisode?: Episode;
  onSelect: (episode: Episode) => void;
  groupBy?: 'source' | 'quality';
}

const EpisodeSelector: React.FC<EpisodeSelectorProps> = ({
  episodes,
  currentEpisode,
  onSelect,
  groupBy = 'source',
}) => {
  const groupedEpisodes = groupEpisodes(episodes, groupBy);

  return (
    <div className='episode-selector'>
      {Object.entries(groupedEpisodes).map(([group, groupEpisodes]) => (
        <div key={group} className='episode-group'>
          <h4>{group}</h4>
          <div className='episode-buttons'>
            {groupEpisodes.map((episode) => (
              <button
                key={episode.id}
                className={clsx('episode-btn', {
                  active: episode.id === currentEpisode?.id,
                })}
                onClick={() => onSelect(episode)}
              >
                {episode.title}
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
};
```

### 业务逻辑

#### 播放记录服务

```typescript
class PlayRecordService {
  // 保存播放记录
  async savePlayRecord(
    userId: string,
    videoId: string,
    progress: number,
    duration: number
  ): Promise<void> {
    const record: PlayRecord = {
      videoId,
      progress,
      duration,
      lastPlayed: new Date(),
      percentage: duration > 0 ? progress / duration : 0,
    };

    await storage.setPlayRecord(userId, videoId, record);

    // 触发同步到其他设备
    this.syncToOtherDevices(userId, videoId, record);
  }

  // 获取播放记录
  async getPlayRecord(
    userId: string,
    videoId: string
  ): Promise<PlayRecord | null> {
    return await storage.getPlayRecord(userId, videoId);
  }

  // 继续观看列表
  async getContinueWatching(userId: string): Promise<Video[]> {
    const records = await storage.getAllPlayRecords(userId);
    const recentRecords = Object.values(records)
      .sort((a, b) => b.lastPlayed.getTime() - a.lastPlayed.getTime())
      .slice(0, 20);

    // 获取视频详情
    return await Promise.all(
      recentRecords.map((record) => this.getVideoDetail(record.videoId))
    );
  }
}
```

## 用户模块

### 功能描述

用户认证、个人信息管理、收藏和播放记录同步功能。

### 核心特性

- **用户认证**: 注册、登录、退出
- **个人信息**: 个人资料管理
- **收藏管理**: 视频收藏和分类
- **播放记录**: 多端播放记录同步
- **偏好设置**: 个性化设置保存

### API 接口

#### 用户注册

```
POST /api/register
参数: username, password, email (可选)
返回: 注册结果
```

#### 用户登录

```
POST /api/login
参数: username, password
返回: 用户信息和认证token
```

#### 获取用户信息

```
GET /api/user/profile
Headers: Authorization: Bearer {token}
返回: 用户个人信息
```

#### 更新用户信息

```
PUT /api/user/profile
Headers: Authorization: Bearer {token}
参数: email, avatar, preferences
返回: 更新结果
```

#### 获取收藏列表

```
GET /api/user/favorites
Headers: Authorization: Bearer {token}
返回: 用户收藏列表
```

#### 添加收藏

```
POST /api/user/favorites
Headers: Authorization: Bearer {token}
参数: videoId, category
返回: 添加结果
```

### 组件设计

#### LoginForm 组件

```typescript
// 登录表单组件
interface LoginFormProps {
  onSuccess?: (user: User) => void;
  onRegisterClick?: () => void;
}

const LoginForm: React.FC<LoginFormProps> = ({
  onSuccess,
  onRegisterClick,
}) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const user = await authAPI.login(username, password);
      onSuccess?.(user);
    } catch (err) {
      setError(err instanceof Error ? err.message : '登录失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className='login-form'>
      <Input label='用户名' value={username} onChange={setUsername} required />
      <Input
        label='密码'
        type='password'
        value={password}
        onChange={setPassword}
        required
      />
      {error && <div className='error-message'>{error}</div>}
      <Button type='submit' disabled={loading}>
        {loading ? '登录中...' : '登录'}
      </Button>
      <Button type='button' variant='link' onClick={onRegisterClick}>
        注册账号
      </Button>
    </form>
  );
};
```

#### UserProfile 组件

```typescript
// 用户个人资料组件
interface UserProfileProps {
  user: User;
  onUpdate?: (user: Partial<User>) => Promise<void>;
}

const UserProfile: React.FC<UserProfileProps> = ({ user, onUpdate }) => {
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState({ ...user });

  const handleSave = async () => {
    try {
      await onUpdate?.(formData);
      setEditing(false);
    } catch (error) {
      console.error('更新失败:', error);
    }
  };

  return (
    <div className='user-profile'>
      <div className='profile-header'>
        <Avatar src={user.avatar} size='large' />
        <div className='profile-info'>
          <h3>{user.username}</h3>
          <p>注册时间: {formatDate(user.createdAt)}</p>
        </div>
        <Button onClick={() => setEditing(!editing)}>
          {editing ? '取消' : '编辑'}
        </Button>
      </div>

      {editing ? (
        <div className='profile-edit'>
          <Input
            label='邮箱'
            value={formData.email || ''}
            onChange={(email) => setFormData({ ...formData, email })}
          />
          <Input
            label='头像URL'
            value={formData.avatar || ''}
            onChange={(avatar) => setFormData({ ...formData, avatar })}
          />
          <Button onClick={handleSave}>保存</Button>
        </div>
      ) : (
        <div className='profile-stats'>
          <StatItem label='收藏数量' value={user.favoriteCount || 0} />
          <StatItem label='观看记录' value={user.playRecordCount || 0} />
          <StatItem label='最近登录' value={formatDate(user.lastLogin)} />
        </div>
      )}
    </div>
  );
};
```

### 业务逻辑

#### 认证服务

```typescript
class AuthService {
  // 用户注册
  async register(
    username: string,
    password: string,
    email?: string
  ): Promise<User> {
    // 验证用户名是否已存在
    const exists = await storage.checkUserExist(username);
    if (exists) {
      throw new Error('用户名已存在');
    }

    // 密码哈希
    const hashedPassword = await bcrypt.hash(password, 10);

    // 创建用户
    const user: User = {
      id: generateId(),
      username,
      email,
      createdAt: new Date(),
      lastLogin: new Date(),
      role: 'user',
    };

    await storage.registerUser(username, hashedPassword);
    await storage.saveUserProfile(user);

    return user;
  }

  // 用户登录
  async login(
    username: string,
    password: string
  ): Promise<{ user: User; token: string }> {
    // 验证用户存在
    const exists = await storage.checkUserExist(username);
    if (!exists) {
      throw new Error('用户名或密码错误');
    }

    // 验证密码
    const valid = await storage.verifyUser(username, password);
    if (!valid) {
      throw new Error('用户名或密码错误');
    }

    // 获取用户信息
    const user = await storage.getUserProfile(username);
    if (!user) {
      throw new Error('用户信息获取失败');
    }

    // 更新最后登录时间
    user.lastLogin = new Date();
    await storage.saveUserProfile(user);

    // 生成认证token
    const token = this.generateToken(user);

    return { user, token };
  }

  // 生成JWT token
  private generateToken(user: User): string {
    const payload = {
      sub: user.id,
      username: user.username,
      role: user.role,
      exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60, // 7天过期
    };

    return jwt.sign(payload, process.env.JWT_SECRET!);
  }
}
```

## 管理模块

### 功能描述

管理员功能，包括用户管理、视频源管理、站点配置和系统监控。

### 核心特性

- **用户管理**: 查看和管理用户账户
- **视频源管理**: 添加、编辑、删除视频源
- **站点配置**: 系统配置管理
- **数据统计**: 系统使用统计
- **数据迁移**: 存储后端数据迁移工具

### API 接口

#### 获取用户列表

```
GET /api/admin/users
参数: page, size, search
Headers: Authorization: Bearer {admin_token}
返回: 用户列表和分页信息
```

#### 更新用户状态

```
PUT /api/admin/users/{userId}/status
参数: active (boolean)
Headers: Authorization: Bearer {admin_token}
返回: 更新结果
```

#### 获取视频源列表

```
GET /api/admin/sources
Headers: Authorization: Bearer {admin_token}
返回: 视频源配置列表
```

#### 添加视频源

```
POST /api/admin/sources
参数: name, url, type, config
Headers: Authorization: Bearer {admin_token}
返回: 添加结果
```

#### 获取系统统计

```
GET /api/admin/stats
Headers: Authorization: Bearer {admin_token}
返回: 系统统计数据
```

### 组件设计

#### AdminDashboard 组件

```typescript
// 管理面板主组件
const AdminDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<
    'users' | 'sources' | 'stats' | 'config'
  >('users');

  return (
    <div className='admin-dashboard'>
      <AdminSidebar activeTab={activeTab} onSelectTab={setActiveTab} />
      <div className='admin-content'>
        {activeTab === 'users' && <UserManagement />}
        {activeTab === 'sources' && <SourceManagement />}
        {activeTab === 'stats' && <SystemStats />}
        {activeTab === 'config' && <SiteConfig />}
      </div>
    </div>
  );
};
```

#### UserManagement 组件

```typescript
// 用户管理组件
const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({
    page: 1,
    size: 20,
    total: 0,
  });

  const loadUsers = async (page: number = 1) => {
    setLoading(true);
    try {
      const response = await adminAPI.getUsers(page, pagination.size);
      setUsers(response.users);
      setPagination({
        page,
        size: pagination.size,
        total: response.total,
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleUpdateStatus = async (userId: string, active: boolean) => {
    await adminAPI.updateUserStatus(userId, active);
    loadUsers(pagination.page); // 刷新当前页
  };

  return (
    <div className='user-management'>
      <h3>用户管理</h3>
      {loading ? (
        <LoadingSpinner />
      ) : (
        <>
          <UserTable users={users} onUpdateStatus={handleUpdateStatus} />
          <Pagination
            current={pagination.page}
            total={pagination.total}
            pageSize={pagination.size}
            onChange={loadUsers}
          />
        </>
      )}
    </div>
  );
};
```

### 业务逻辑

#### 管理员服务

```typescript
class AdminService {
  // 验证管理员权限
  async verifyAdmin(userId: string): Promise<boolean> {
    const user = await storage.getUserProfileById(userId);
    return user?.role === 'admin';
  }

  // 获取用户列表
  async getUsers(
    page: number,
    size: number,
    search?: string
  ): Promise<{
    users: User[];
    total: number;
  }> {
    const allUsers = await storage.getAllUsers();

    // 搜索过滤
    let filteredUsers = allUsers;
    if (search) {
      filteredUsers = allUsers.filter(
        (user) =>
          user.username.toLowerCase().includes(search.toLowerCase()) ||
          user.email?.toLowerCase().includes(search.toLowerCase())
      );
    }

    // 分页
    const start = (page - 1) * size;
    const end = start + size;
    const paginatedUsers = filteredUsers.slice(start, end);

    return {
      users: paginatedUsers,
      total: filteredUsers.length,
    };
  }

  // 获取系统统计
  async getSystemStats(): Promise<SystemStats> {
    const users = await storage.getAllUsers();
    const playRecords = await storage.getAllPlayRecords();
    const favorites = await storage.getAllFavorites();

    // 计算各种统计
    const totalPlayTime = Object.values(playRecords).reduce((sum, records) => {
      const recordTimes = Object.values(records)
        .map((record) => record.progress)
        .reduce((s, p) => s + p, 0);
      return sum + recordTimes;
    }, 0);

    return {
      totalUsers: users.length,
      activeUsers: users.filter(
        (u) => u.lastLogin > new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      ).length,
      totalPlayRecords: Object.values(playRecords).reduce(
        (sum, records) => sum + Object.keys(records).length,
        0
      ),
      totalFavorites: Object.values(favorites).reduce(
        (sum, favs) => sum + Object.keys(favs).length,
        0
      ),
      totalPlayTime,
      storageUsage: await this.calculateStorageUsage(),
    };
  }
}
```

## TVBox 模块

### 功能描述

TVBox 播放器生态集成，提供 TVBox 配置生成和 API 接口。

### 核心特性

- **配置生成**: 自动生成 TVBox 配置
- **API 接口**: TVBox 标准 API 接口
- **密码保护**: TVBox 接口访问控制
- **多源支持**: 支持多个视频源配置
- **实时更新**: 配置实时更新机制

### API 接口

#### 获取 TVBox 配置

```
GET /api/tvbox/config
参数: password (TVBox接口密码)
返回: TVBox配置JSON
```

#### 获取分类列表

```
GET /api/tvbox/category
参数: password
返回: 视频分类列表
```

#### 获取视频列表

```
GET /api/tvbox/videos
参数: category, page, password
返回: 视频列表
```

#### 搜索视频

```
GET /api/tvbox/search
参数: keyword, page, password
返回: 搜索结果
```

### 组件设计

#### TVBoxConfigGenerator 组件

```typescript
// TVBox配置生成器组件
const TVBoxConfigGenerator: React.FC = () => {
  const [config, setConfig] = useState<TVBoxConfig | null>(null);
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const generateConfig = async () => {
    setLoading(true);
    try {
      const newConfig = await tvboxAPI.generateConfig(password);
      setConfig(newConfig);
    } finally {
      setLoading(false);
    }
  };

  const configUrl = config
    ? `${window.location.origin}/api/tvbox/config?password=${encodeURIComponent(
        password
      )}`
    : '';

  return (
    <div className='tvbox-config'>
      <h3>TVBox配置生成</h3>
      <Input
        label='TVBox接口密码'
        type='password'
        value={password}
        onChange={setPassword}
        placeholder='输入TVBox接口密码'
      />
      <Button onClick={generateConfig} disabled={!password || loading}>
        {loading ? '生成中...' : '生成配置'}
      </Button>

      {configUrl && (
        <div className='config-result'>
          <h4>配置地址:</h4>
          <code className='config-url'>{configUrl}</code>
          <p>将此地址复制到TVBox应用的配置地址中</p>
          <Button
            variant='outline'
            onClick={() => navigator.clipboard.writeText(configUrl)}
          >
            复制地址
          </Button>
        </div>
      )}
    </div>
  );
};
```

### 业务逻辑

#### TVBox 服务

```typescript
class TVBoxService {
  // 生成TVBox配置
  async generateConfig(password?: string): Promise<TVBoxConfig> {
    // 验证密码
    if (!this.verifyPassword(password)) {
      throw new Error('TVBox接口密码错误');
    }

    const sources = await this.getEnabledSources();
    const categories = await this.getAllCategories();

    const config: TVBoxConfig = {
      sites: sources.map((source) => ({
        key: source.id,
        name: source.name,
        api: `${this.getBaseUrl()}/api/tvbox`,
        searchable: source.searchable,
        quickSearch: source.quickSearch,
        filterable: source.filterable,
      })),
      config: {
        videoConfig: {
          isHW: true,
          isLive: false,
          decode: '硬解',
        },
        uiConfig: {
          showSourceName: true,
          showEpisodeTitle: true,
        },
      },
      categories: categories.map((cat) => ({
        type_id: cat.id,
        type_name: cat.name,
      })),
    };

    return config;
  }

  // 获取视频列表 (TVBox格式)
  async getVideos(
    category: string,
    page: number,
    password?: string
  ): Promise<TVBoxVideoList> {
    if (!this.verifyPassword(password)) {
      throw new Error('TVBox接口密码错误');
    }

    // 转换内部数据结构为TVBox格式
    const videos = await this.getVideosByCategory(category, page);

    return {
      list: videos.map((video) => ({
        vod_id: video.id,
        vod_name: video.title,
        vod_pic: video.poster,
        vod_remarks: video.remark,
        vod_year: video.year,
        vod_area: video.area,
        vod_actor: video.actors?.join(','),
        vod_director: video.director,
        vod_content: video.description,
        type_name: video.category,
      })),
      total: videos.length,
      page,
      pagecount: Math.ceil(videos.length / 20),
    };
  }

  // 搜索视频 (TVBox格式)
  async searchVideos(
    keyword: string,
    page: number,
    password?: string
  ): Promise<TVBoxVideoList> {
    if (!this.verifyPassword(password)) {
      throw new Error('TVBox接口密码错误');
    }

    const results = await searchService.batchSearch(keyword);

    return {
      list: results.map((video) => ({
        vod_id: video.id,
        vod_name: video.title,
        vod_pic: video.poster,
        vod_remarks: video.source,
        type_name: video.category,
      })),
      total: results.length,
      page,
      pagecount: Math.ceil(results.length / 20),
    };
  }
}
```

## 豆瓣集成模块

### 功能描述

豆瓣电影数据集成，提供影片信息、评分、演员信息和图片代理。

### 核心特性

- **影片信息**: 获取豆瓣影片详细信息
- **评分显示**: 显示豆瓣评分和评价人数
- **演员信息**: 影片演员和导演信息
- **图片代理**: 豆瓣图片代理服务
- **数据缓存**: 豆瓣数据缓存机制

### API 接口

#### 搜索豆瓣影片

```
GET /api/douban/search
参数: keyword
返回: 豆瓣搜索结果
```

#### 获取影片详情

```
GET /api/douban/subject/{id}
参数: id (豆瓣ID)
返回: 影片详细信息
```

#### 图片代理

```
GET /api/image-proxy
参数: url (原始图片URL)
返回: 代理后的图片数据
```

### 组件设计

#### DoubanInfo 组件

```typescript
// 豆瓣信息展示组件
interface DoubanInfoProps {
  doubanId?: string;
  title?: string;
}

const DoubanInfo: React.FC<DoubanInfoProps> = ({ doubanId, title }) => {
  const [info, setInfo] = useState<DoubanSubject | null>(null);
  const [loading, setLoading] = useState(false);

  const loadInfo = async () => {
    if (!doubanId && !title) return;

    setLoading(true);
    try {
      let subject: DoubanSubject;

      if (doubanId) {
        subject = await doubanAPI.getSubject(doubanId);
      } else if (title) {
        const searchResults = await doubanAPI.search(title);
        if (searchResults.length > 0) {
          subject = await doubanAPI.getSubject(searchResults[0].id);
        }
      }

      setInfo(subject!);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadInfo();
  }, [doubanId, title]);

  if (loading) return <LoadingSpinner />;
  if (!info) return null;

  return (
    <div className='douban-info'>
      <div className='douban-header'>
        <img
          src={`/api/image-proxy?url=${encodeURIComponent(info.image)}`}
          alt={info.title}
          className='douban-poster'
        />
        <div className='douban-meta'>
          <h3>
            {info.title} ({info.year})
          </h3>
          <div className='douban-rating'>
            <span className='rating-star'>★</span>
            <span className='rating-score'>
              {info.rating?.average || 'N/A'}
            </span>
            <span className='rating-count'>
              ({info.rating?.numRaters || 0}人评价)
            </span>
          </div>
          <p className='douban-genres'>{info.genres?.join(' / ')}</p>
          <p className='douban-directors'>
            导演: {info.directors?.map((d) => d.name).join('、')}
          </p>
          <p className='douban-casts'>
            主演:{' '}
            {info.casts
              ?.slice(0, 5)
              .map((c) => c.name)
              .join('、')}
          </p>
        </div>
      </div>
      <div className='douban-summary'>
        <h4>剧情简介</h4>
        <p>{info.summary}</p>
      </div>
    </div>
  );
};
```

### 业务逻辑

#### 豆瓣服务

```typescript
class DoubanService {
  // 代理类型配置
  private proxyType: 'none' | 'custom' | 'proxy' | 'imgproxy';
  private customProxyUrl?: string;

  constructor() {
    this.proxyType =
      (process.env.NEXT_PUBLIC_DOUBAN_PROXY_TYPE as any) || 'none';
    this.customProxyUrl = process.env.NEXT_PUBLIC_DOUBAN_PROXY;
  }

  // 搜索豆瓣影片
  async search(keyword: string): Promise<DoubanSearchResult[]> {
    const cacheKey = `douban:search:${keyword}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const url = this.buildUrl(
      `https://api.douban.com/v2/movie/search?q=${encodeURIComponent(keyword)}`
    );
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`豆瓣搜索失败: ${response.status}`);
    }

    const data = await response.json();
    const results: DoubanSearchResult[] =
      data.subjects?.map((subject: any) => ({
        id: subject.id,
        title: subject.title,
        originalTitle: subject.original_title,
        year: subject.year,
        image: subject.images?.medium,
        rating: subject.rating,
      })) || [];

    await cache.set(cacheKey, results, { ttl: 3600 * 24 }); // 缓存24小时
    return results;
  }

  // 获取影片详情
  async getSubject(id: string): Promise<DoubanSubject> {
    const cacheKey = `douban:subject:${id}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const url = this.buildUrl(`https://api.douban.com/v2/movie/subject/${id}`);
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`获取豆瓣详情失败: ${response.status}`);
    }

    const data = await response.json();
    const subject: DoubanSubject = {
      id: data.id,
      title: data.title,
      originalTitle: data.original_title,
      year: data.year,
      image: data.images?.large,
      summary: data.summary,
      rating: data.rating,
      genres: data.genres,
      countries: data.countries,
      directors: data.directors?.map((d: any) => ({ id: d.id, name: d.name })),
      casts: data.casts?.map((c: any) => ({
        id: c.id,
        name: c.name,
        avatar: c.avatars?.large,
      })),
      aka: data.aka,
    };

    await cache.set(cacheKey, subject, { ttl: 3600 * 24 * 7 }); // 缓存7天
    return subject;
  }

  // 构建代理URL
  private buildUrl(originalUrl: string): string {
    switch (this.proxyType) {
      case 'custom':
        return `${this.customProxyUrl}?url=${encodeURIComponent(originalUrl)}`;
      case 'proxy':
        return `/api/douban/proxy?url=${encodeURIComponent(originalUrl)}`;
      case 'imgproxy':
        // 特殊处理图片代理
        return originalUrl;
      case 'none':
      default:
        return originalUrl;
    }
  }

  // 图片代理
  async proxyImage(imageUrl: string): Promise<Response> {
    const proxyType = process.env.NEXT_PUBLIC_DOUBAN_IMAGE_PROXY_TYPE || 'none';
    const customProxy = process.env.NEXT_PUBLIC_DOUBAN_IMAGE_PROXY;

    switch (proxyType) {
      case 'custom':
        return fetch(`${customProxy}?url=${encodeURIComponent(imageUrl)}`);
      case 'proxy':
        return fetch(`/api/image-proxy?url=${encodeURIComponent(imageUrl)}`);
      case 'imgproxy':
        // 使用imgproxy服务
        const encodedUrl = Buffer.from(imageUrl)
          .toString('base64')
          .replace(/=/g, '')
          .replace(/\+/g, '-')
          .replace(/\//g, '_');
        return fetch(`${customProxy}/${encodedUrl}`);
      case 'none':
      default:
        return fetch(imageUrl);
    }
  }
}
```

## 模块集成和协作

### 模块间通信

#### 事件总线

```typescript
// 全局事件总线，用于模块间松耦合通信
class EventBus {
  private listeners: Map<string, Function[]> = new Map();

  on(event: string, callback: Function): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);

    // 返回取消监听函数
    return () => this.off(event, callback);
  }

  off(event: string, callback: Function): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  emit(event: string, data?: any): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.forEach((callback) => callback(data));
    }
  }
}

// 全局事件定义
export const Events = {
  // 用户相关
  USER_LOGIN: 'user:login',
  USER_LOGOUT: 'user:logout',
  USER_UPDATED: 'user:updated',

  // 播放相关
  VIDEO_PLAY: 'video:play',
  VIDEO_PAUSE: 'video:pause',
  VIDEO_ENDED: 'video:ended',
  PLAY_PROGRESS: 'play:progress',

  // 搜索相关
  SEARCH_START: 'search:start',
  SEARCH_COMPLETE: 'search:complete',

  // 系统相关
  THEME_CHANGED: 'theme:changed',
  LANGUAGE_CHANGED: 'language:changed',
};
```

#### 状态共享

```typescript
// 全局状态管理，用于模块间状态共享
interface GlobalState {
  user: User | null;
  theme: 'light' | 'dark';
  language: string;
  player: {
    currentVideo: VideoDetail | null;
    playing: boolean;
    fullscreen: boolean;
  };
  search: {
    history: string[];
    suggestions: string[];
  };
}

class GlobalStore {
  private state: GlobalState;
  private listeners: Set<(state: GlobalState) => void> = new Set();

  constructor() {
    this.state = this.getInitialState();
  }

  private getInitialState(): GlobalState {
    return {
      user: null,
      theme: 'light',
      language: 'zh-CN',
      player: {
        currentVideo: null,
        playing: false,
        fullscreen: false,
      },
      search: {
        history: [],
        suggestions: [],
      },
    };
  }

  getState(): GlobalState {
    return { ...this.state };
  }

  setState(updater: (state: GlobalState) => GlobalState): void {
    const newState = updater(this.state);
    this.state = newState;
    this.notifyListeners();
  }

  subscribe(listener: (state: GlobalState) => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private notifyListeners(): void {
    this.listeners.forEach((listener) => listener(this.state));
  }
}
```

### 模块初始化顺序

```typescript
// 应用启动时的模块初始化顺序
async function initializeApp() {
  // 1. 初始化配置模块
  await configService.initialize();

  // 2. 初始化存储模块
  await storageService.initialize();

  // 3. 初始化用户模块（自动登录）
  await authService.initialize();

  // 4. 初始化搜索模块（预加载源配置）
  await searchService.initialize();

  // 5. 初始化播放模块
  await playerService.initialize();

  // 6. 初始化TVBox模块（如果启用）
  if (configService.get('TVBOX_ENABLED')) {
    await tvboxService.initialize();
  }

  // 7. 初始化豆瓣模块（如果配置了代理）
  if (configService.get('DOUBAN_PROXY_TYPE') !== 'none') {
    await doubanService.initialize();
  }

  // 8. 事件总线初始化
  eventBus.initialize();

  console.log('所有模块初始化完成');
}
```

## 扩展和定制

### 添加新视频源

#### 步骤指南

1. **创建源配置**

   ```typescript
   // src/lib/sources/my-source.ts
   export interface MySourceConfig {
     apiUrl: string;
     apiKey?: string;
     categories: string[];
   }

   export class MySource implements VideoSource {
     constructor(private config: MySourceConfig) {}

     async search(keyword: string): Promise<Video[]> {
       // 实现搜索逻辑
     }

     async getDetail(id: string): Promise<VideoDetail> {
       // 实现详情获取逻辑
     }
   }
   ```

2. **注册源到系统**

   ```typescript
   // src/lib/sources/index.ts
   import { MySource } from './my-source';

   export function registerSources() {
     sourceRegistry.register('my-source', (config) => new MySource(config));
   }
   ```

3. **添加源配置**
   ```json
   // config.json 或通过管理面板添加
   {
     "id": "my-source",
     "name": "我的视频源",
     "type": "my-source",
     "config": {
       "apiUrl": "https://api.example.com",
       "categories": ["movie", "tv"]
     },
     "enabled": true
   }
   ```

### 自定义播放器

#### 实现自定义播放器

```typescript
// src/components/players/CustomPlayer.tsx
interface CustomPlayerProps extends PlayerProps {
  customConfig?: any;
}

const CustomPlayer: React.FC<CustomPlayerProps> = ({
  video,
  episode,
  customConfig,
  ...props
}) => {
  // 实现自定义播放器逻辑
  return <div className='custom-player'>自定义播放器实现</div>;
};

// 注册到播放器管理器
playerManager.register('custom', CustomPlayer);
```

### 添加新功能模块

#### 模块模板

```typescript
// src/modules/new-feature/
// ├── index.ts              # 模块出口
// ├── types.ts             # 类型定义
// ├── api.ts              # API接口
// ├── components/         # React组件
// ├── services/          # 业务逻辑
// └── utils.ts           # 工具函数
```

## 性能优化

### 模块懒加载

```typescript
// 使用React.lazy实现组件懒加载
const TVBoxModule = React.lazy(() => import('@/modules/tvbox'));
const AdminModule = React.lazy(() => import('@/modules/admin'));

// 路由配置中使用
const routes = [
  {
    path: '/tvbox',
    component: TVBoxModule,
    lazy: true,
  },
  {
    path: '/admin',
    component: AdminModule,
    lazy: true,
    auth: 'admin',
  },
];
```

### 数据预加载

```typescript
// 关键数据预加载
async function prefetchCriticalData() {
  // 预加载用户信息（如果已登录）
  if (authService.isLoggedIn()) {
    await authService.getProfile();
  }

  // 预加载配置
  await configService.loadConfig();

  // 预加载搜索源
  await searchService.prefetchSources();
}
```

### 缓存策略

```typescript
// 模块级缓存管理
class ModuleCache {
  private cache = new Map<string, { data: any; expiry: number }>();

  set(key: string, data: any, ttl: number = 300000): void {
    this.cache.set(key, {
      data,
      expiry: Date.now() + ttl,
    });
  }

  get(key: string): any | null {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }

    return item.data;
  }
}
```

## 故障排除

### 模块常见问题

#### 搜索模块无结果

1. 检查视频源配置是否正确
2. 验证网络连接和代理设置
3. 检查视频源 API 是否可用
4. 查看搜索日志和错误信息

#### 播放模块无法播放

1. 检查视频 URL 是否有效
2. 验证播放器配置
3. 检查网络连接和 CDN
4. 查看浏览器控制台错误

#### 用户模块认证失败

1. 检查存储后端连接
2. 验证密码哈希算法
3. 检查 Cookie 和 Session 配置
4. 查看认证日志

#### TVBox 模块配置无效

1. 验证 TVBox 接口密码
2. 检查配置生成逻辑
3. 验证视频源是否启用
4. 查看 TVBox 兼容性

### 模块调试指南

```typescript
// 启用模块调试模式
const moduleDebug = {
  search: process.env.DEBUG_SEARCH === 'true',
  player: process.env.DEBUG_PLAYER === 'true',
  user: process.env.DEBUG_USER === 'true',
  tvbox: process.env.DEBUG_TVBOX === 'true',
};

// 调试日志
function debugLog(module: string, message: string, data?: any) {
  if (moduleDebug[module as keyof typeof moduleDebug]) {
    console.log(`[${module}] ${message}`, data || '');
  }
}
```

## 更新历史

- 2025-12-12: 创建功能模块记忆文件，基于项目记忆管理器新规则重构
- 2025-12-09: 优化搜索模块性能，添加结果缓存
- 2025-12-05: 升级播放模块，集成 Vidstack 播放器
- 2025-11-01: 完善用户模块，添加多端同步功能
- 2025-10-15: 实现管理模块，支持视频源管理
- 2025-10-01: 建立基础功能模块架构
