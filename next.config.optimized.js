/** @type {import('next').NextConfig} */
const nextConfig = {
  // 生产环境优化
  swcMinify: true,
  poweredByHeader: false,

  // 实验性功能
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', '@headlessui/react'],
    swcMinify: true,
  },

  // 图像优化
  images: {
    domains: [],
    unoptimized: true,
  },

  // 编译优化
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // 构建优化
  webpack: (config, { isServer }) => {
    // 生产环境优化
    if (!isServer && process.env.NODE_ENV === 'production') {
      config.optimization.splitChunks = {
        chunks: 'all',
        cacheGroups: {
          default: {
            minChunks: 2,
            priority: -20,
            reuseExistingChunk: true,
          },
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendors',
            priority: -10,
            chunks: 'all',
          },
        },
      };
    }

    return config;
  },

  // 输出配置
  output: 'standalone',

  // 重定向和重写
  async redirects() {
    return [];
  },

  // 压缩
  compress: true,

  // 分析包大小
  webpack: (config) => {
    if (process.env.ANALYZE === 'true') {
      const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
      config.plugins.push(
        new BundleAnalyzerPlugin({
          analyzerMode: 'static',
          openAnalyzer: false,
        })
      );
    }
    return config;
  },
};

module.exports = nextConfig;