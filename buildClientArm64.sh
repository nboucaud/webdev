#!/bin/sh

set -e

# ARM64 Build Script - Builds Docker image for ARM64 architecture and pushes to Docker Hub
# Run this script locally or in CI/CD pipeline

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}"
PLATFORM="linux/arm64"

echo "Building ARM64 Docker image..."
echo "Image will be tagged as: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Target platform: ${PLATFORM}"

# Build ARM64 Docker image
echo "Building ARM64 Docker image..."
docker build \
  --platform ${PLATFORM} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} \
  .

# Push the image
echo "Pushing ARM64 image to Docker Hub..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Also tag and push as latest if a specific tag was provided
if [ "$TAG" != "latest" ]; then
  echo "Tagging and pushing as latest..."
  docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
  docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
fi

echo "ARM64 build and push completed successfully!"
echo "Image available at: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Platform: ${PLATFORM}" 