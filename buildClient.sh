#!/bin/sh

set -e

# Multi-Architecture Build Script - Builds Docker image for multiple architectures and pushes to Docker Hub
# Run this script locally or in CI/CD pipeline

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}" 
PLATFORMS="linux/amd64,linux/arm64"  

echo "Building multi-architecture Docker image..."
echo "Image will be tagged as: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Target platforms: ${PLATFORMS}"

# Create and use a new builder instance for multi-architecture builds
echo "Setting up buildx builder..."
docker buildx create --name multiarch-builder --use || docker buildx use multiarch-builder

# Ensure the builder is running
docker buildx inspect --bootstrap

# Build multi-architecture Docker image with memory and CPU constraints
echo "Building optimized multi-architecture Docker image..."
docker buildx build \
  --platform ${PLATFORMS} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} \
  --push \
  .

# Also tag and push as latest if a specific tag was provided
if [ "$TAG" != "latest" ]; then
  echo "Building and pushing latest tag..."
  docker buildx build \
    --platform ${PLATFORMS} \
    -t ${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
    --push \
    .
fi

echo "Multi-architecture build and push completed successfully!"
echo "Image available at: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Supported platforms: ${PLATFORMS}"

# Clean up builder (optional)
echo "Cleaning up builder..."
docker buildx rm multiarch-builder || true 