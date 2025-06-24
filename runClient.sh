#!/bin/sh

set -e

# Run Script - Pulls Docker image from Docker Hub and runs it on the server
# Run this script on the remote server

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}"  # Use provided tag or default to 'latest'
CONTAINER_NAME="onlook-container"

# Ensure the .env file exists for the client app
if [ ! -f ./apps/web/client/.env ]; then
  echo ".env file not found in ./apps/web/client/. Please create it from .env.example."
  exit 1
fi

# Pull the latest image from Docker Hub
echo "Pulling Docker image from Docker Hub..."
docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Create network
echo "Creating Docker network..."
docker network create deployment-onlook_network || true

# Clean up existing container
echo "Cleaning up existing ${CONTAINER_NAME} container..."
docker rm -f ${CONTAINER_NAME} || true

# Create the external volume for static files
echo "Creating next_static volume..."
docker volume create next_static || true

# Create a temporary container to copy static files to the volume
echo "Copying static files to shared volume..."
docker create --name temp-static-container ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Clear the volume and copy new static files
docker run --rm -v next_static:/volume alpine sh -c "rm -rf /volume/* && mkdir -p /volume"
docker cp temp-static-container:/app/apps/web/client/.next/static/. /tmp/next_static_temp/
docker run --rm -v next_static:/volume -v /tmp/next_static_temp:/source alpine cp -r /source/. /volume/

# Clean up temporary container and files
docker rm temp-static-container
rm -rf /tmp/next_static_temp

# Run container in production mode with memory limits and restart policy
echo "Starting Client Service in production mode..."
docker run -d --name ${CONTAINER_NAME} \
  --network deployment-onlook_network \
  --restart always \
  -v next_static:/app/apps/web/client/.next/static \
  -v "$(pwd)/apps/web/client/.env:/app/apps/web/client/.env:ro" \
  --memory=1g \
  --memory-swap=1.5g \
  ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

echo "Client is running in production mode!"
echo "Container will restart automatically on system reboot."
echo "Static files are now available in the next_static volume for nginx to serve."