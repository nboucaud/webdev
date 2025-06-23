#!/bin/sh

# This script starts the local deployment using Docker Compose.

# Ensure the .env file exists for the client app
if [ ! -f ./apps/web/client/.env ]; then
  echo ".env file not found in ./apps/web/client/. Please create it from .env.example."
  exit 1
fi

# Build the client application
echo "Building Client Application..."
cd apps/web/client
NODE_OPTIONS='--max_old_space_size=2048' bun run build
cd ../../..

docker network create deployment-onlook_network || true
# Start the services using the docker-compose file in the nginx directory
echo "Starting Client Service..."
docker rm -f client || true
docker build --memory=4g -f apps/web/client/Dockerfile -t client .
docker run -d --name client --network deployment-onlook_network -v next_static:/app/apps/web/client/.next/static client