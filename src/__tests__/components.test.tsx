// 组件测试示例
import { describe, it, expect } from '@jest/globals';
import { render, screen } from '@testing-library/react';

describe('组件测试', () => {
  it('应该能够渲染基本组件', () => {
    const TestComponent = () => <div>Test Component</div>;
    render(<TestComponent />);
    expect(screen.getByText('Test Component')).toBeInTheDocument();
  });

  it('应该能够测试基本功能', () => {
    const message = 'Hello MoonTV';
    expect(message).toBe('Hello MoonTV');
  });
});