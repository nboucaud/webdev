#!/bin/sh

set -e

# Build Script - Builds Docker image locally and pushes to Docker Hub
# Run this script locally or in CI/CD pipeline

DOCKER_USERNAME="jem3i"
IMAGE_NAME="onlook-app"
TAG="${1:-latest}"  # Use provided tag or default to 'latest'

echo "Building Docker image..."
echo "Image will be tagged as: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

# Build optimized Docker image with memory and CPU constraints
echo "Building optimized Docker image with memory and CPU limits..."
docker build --memory=3g --memory-swap=4g --cpu-period=100000 --cpu-quota=200000 -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} .

# Also tag as latest if a specific tag was provided
if [ "$TAG" != "latest" ]; then
  echo "Tagging image as latest..."
  docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
fi

# Push to Docker Hub
echo "Pushing image to Docker Hub..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

if [ "$TAG" != "latest" ]; then
  echo "Pushing latest tag to Docker Hub..."
  docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
fi

echo "Build and push completed successfully!"
echo "Image available at: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}" 