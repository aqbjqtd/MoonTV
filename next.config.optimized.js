/** @type {import('next').NextConfig} */
/* eslint-disable @typescript-eslint/no-var-requires */

const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
  scope: '/',
  sw: 'service-worker.js',
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',

  // ESLint 配置
  eslint: {
    ignoreDuringBuilds: false,
    dirs: ['src'], // 只检查 src 目录
  },

  // TypeScript 配置
  typescript: {
    ignoreBuildErrors: false,
  },

  // React 配置
  reactStrictMode: true, // 启用严格模式以检测潜在问题
  swcMinify: true, // 使用 SWC 压缩

  // 图片优化配置
  images: {
    unoptimized: false, // 启用图片优化
    formats: ['image/webp', 'image/avif'], // 现代图片格式
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: '**',
      },
    ],
    minimumCacheTTL: 86400, // 24小时缓存
  },

  // 压缩配置
  compress: true,
  poweredByHeader: false, // 移除 X-Powered-By 头

  // 实验性功能
  experimental: {
    optimizePackageImports: ['lucide-react', '@heroicons/react'], // 优化包导入
    turbo: {
      rules: {
        '*.svg': {
          loaders: ['@svgr/webpack'],
          as: '*.js',
        },
      },
    },
  },

  // Webpack 优化
  webpack(config, { dev, isServer }) {
    // SVG 处理规则
    const fileLoaderRule = config.module.rules.find((rule) =>
      rule.test?.test?.('.svg'),
    );

    config.module.rules.push(
      {
        ...fileLoaderRule,
        test: /\.svg$/i,
        resourceQuery: /url/,
      },
      {
        test: /\.svg$/i,
        issuer: { not: /\.(css|scss|sass)$/ },
        resourceQuery: { not: /url/ },
        loader: '@svgr/webpack',
        options: {
          dimensions: false,
          titleProp: true,
          memo: true, // 启用 memo
        },
      },
    );

    fileLoaderRule.exclude = /\.svg$/i;

    // Fallback 配置
    config.resolve.fallback = {
      ...config.resolve.fallback,
      net: false,
      tls: false,
      crypto: false,
      fs: false,
      path: false,
    };

    // 生产环境优化
    if (!dev && !isServer) {
      // 代码分割优化
      config.optimization = {
        ...config.optimization,
        splitChunks: {
          chunks: 'all',
          cacheGroups: {
            vendor: {
              test: /[\\/]node_modules[\\/]/,
              name: 'vendors',
              chunks: 'all',
              priority: 10,
            },
            common: {
              name: 'common',
              minChunks: 2,
              chunks: 'all',
              priority: 5,
            },
          },
        },
      };

      // Resolve 优化
      config.resolve.alias = {
        ...config.resolve.alias,
        '@': './src',
        '~': './public',
      };
    }

    // 性能优化
    config.performance = {
      hints: false, // 暂时禁用性能提示
    };

    // 分析包大小
    if (process.env.ANALYZE === 'true') {
      const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
      config.plugins.push(
        new BundleAnalyzerPlugin({
          analyzerMode: 'static',
          openAnalyzer: false,
        }),
      );
    }

    return config;
  },

  // 安全头配置
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
        ],
      },
      {
        source: '/api/(.*)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, no-cache, must-revalidate, proxy-revalidate',
          },
        ],
      },
      {
        source: '/(.*\\.(js|css|png|jpg|jpeg|gif|ico|svg))',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
    ];
  },

  // 重定向配置
  async redirects() {
    return [
      // 可以根据需要添加重定向规则
    ];
  },
};

// 开发环境特殊配置
if (process.env.NODE_ENV === 'development') {
  try {
    const { setupDevPlatform } = require('@cloudflare/next-on-pages/next-dev');
    setupDevPlatform();
  } catch (error) {
    console.warn('Cloudflare dev platform setup skipped:', error.message);
  }
}

module.exports = withPWA(nextConfig);
