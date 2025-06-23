/**
 * Memory-optimized Next.js configuration for 8GB RAM constraint
 */
import { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';
import path from 'node:path';
import './src/env';

const nextConfig: NextConfig = {
    devIndicators: false,
    eslint: {
        ignoreDuringBuilds: true,
    },
    typescript: {
        ignoreBuildErrors: true,
    },

    // Critical memory optimizations
    productionBrowserSourceMaps: false,
    poweredByHeader: false,
    output: 'standalone', // For Docker optimization

    experimental: {
        webpackMemoryOptimizations: true,
        cpus: Math.max(2, Math.floor(require('os').cpus().length / 2)),
        workerThreads: false,
    },

    // Transpile monorepo packages
    transpilePackages: [
        '@onlook/ai',
        '@onlook/constants',
        '@onlook/db',
        '@onlook/email',
        '@onlook/fonts',
        '@onlook/git',
        '@onlook/growth',
        '@onlook/mastra',
        '@onlook/models',
        '@onlook/parser',
        '@onlook/penpal',
        '@onlook/rpc',
        '@onlook/scripts',
        '@onlook/stripe',
        '@onlook/types',
        '@onlook/ui',
        '@onlook/utility',
    ],
    serverExternalPackages: [
        '@codemirror/lang-css',
        '@codemirror/lang-html',
        '@codemirror/lang-javascript',
        '@codemirror/lang-json',
        '@codemirror/lang-markdown',
        '@uiw/codemirror-extensions-basic-setup',
        '@uiw/react-codemirror',
        'shiki',
        'prosemirror-commands',
        'prosemirror-history',
        'prosemirror-keymap',
    ],

    // Webpack memory optimizations
    webpack: (config, { dev, isServer, webpack }) => {
        // Reduce memory usage
        config.optimization = {
            ...config.optimization,
            // Disable code splitting during build to reduce memory
            splitChunks: dev
                ? config.optimization?.splitChunks
                : {
                      chunks: 'all',
                      minSize: 20000,
                      maxSize: 200000,
                      cacheGroups: {
                          default: false,
                          vendors: false,
                          // Bundle heavy packages separately
                          codemirror: {
                              name: 'codemirror',
                              test: /[\\/]node_modules[\\/](@codemirror|@uiw)/,
                              chunks: 'all',
                              priority: 30,
                          },
                          ai: {
                              name: 'ai-sdk',
                              test: /[\\/]node_modules[\\/](@ai-sdk|ai)/,
                              chunks: 'all',
                              priority: 25,
                          },
                          ui: {
                              name: 'ui-heavy',
                              test: /[\\/]node_modules[\\/](prosemirror|react-arborist|embla-carousel)/,
                              chunks: 'all',
                              priority: 20,
                          },
                      },
                  },
            // Reduce memory during minimization
            minimize: !dev,
            concatenateModules: false,
        };

        // Memory management
        config.resolve = {
            ...config.resolve,
            symlinks: false,
            cacheWithContext: false,
        };

        // Limit parallel processing
        config.parallelism = 1;

        // Add memory pressure relief
        config.plugins.push(
            new webpack.DefinePlugin({
                'process.env.NODE_OPTIONS': JSON.stringify('--max-old-space-size=1536'),
            }),
        );

        return config;
    },

    // Reduce bundle size
    modularizeImports: {
        'lucide-react': {
            transform: 'lucide-react/dist/esm/icons/{{member}}',
        },
    },
};

if (process.env.NODE_ENV === 'development') {
    nextConfig.outputFileTracingRoot = path.join(__dirname, '../../..');
}

const withNextIntl = createNextIntlPlugin({
    experimental: {
        createMessagesDeclaration: './messages/en.json',
    },
});
export default withNextIntl(nextConfig);
