#!/bin/sh

set -e

# AMD64 Build Script - Builds Docker image for AMD64 architecture and pushes to Docker Hub
# Run this script locally or in CI/CD pipeline

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}"
PLATFORM="linux/amd64"

echo "Building AMD64 Docker image..."
echo "Image will be tagged as: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Target platform: ${PLATFORM}"

# Build AMD64 Docker image
echo "Building AMD64 Docker image..."
docker build \
  --platform ${PLATFORM} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} \
  .

# Push the image
echo "Pushing AMD64 image to Docker Hub..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

# Also tag and push as latest if a specific tag was provided
if [ "$TAG" != "latest" ]; then
  echo "Tagging and pushing as latest..."
  docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
  docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
fi

echo "AMD64 build and push completed successfully!"
echo "Image available at: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Platform: ${PLATFORM}" 