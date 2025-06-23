#!/bin/sh

# This script builds locally then creates a lightweight Docker container

# Ensure the .env file exists for the client app
if [ ! -f ./apps/web/client/.env ]; then
  echo ".env file not found in ./apps/web/client/. Please create it from .env.example."
  exit 1
fi

# Build locally to save server RAM with resource limits
echo "Building Next.js app locally with resource limits..."
cd apps/web/client

# Clean previous build
rm -rf .next

# Build with memory and CPU limits to prevent server overload
# Set environment variable first, then run with nice (lower CPU priority)
export NODE_OPTIONS='--max-old-space-size=4096'
nice -n 10 bun run build &
BUILD_PID=$!

# Monitor and limit CPU usage
while kill -0 $BUILD_PID 2>/dev/null; do
    # Check if build process is using too much CPU
    CPU_USAGE=$(ps -p $BUILD_PID -o %cpu= 2>/dev/null || echo "0")
    if [ "${CPU_USAGE%.*}" -gt 80 ]; then
        echo "Build using high CPU (${CPU_USAGE}%), throttling..."
        kill -STOP $BUILD_PID
        sleep 2
        kill -CONT $BUILD_PID
    fi
    sleep 5
done

# Wait for build to complete
wait $BUILD_PID
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "Build failed with exit code $BUILD_EXIT_CODE"
    exit $BUILD_EXIT_CODE
fi

cd ../../..

# Create network
docker network create deployment-onlook_network || true

# Clean up existing container
echo "Cleaning up existing client container..."
docker rm -f client || true

# Build lightweight Docker image with resource limits
echo "Building Docker image with resource limits..."
docker build \
  --memory=2g \
  -f apps/web/client/Dockerfile \
  -t client \
  .

# Run container with resource limits
echo "Starting Client Service with resource limits..."
docker run -d \
  --name client \
  --network deployment-onlook_network \
  --memory=1g \
  --cpus=0.5 \
  client

echo "Client is running! Build was done with resource limits to protect server."