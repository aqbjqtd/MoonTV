
import { NextRequest, NextResponse } from 'next/server';

import { db } from '@/lib/db';
import { fetchVideoDetail } from '@/lib/fetchVideoDetail';
import { createApiLogger } from '@/lib/request-logger';
import { SearchResult } from '@/lib/types';

const cronLogger = createApiLogger('cron');



export async function GET(request: NextRequest) {
  cronLogger.logStart({ url: request.url });
  try {
    cronLogger.logStart({ timestamp: new Date().toISOString() });

    refreshRecordAndFavorites();

    return NextResponse.json({
      success: true,
      message: 'Cron job executed successfully',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    cronLogger.logError(error as Error);

    return NextResponse.json(
      {
        success: false,
        message: 'Cron job failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}

async function refreshRecordAndFavorites() {
  if (
    (process.env.NEXT_PUBLIC_STORAGE_TYPE || 'localstorage') === 'localstorage'
  ) {
    cronLogger.logSuccess({ message: '跳过刷新：当前使用 localstorage 存储模式' });
    return;
  }

  try {
    const users = await db.getAllUsers();
    if (process.env.USERNAME && !users.includes(process.env.USERNAME)) {
      users.push(process.env.USERNAME);
    }
    // 函数级缓存：key 为 `${source}+${id}`，值为 Promise<VideoDetail | null>
    const detailCache = new Map<string, Promise<SearchResult | null>>();

    // 获取详情 Promise（带缓存和错误处理）
    const getDetail = async (
      source: string,
      id: string,
      fallbackTitle: string
    ): Promise<SearchResult | null> => {
      const key = `${source}+${id}`;
      let promise = detailCache.get(key);
      if (!promise) {
        promise = fetchVideoDetail({
          source,
          id,
          fallbackTitle: fallbackTitle.trim(),
        })
          .then((detail) => {
            // 成功时才缓存结果
            const successPromise = Promise.resolve(detail);
            detailCache.set(key, successPromise);
            return detail;
          })
          .catch((error) => {
            cronLogger.logError(new Error(`获取视频详情失败 (${source}+${id}):`), { source, id, originalError: error });
            return null;
          });
      }
      return promise;
    };

    for (const user of users) {
      cronLogger.logSuccess({ user });

      // 播放记录
      try {
        const playRecords = await db.getAllPlayRecords(user);
        const totalRecords = Object.keys(playRecords).length;
        let processedRecords = 0;

        for (const [key, record] of Object.entries(playRecords)) {
          try {
            const [source, id] = key.split('+');
            if (!source || !id) {
              cronLogger.logValidationError({ key, message: '跳过无效的播放记录键' });
              continue;
            }

            const detail = await getDetail(source, id, record.title);
            if (!detail) {
              cronLogger.logValidationError({ key, message: '跳过无法获取详情的播放记录' });
              continue;
            }

            const episodeCount = detail.episodes?.length || 0;
            if (episodeCount > 0 && episodeCount !== record.total_episodes) {
              await db.savePlayRecord(user, source, id, {
                title: detail.title || record.title,
                source_name: record.source_name,
                cover: detail.poster || record.cover,
                index: record.index,
                total_episodes: episodeCount,
                play_time: record.play_time,
                year: detail.year || record.year,
                total_time: record.total_time,
                save_time: record.save_time,
                search_title: record.search_title,
              });
              cronLogger.logSuccess({ title: record.title, oldEpisodes: record.total_episodes, newEpisodes: episodeCount, message: '更新播放记录' });
            }

            processedRecords++;
          } catch (error) {
            cronLogger.logError(new Error(`处理播放记录失败 (${key}):`), { key, originalError: error });
            // 继续处理下一个记录
          }
        }

        cronLogger.logSuccess({ processed: processedRecords, total: totalRecords, message: '播放记录处理完成' });
      } catch (error) {
        cronLogger.logError(new Error(`获取用户播放记录失败 (${user}):`), { user, originalError: error });
      }

      // 收藏
      try {
        const favorites = await db.getAllFavorites(user);
        const totalFavorites = Object.keys(favorites).length;
        let processedFavorites = 0;

        for (const [key, fav] of Object.entries(favorites)) {
          try {
            const [source, id] = key.split('+');
            if (!source || !id) {
  cronLogger.logValidationError({ key, message: '跳过无效的收藏键' });
              continue;
            }

            const favDetail = await getDetail(source, id, fav.title);
            if (!favDetail) {
              cronLogger.logValidationError({ key, message: '跳过无法获取详情的收藏' });
              continue;
            }

            const favEpisodeCount = favDetail.episodes?.length || 0;
            if (favEpisodeCount > 0 && favEpisodeCount !== fav.total_episodes) {
              await db.saveFavorite(user, source, id, {
                title: favDetail.title || fav.title,
                source_name: fav.source_name,
                cover: favDetail.poster || fav.cover,
                year: favDetail.year || fav.year,
                total_episodes: favEpisodeCount,
                save_time: fav.save_time,
                search_title: fav.search_title,
              });
              cronLogger.logSuccess({ title: fav.title, oldEpisodes: fav.total_episodes, newEpisodes: favEpisodeCount, message: '更新收藏' });
            }

            processedFavorites++;
          } catch (error) {
            cronLogger.logError(new Error(`处理收藏失败 (${key}):`), { key, originalError: error });
            // 继续处理下一个收藏
          }
        }

        cronLogger.logSuccess({ processed: processedFavorites, total: totalFavorites, message: '收藏处理完成' });
      } catch (error) {
        cronLogger.logError(new Error(`获取用户收藏失败 (${user}):`), { user, originalError: error });
      }
    }

    cronLogger.logSuccess({ message: '刷新播放记录/收藏任务完成' });
  } catch (error) {
    cronLogger.logError(error instanceof Error ? error : new Error(String(error)));
  }
}
