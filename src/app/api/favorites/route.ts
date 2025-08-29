import { NextRequest, NextResponse } from 'next/server';

import { getAuthInfoFromCookie } from '@/lib/auth';
import { getConfig } from '@/lib/config';
import { db } from '@/lib/db';
import { createApiLogger } from '@/lib/request-logger';
import { Favorite } from '@/lib/types';

type AuthInfo = {
  username?: string;
  password?: string;
  signature?: string;
  timestamp?: number;
} | null;

const favoritesLogger = createApiLogger('favorites');


/**
 * GET /api/favorites
 *
 * 支持两种调用方式：
 * 1. 不带 query，返回全部收藏列表（Record<string, Favorite>）。
 * 2. 带 key=source+id，返回单条收藏（Favorite | null）。
 */
export async function GET(request: NextRequest) {
  let authInfo: AuthInfo = null;
  try {
    // 从 cookie 获取用户信息
    authInfo = getAuthInfoFromCookie(request);
    if (!authInfo || !authInfo.username) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const username = authInfo.username; // 已通过null检查，安全使用

    const config = await getConfig();
    if (config.UserConfig.Users) {
      // 检查用户是否被封禁
      const user = config.UserConfig.Users.find(
        (u) => u.username === username
      );
      if (user && user.banned) {
        return NextResponse.json({ error: '用户已被封禁' }, { status: 401 });
      }
    }

    const { searchParams } = new URL(request.url);
    const key = searchParams.get('key');

    // 查询单条收藏
    if (key) {
      const [source, id] = key.split('+');
      if (!source || !id) {
        return NextResponse.json(
          { error: 'Invalid key format' },
          { status: 400 }
        );
      }
      const fav = await db.getFavorite(username, source, id);
      return NextResponse.json(fav, { status: 200 });
    }

    // 查询全部收藏
    const favorites = await db.getAllFavorites(username);
    return NextResponse.json(favorites, { status: 200 });
  } catch (err) {
    favoritesLogger.logError(err as Error, { username: authInfo?.username });
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/favorites
 * body: { key: string; favorite: Favorite }
 */
export async function POST(request: NextRequest) {
  let authInfo: AuthInfo = null;
  try {
    // 从 cookie 获取用户信息
    authInfo = getAuthInfoFromCookie(request);
    if (!authInfo || !authInfo.username) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const username = authInfo.username; // 已通过null检查，安全使用

    const config = await getConfig();
    if (config.UserConfig.Users) {
      // 检查用户是否被封禁
      const user = config.UserConfig.Users.find(
        (u) => u.username === username
      );
      if (user && user.banned) {
        return NextResponse.json({ error: '用户已被封禁' }, { status: 401 });
      }
    }

    const body = await request.json();
    const { key, favorite }: { key: string; favorite: Favorite } = body;

    if (!key || !favorite) {
      return NextResponse.json(
        { error: 'Missing key or favorite' },
        { status: 400 }
      );
    }

    // 验证必要字段
    if (!favorite.title || !favorite.source_name) {
      return NextResponse.json(
        { error: 'Invalid favorite data' },
        { status: 400 }
      );
    }

    const [source, id] = key.split('+');
    if (!source || !id) {
      return NextResponse.json(
        { error: 'Invalid key format' },
        { status: 400 }
      );
    }

    const finalFavorite = {
      ...favorite,
      save_time: favorite.save_time ?? Date.now(),
    } as Favorite;

    await db.saveFavorite(username, source, id, finalFavorite);

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (err) {
    favoritesLogger.logError(err as Error, { username: authInfo?.username, action: 'add' });
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/favorites
 *
 * 1. 不带 query -> 清空全部收藏
 * 2. 带 key=source+id -> 删除单条收藏
 */
export async function DELETE(request: NextRequest) {
  let authInfo: AuthInfo = null;
  try {
    // 从 cookie 获取用户信息
    authInfo = getAuthInfoFromCookie(request);
    if (!authInfo || !authInfo.username) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const username = authInfo.username; // 已通过null检查，安全使用

    const config = await getConfig();
    if (config.UserConfig.Users) {
      // 检查用户是否被封禁
      const user = config.UserConfig.Users.find(
        (u) => u.username === username
      );
      if (user && user.banned) {
        return NextResponse.json({ error: '用户已被封禁' }, { status: 401 });
      }
    }

    const { searchParams } = new URL(request.url);
    const key = searchParams.get('key');

    if (key) {
      // 删除单条
      const [source, id] = key.split('+');
      if (!source || !id) {
        return NextResponse.json(
          { error: 'Invalid key format' },
          { status: 400 }
        );
      }
      await db.deleteFavorite(username, source, id);
    } else {
      // 清空全部
      const all = await db.getAllFavorites(username);
      await Promise.all(
        Object.keys(all).map(async (k) => {
          const [s, i] = k.split('+');
          if (s && i) await db.deleteFavorite(username, s, i);
        })
      );
    }

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (err) {
    favoritesLogger.logError(err as Error, { username: authInfo?.username, action: 'delete' });
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}