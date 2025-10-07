import { NextRequest } from 'next/server';

import { getCacheTime, getConfig } from '@/lib/config';

export const runtime = 'nodejs';

export async function GET(_request: NextRequest) {
  try {
    const config = await getConfig();
    const sources = config.SourceConfig || [];

    const cacheTime = await getCacheTime();

    return new Response(JSON.stringify(sources), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': `public, max-age=${cacheTime}, s-maxage=0`, // 使用配置的缓存时间
      },
    });
  } catch (error) {
    // Error handling for source fetching
    return new Response(JSON.stringify([]), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
}
