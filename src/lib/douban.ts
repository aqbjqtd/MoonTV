/**
 * 豆瓣API代理配置
 */
const DOUBAN_PROXIES = [
  'https://m.douban.cmliussss.net',
  'https://m.douban.cmliussss.com',
];

/**
 * 代理健康状态缓存
 */
const proxyHealthCache = new Map<
  string,
  { healthy: boolean; lastCheck: number }
>();

/**
 * 检测代理健康状态
 */
async function checkProxyHealth(proxy: string): Promise<boolean> {
  const cached = proxyHealthCache.get(proxy);
  const now = Date.now();

  // 缓存5分钟
  if (cached && now - cached.lastCheck < 300000) {
    return cached.healthy;
  }

  try {
    const response = await fetch(
      `${proxy}/rexxar/api/v2/subject/recent_hot/movie?start=0&limit=1`,
      {
        method: 'HEAD',
        signal: AbortSignal.timeout(5000), // 5秒超时
      }
    );

    const isHealthy = response.ok;
    proxyHealthCache.set(proxy, { healthy: isHealthy, lastCheck: now });
    return isHealthy;
  } catch (error) {
    proxyHealthCache.set(proxy, { healthy: false, lastCheck: now });
    return false;
  }
}

/**
 * 获取健康的代理URL
 */
async function getHealthyProxy(): Promise<string | null> {
  for (const proxy of DOUBAN_PROXIES) {
    if (await checkProxyHealth(proxy)) {
      return proxy;
    }
  }
  return null;
}

/**
 * 指数退避重试延迟
 */
function getRetryDelay(attempt: number): number {
  return Math.min(1000 * Math.pow(2, attempt), 10000); // 最大10秒
}

/**
 * 通用的豆瓣数据获取函数（增强版）
 * @param url 请求的URL
 * @param maxRetries 最大重试次数
 * @returns Promise<T> 返回指定类型的数据
 */
export async function fetchDoubanData<T>(
  url: string,
  maxRetries = 3
): Promise<T> {
  let lastError: Error | null = null;

  // 尝试直连豆瓣API
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      // eslint-disable-next-line no-console
      console.log(
        `[豆瓣API] 尝试直连 (${attempt + 1}/${maxRetries + 1}): ${url}`
      );

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      const fetchOptions = {
        signal: controller.signal,
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          Referer: 'https://movie.douban.com/',
          Accept: 'application/json, text/plain, */*',
          Origin: 'https://movie.douban.com',
        },
      };

      const response = await fetch(url, fetchOptions);
      clearTimeout(timeoutId);

      if (response.ok) {
        // eslint-disable-next-line no-console
        console.log(`[豆瓣API] 直连成功: ${url}`);
        return await response.json();
      } else {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
    } catch (error) {
      lastError = error as Error;
      // eslint-disable-next-line no-console
      console.warn(
        `[豆瓣API] 直连失败 (${attempt + 1}/${maxRetries + 1}):`,
        (error as Error).message
      );

      if (attempt < maxRetries) {
        const delay = getRetryDelay(attempt);
        // eslint-disable-next-line no-console
        console.log(`[豆瓣API] 等待 ${delay}ms 后重试...`);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  // 直连失败，尝试代理
  // eslint-disable-next-line no-console
  console.log('[豆瓣API] 直连失败，尝试代理...');
  const healthyProxy = await getHealthyProxy();

  if (healthyProxy) {
    const proxyUrl = url.replace('https://m.douban.com', healthyProxy);
    // eslint-disable-next-line no-console
    console.log(`[豆瓣API] 尝试代理: ${proxyUrl}`);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000); // 代理超时稍短

      const fetchOptions = {
        signal: controller.signal,
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          Referer: 'https://movie.douban.com/',
          Accept: 'application/json, text/plain, */*',
          Origin: 'https://movie.douban.com',
        },
      };

      const response = await fetch(proxyUrl, fetchOptions);
      clearTimeout(timeoutId);

      if (response.ok) {
        // eslint-disable-next-line no-console
        console.log(`[豆瓣API] 代理成功: ${proxyUrl}`);
        return await response.json();
      } else {
        throw new Error(`代理HTTP错误! Status: ${response.status}`);
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn(`[豆瓣API] 代理失败:`, (error as Error).message);
      lastError = error as Error;
    }
  }

  // 所有尝试都失败
  // eslint-disable-next-line no-console
  console.error('[豆瓣API] 所有连接方式都失败');
  throw lastError || new Error('豆瓣API连接失败');
}
