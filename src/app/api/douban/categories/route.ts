import { NextResponse } from 'next/server';

import { getCacheTime } from '@/lib/config';
import { fetchDoubanData } from '@/lib/douban';
import { DoubanItem, DoubanResult } from '@/lib/types';

interface DoubanCategoryApiResponse {
  total: number;
  items: Array<{
    id: string;
    title: string;
    card_subtitle: string;
    pic: {
      large: string;
      normal: string;
    };
    rating: {
      value: number;
    };
  }>;
}

export const runtime = 'nodejs';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);

  // 获取参数
  const kind = searchParams.get('kind') || 'movie';
  const category = searchParams.get('category');
  const type = searchParams.get('type');
  const pageLimit = parseInt(searchParams.get('limit') || '20');
  const pageStart = parseInt(searchParams.get('start') || '0');

  // 验证参数
  if (!kind || !category || !type) {
    return NextResponse.json(
      { error: '缺少必要参数: kind 或 category 或 type' },
      { status: 400 }
    );
  }

  if (!['tv', 'movie'].includes(kind)) {
    return NextResponse.json(
      { error: 'kind 参数必须是 tv 或 movie' },
      { status: 400 }
    );
  }

  if (pageLimit < 1 || pageLimit > 100) {
    return NextResponse.json(
      { error: 'pageSize 必须在 1-100 之间' },
      { status: 400 }
    );
  }

  if (pageStart < 0) {
    return NextResponse.json(
      { error: 'pageStart 不能小于 0' },
      { status: 400 }
    );
  }

  const target = `https://m.douban.com/rexxar/api/v2/subject/recent_hot/${kind}?start=${pageStart}&limit=${pageLimit}&category=${category}&type=${type}`;

  try {
    // 调用豆瓣 API
    const doubanData = await fetchDoubanData<DoubanCategoryApiResponse>(target);

    // 转换数据格式
    const list: DoubanItem[] = doubanData.items.map((item) => ({
      id: item.id,
      title: item.title,
      poster: item.pic?.normal || item.pic?.large || '',
      rate: item.rating?.value ? item.rating.value.toFixed(1) : '',
      year: item.card_subtitle?.match(/(\d{4})/)?.[1] || '',
    }));

    const response: DoubanResult = {
      code: 200,
      message: '获取成功',
      list: list,
    };

    const cacheTime = await getCacheTime();
    return NextResponse.json(response, {
      headers: {
        'Cache-Control': `public, max-age=${cacheTime}, s-maxage=${cacheTime}`,
        'CDN-Cache-Control': `public, s-maxage=${cacheTime}`,
        'Vercel-CDN-Cache-Control': `public, s-maxage=${cacheTime}`,
        'Netlify-Vary': 'query',
      },
    });
  } catch (error) {
    // 详细的错误分类和处理
    const errorMessage = (error as Error).message;
    let errorType = 'unknown_error';
    let userMessage = '获取豆瓣数据失败，请稍后重试';
    let statusCode = 500;

    if (errorMessage.includes('HTTP error! Status: 429')) {
      errorType = 'rate_limit';
      userMessage = '豆瓣API请求过于频繁，请稍等片刻再试';
      statusCode = 429;
    } else if (errorMessage.includes('HTTP error! Status: 403')) {
      errorType = 'access_denied';
      userMessage = '豆瓣API访问受限，正在尝试其他方式';
      statusCode = 403;
    } else if (errorMessage.includes('HTTP error! Status: 404')) {
      errorType = 'not_found';
      userMessage = '未找到相关数据，请检查分类参数';
      statusCode = 404;
    } else if (errorMessage.includes('AbortError') || errorMessage.includes('timeout')) {
      errorType = 'timeout';
      userMessage = '网络连接超时，正在重试其他连接方式';
      statusCode = 408;
    } else if (errorMessage.includes('fetch failed') || errorMessage.includes('NetworkError')) {
      errorType = 'network_error';
      userMessage = '网络连接异常，正在尝试备用连接';
      statusCode = 503;
    } else if (errorMessage.includes('代理HTTP错误')) {
      errorType = 'proxy_error';
      userMessage = '代理服务暂时不可用，已切换到直连模式';
      statusCode = 502;
    } else if (errorMessage.includes('豆瓣API连接失败')) {
      errorType = 'all_failed';
      userMessage = '豆瓣服务暂时不可用，请稍后再试';
      statusCode = 503;
    }

    // 记录详细错误日志
    console.error(`[豆瓣API错误] 类型: ${errorType}, 消息: ${errorMessage}, 参数: kind=${kind}, category=${category}, type=${type}`);

    return NextResponse.json({
      error: userMessage,
      error_type: errorType,
      details: process.env.NODE_ENV === 'development' ? errorMessage : undefined,
      retry_suggested: ['timeout', 'network_error', 'proxy_error', 'all_failed'].includes(errorType)
    }, { status: statusCode });
  }
}
