// 工具函数测试扩展
import { describe, it, expect, beforeEach } from '@jest/globals';
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { ReactNode } from 'react';

// 测试工具函数
export const createMockRouter = (overrides = {}) => ({
  push: jest.fn(),
  replace: jest.fn(),
  reload: jest.fn(),
  back: jest.fn(),
  prefetch: jest.fn(),
  beforePopState: jest.fn(),
  pathname: '/',
  query: {},
  asPath: '/',
  isFallback: false,
  isLocaleDomain: true,
  isReady: true,
  events: {
    on: jest.fn(),
    off: jest.fn(),
    emit: jest.fn(),
  },
  ...overrides,
});

// 测试工具组件
const TestWrapper = ({ children }: { children: ReactNode }) => {
  return <div data-testid='test-wrapper'>{children}</div>;
};

describe('扩展工具函数测试', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('React测试工具', () => {
    it('应该能够渲染包装组件', () => {
      render(
        <TestWrapper>
          <div>测试内容</div>
        </TestWrapper>,
      );

      const wrapper = screen.getByTestId('test-wrapper');
      expect(wrapper).toBeInTheDocument();
      expect(wrapper).toHaveTextContent('测试内容');
    });

    it('应该能够模拟用户交互', () => {
      const handleClick = jest.fn();
      render(
        <TestWrapper>
          <button onClick={handleClick}>点击我</button>
        </TestWrapper>,
      );

      const button = screen.getByText('点击我');
      fireEvent.click(button);
      expect(handleClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('异步测试', () => {
    it('应该能够处理Promise rejection', async () => {
      const failingPromise = Promise.reject(new Error('测试错误'));

      await expect(failingPromise).rejects.toThrow('测试错误');
    });

    it('应该能够测试async/await', async () => {
      const asyncFunction = async (value: number) => {
        return new Promise((resolve) => {
          setTimeout(() => resolve(value * 2), 100);
        });
      };

      const result = await asyncFunction(21);
      expect(result).toBe(42);
    });
  });

  describe('Mock测试', () => {
    it('应该能够模拟模块', () => {
      const mockModule = {
        getValue: jest.fn().mockReturnValue(42),
        setValue: jest.fn(),
      };

      mockModule.getValue();
      expect(mockModule.getValue).toHaveBeenCalledTimes(1);
      expect(mockModule.setValue).not.toHaveBeenCalled();
    });

    it('应该能够模拟API调用', async () => {
      const mockFetch = jest.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ success: true }),
      });

      global.fetch = mockFetch;

      const response = await fetch('/api/test');
      const data = await response.json();

      expect(data).toEqual({ success: true });
      expect(mockFetch).toHaveBeenCalledWith('/api/test');
    });
  });
});
