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

    output: 'standalone', // For Docker optimization
    webpack(config, { isServer }) {
        console.log(`> 🔧 Webpack build for ${isServer ? 'server' : 'client'}`);

        config.plugins.push({
            apply(compiler) {
                compiler.hooks.compilation.tap('LogModulesPlugin', (compilation) => {
                    compilation.hooks.buildModule.tap('LogModulesPlugin', (module) => {
                        if (module.resource) {
                            const file = module.resource;
                            if (
                                file.includes('/node_modules/') ||
                                file.includes('.next') ||
                                file.includes('__virtual__')
                            )
                                return;

                            console.log(`🛠️ ${isServer ? 'server' : 'client'}: ${file}`);
                        }
                    });
                });
            },
        });

        return config;
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
