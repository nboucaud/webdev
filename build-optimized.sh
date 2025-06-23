#!/bin/bash

set -e

# Memory-optimized build script
echo "Starting memory-optimized build process..."

# Set memory limits and environment variables
export NODE_OPTIONS="--max-old-space-size=1024 --optimize-for-size"
export NEXT_TELEMETRY_DISABLED=1
export DISABLE_ESLINT_PLUGIN=true

# Clear any previous builds
echo "Cleaning previous builds..."
rm -rf apps/web/client/.next
rm -rf apps/web/client/out
rm -rf node_modules/.cache

# Enable swap if not already enabled (Linux/Mac)
if command -v swapon &> /dev/null; then
    echo "Checking swap status..."
    sudo swapon --show
fi

# Build packages incrementally to reduce memory usage
echo "Building packages incrementally..."

# Clear cache between builds
echo "Clearing cache..."
rm -rf node_modules/.cache 2>/dev/null || true

# Build Next.js with minimal memory usage
echo "Building Next.js application with optimizations..."
cd apps/web/client

# Use incremental builds and reduce parallelism
NODE_OPTIONS="--max-old-space-size=1024" \
NEXT_TELEMETRY_DISABLED=1 \
npm run build

cd ../../..
echo "Build completed!" 