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
DEPLOY_DIR="/home/ubuntu/design-flow-app"

echo -e "${YELLOW}Docker Image: ${DOCKER_IMAGE}${NC}"

# Create deployment directory if it doesn't exist
mkdir -p ${DEPLOY_DIR}
cd ${DEPLOY_DIR}

# Pull latest image from DockerHub
echo -e "${YELLOW}Pulling latest image from DockerHub...${NC}"
docker pull ${DOCKER_IMAGE}

# Export Docker image for docker-compose
export DOCKER_IMAGE=${DOCKER_IMAGE}

# Stop existing containers using docker compose
echo -e "${YELLOW}Stopping existing containers...${NC}"
if [ -f "docker-compose.prod.yml" ]; then
    docker compose -f docker-compose.prod.yml down || true
fi

# Start containers with docker compose
echo -e "${YELLOW}Starting containers with docker compose...${NC}"
docker compose -f docker-compose.prod.yml up -d app nginx-proxy

# Wait for containers to be healthy
echo -e "${YELLOW}Waiting for containers to be healthy...${NC}"
sleep 10

# Check if app container is running
if [ "$(docker ps -q -f name=design-flow-app)" ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment successful!${NC}"
    echo -e "${GREEN}Application is running${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Show container status
    docker compose -f docker-compose.prod.yml ps

    # Start certbot if SSL certificates exist
    if [ -d "/etc/letsencrypt/live/designuiux.com" ]; then
        echo -e "${YELLOW}Starting certbot renewal service...${NC}"
        docker compose -f docker-compose.prod.yml up -d certbot
    else
        echo -e "${YELLOW}SSL certificates not found. Run init-letsencrypt.sh to set up SSL.${NC}"
    fi

    # Cleanup old images
    echo -e "${YELLOW}Cleaning up old images...${NC}"
    docker image prune -af --filter "until=72h" || true

    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}Application available at: http://designuiux.com${NC}"
    if [ -d "/etc/letsencrypt/live/designuiux.com" ]; then
        echo -e "${GREEN}SSL enabled at: https://designuiux.com${NC}"
    fi
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Deployment failed!${NC}"
    echo -e "${RED}Container failed to start${NC}"
    echo -e "${RED}========================================${NC}"

    # Show logs for debugging
    docker compose -f docker-compose.prod.yml logs app
    exit 1
fi
