// SVG Mock组件
import React from 'react';

interface SvgProps {
  src?: string;
  width?: number | string;
  height?: number | string;
  className?: string;
  alt?: string;
  [key: string]: any;
}

export default function SvgMock({
  width = 24,
  height = 24,
  className = '',
  ...props
}: SvgProps) {
  return (
    <div
      data-testid='svg-mock'
      className={className}
      style={{ width, height }}
      {...props}
      role='img'
    />
  );
}
