#!/bin/sh

set -e

# This script builds locally then creates a lightweight Docker container

# Ensure the .env file exists for the client app
if [ ! -f ./apps/web/client/.env ]; then
  echo ".env file not found in ./apps/web/client/. Please create it from .env.example."
  exit 1
fi

# Create network
docker network create deployment-onlook_network || true

# Clean up existing container
echo "Cleaning up existing onlook-container container..."
docker rm -f onlook-container || true

# Create the external volume for static files
echo "Creating next_static volume..."
docker volume create next_static || true

# Build optimized Docker image with memory constraints
echo "Building optimized Docker image with memory limits..."
docker build --memory=3g --memory-swap=4g -t onlook-app .

# Create a temporary container to copy static files to the volume
echo "Copying static files to shared volume..."
docker create --name temp-static-container onlook-app

# Clear the volume and copy new static files
docker run --rm -v next_static:/volume alpine sh -c "rm -rf /volume/* && mkdir -p /volume"
docker cp temp-static-container:/app/apps/web/client/.next/static/. /tmp/next_static_temp/
docker run --rm -v next_static:/volume -v /tmp/next_static_temp:/source alpine cp -r /source/. /volume/

# Clean up temporary container and files
docker rm temp-static-container
rm -rf /tmp/next_static_temp

# Run container in production mode with memory limits
echo "Starting Client Service in production mode..."
docker run -d --name onlook-container \
  --network deployment-onlook_network \
  -v next_static:/app/apps/web/client/.next/static \
  --memory=1g \
  --memory-swap=1.5g \
  onlook-app

echo "Client is running in production mode!"
echo "Static files are now available in the next_static volume for nginx to serve."