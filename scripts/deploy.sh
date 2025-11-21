#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting deployment process...${NC}"
echo -e "${GREEN}========================================${NC}"

# Get the Docker image name from the first argument
DOCKER_IMAGE=${1:-"credittrackerprod:latest"}
CONTAINER_NAME="design-flow-app"

echo -e "${YELLOW}Docker Image: ${DOCKER_IMAGE}${NC}"

# Login to DockerHub (credentials should be in environment or docker already logged in)
echo -e "${YELLOW}Pulling latest image from DockerHub...${NC}"
docker pull ${DOCKER_IMAGE}

# Stop and remove existing container if it exists
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME} || true
    echo -e "${YELLOW}Removing existing container...${NC}"
    docker rm ${CONTAINER_NAME} || true
fi

# Run new container
echo -e "${YELLOW}Starting new container...${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p 3000:80 \
  ${DOCKER_IMAGE}

# Wait for container to be healthy
echo -e "${YELLOW}Waiting for container to be healthy...${NC}"
sleep 5

# Check if container is running
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment successful!${NC}"
    echo -e "${GREEN}Container ${CONTAINER_NAME} is running${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Show container status
    docker ps | grep ${CONTAINER_NAME}

    # Cleanup old images (keep last 3)
    echo -e "${YELLOW}Cleaning up old images...${NC}"
    docker image prune -af --filter "until=72h" || true

    echo -e "${GREEN}Deployment completed successfully!${NC}"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Deployment failed!${NC}"
    echo -e "${RED}Container failed to start${NC}"
    echo -e "${RED}========================================${NC}"

    # Show logs for debugging
    docker logs ${CONTAINER_NAME}
    exit 1
fi
