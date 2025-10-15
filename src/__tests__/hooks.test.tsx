// 自定义Hook测试
import { describe, it, expect, beforeEach } from '@jest/globals';
import React from 'react';
import { renderHook, act } from '@testing-library/react';
import { ReactNode } from 'react';

// 测试用的简单Hook
function useCounter(initialValue = 0) {
  const [count, setCount] = React.useState(initialValue);
  const increment = () => setCount((prev) => prev + 1);
  const decrement = () => setCount((prev) => prev - 1);
  const reset = () => setCount(initialValue);

  return { count, increment, decrement, reset };
}

// 测试用的异步Hook
function useAsyncData<T>(fetcher: () => Promise<T>) {
  const [data, setData] = React.useState<T | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<Error | null>(null);

  React.useEffect(() => {
    let cancelled = false;

    const loadData = async () => {
      try {
        setLoading(true);
        const result = await fetcher();
        if (!cancelled) {
          setData(result);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err as Error);
          setData(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    loadData();

    return () => {
      cancelled = true;
    };
  }, [fetcher]);

  return { data, loading, error };
}

describe('自定义Hook测试', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useCounter Hook', () => {
    it('应该返回初始值', () => {
      const { result } = renderHook(() => useCounter(10));
      expect(result.current.count).toBe(10);
    });

    it('应该能够增加计数', () => {
      const { result } = renderHook(() => useCounter(0));

      act(() => {
        result.current.increment();
      });

      expect(result.current.count).toBe(1);
    });

    it('应该能够减少计数', () => {
      const { result } = renderHook(() => useCounter(5));

      act(() => {
        result.current.decrement();
      });

      expect(result.current.count).toBe(4);
    });

    it('应该能够重置计数', () => {
      const { result } = renderHook(() => useCounter(3));

      act(() => {
        result.current.increment();
        result.current.increment();
      });

      expect(result.current.count).toBe(5);

      act(() => {
        result.current.reset();
      });

      expect(result.current.count).toBe(3);
    });
  });

  describe('useAsyncData Hook', () => {
    it('应该处理成功的数据获取', async () => {
      const mockFetcher = jest.fn().mockResolvedValue({ id: 1, name: 'Test' });

      const { result } = renderHook(() => useAsyncData(mockFetcher));

      expect(result.current.loading).toBe(true);
      expect(result.current.data).toBe(null);
      expect(result.current.error).toBe(null);

      await act(async () => {
        await new Promise((resolve) => setTimeout(resolve, 0));
      });

      expect(result.current.loading).toBe(false);
      expect(result.current.data).toEqual({ id: 1, name: 'Test' });
      expect(result.current.error).toBe(null);
      expect(mockFetcher).toHaveBeenCalledTimes(1);
    });

    it('应该处理数据获取错误', async () => {
      const mockError = new Error('获取失败');
      const mockFetcher = jest.fn().mockRejectedValue(mockError);

      const { result } = renderHook(() => useAsyncData(mockFetcher));

      await act(async () => {
        await new Promise((resolve) => setTimeout(resolve, 0));
      });

      expect(result.current.loading).toBe(false);
      expect(result.current.data).toBe(null);
      expect(result.current.error).toBe(mockError);
    });

    it('应该在组件卸载时取消请求', async () => {
      const mockFetcher = jest
        .fn()
        .mockImplementation(
          () =>
            new Promise((resolve) =>
              setTimeout(() => resolve({ success: true }), 1000),
            ),
        );

      const { unmount } = renderHook(() => useAsyncData(mockFetcher));

      // 立即卸载组件
      unmount();

      // 等待足够时间让原始Promise完成
      await new Promise((resolve) => setTimeout(resolve, 100));

      // 验证数据没有被设置（因为组件已卸载）
      expect(mockFetcher).toHaveBeenCalledTimes(1);
    });
  });
});
