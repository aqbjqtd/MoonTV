// 基础工具函数测试
import { describe, it, expect } from '@jest/globals';

describe('基础工具函数', () => {
  it('应该能够运行基本测试', () => {
    expect(1 + 1).toBe(2);
  });

  it('应该能够处理异步测试', async () => {
    const result = await Promise.resolve(42);
    expect(result).toBe(42);
  });

  it('应该能够模拟fetch', async () => {
    const mockData = { message: 'Hello World' };
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      json: async () => mockData,
    });

    const response = await fetch('/api/test');
    const data = await response.json();
    expect(data).toEqual(mockData);
  });
});