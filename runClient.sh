#!/bin/sh

set -e

# Run Script - Pulls Docker image from Docker Hub and runs it on the server
# Run this script on the remote server

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}"  # Use provided tag or default to 'latest'
CONTAINER_NAME="onlook-container"
TEMP_CONTAINER_NAME="temp-static-container-$(date +%s)"  # Unique name with timestamp

# Ensure the .env file exists for the client app
if [ ! -f ./apps/web/client/.env ]; then
  echo ".env file not found in ./apps/web/client/. Please create it from .env.example."
  exit 1
fi

# Pull the latest image from Docker Hub
echo "Pulling Docker image from Docker Hub..."
docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Create network (ignore if already exists)
echo "Creating Docker network..."
docker network create deployment-onlook_network 2>/dev/null || echo "Network already exists, continuing..."

# Clean up existing containers
echo "Cleaning up existing containers..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || echo "Container ${CONTAINER_NAME} not found, continuing..."
docker rm -f temp-static-container 2>/dev/null || echo "Old temp container not found, continuing..."

# Create the external volume for static files
echo "Creating next_static volume..."
docker volume create next_static 2>/dev/null || echo "Volume already exists, continuing..."

# Create a temporary container to copy static files to the volume
echo "Copying static files to shared volume..."
docker create --name ${TEMP_CONTAINER_NAME} ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Clear the volume and copy new static files
echo "Preparing volume and copying static files..."
docker run --rm -v next_static:/volume alpine sh -c "rm -rf /volume/* && mkdir -p /volume" || true

# Create temp directory and copy Next.js static files
mkdir -p /tmp/next_static_temp_$$
docker cp ${TEMP_CONTAINER_NAME}:/app/apps/web/client/.next/static/. /tmp/next_static_temp_$$/ 2>/dev/null || echo "No static files to copy, continuing..."

# Copy to volume if files exist
if [ -d "/tmp/next_static_temp_$$" ] && [ "$(ls -A /tmp/next_static_temp_$$)" ]; then
    docker run --rm -v next_static:/volume -v /tmp/next_static_temp_$$:/source alpine cp -r /source/. /volume/ || echo "Failed to copy static files, continuing..."
fi

# Copy assets folder from public directory - FIXED PATH
echo "Copying assets folder to shared volume..."
mkdir -p /tmp/assets_temp_$$
docker cp ${TEMP_CONTAINER_NAME}:/app/apps/web/client/public/assets/. /tmp/assets_temp_$$/ 2>/dev/null || echo "No assets files to copy, continuing..."

# Copy assets to volume if files exist
if [ -d "/tmp/assets_temp_$$" ] && [ "$(ls -A /tmp/assets_temp_$$)" ]; then
    docker run --rm -v next_static:/volume -v /tmp/assets_temp_$$:/source alpine sh -c "mkdir -p /volume/assets && cp -r /source/. /volume/assets/" || echo "Failed to copy assets files, continuing..."
fi

# Clean up temporary container and files
echo "Cleaning up temporary resources..."
docker rm ${TEMP_CONTAINER_NAME} 2>/dev/null || true
rm -rf /tmp/next_static_temp_$$ 2>/dev/null || true
rm -rf /tmp/assets_temp_$$ 2>/dev/null || true

# Run container in production mode with memory limits and restart policy
echo "Starting Client Service in production mode..."
docker run -d --name ${CONTAINER_NAME} \
  --network deployment-onlook_network \
  --restart always \
  -v next_static:/app/.next/static \
  -v "$(pwd)/apps/web/client/.env:/app/.env:ro" \
  --env-file "$(pwd)/apps/web/client/.env" \
  -e SKIP_ENV_VALIDATION=1 \
  ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

echo "Client is running in production mode!"
echo "Container will restart automatically on system reboot."
echo "Static files and assets are now available in the next_static volume for nginx to serve."
echo "Container logs: docker logs -f ${CONTAINER_NAME}"
