# Deployment Guide

## Overview

This application uses a fully automated CI/CD pipeline that deploys to AWS EC2 using Docker containers. The pipeline is triggered on every push to the `main` branch.

## Architecture

```
GitHub Push → GitHub Actions → Build Docker Image → Push to DockerHub → Deploy to EC2 → Live Production
```

### Components

1. **GitHub Actions**: Automates the build and deployment process
2. **DockerHub**: Stores Docker images
3. **AWS EC2**: Hosts the application
4. **Nginx**: Reverse proxy with SSL termination
5. **Let's Encrypt**: Provides free SSL certificates

## How the Pipeline Works

### Step 1: Code Push
When you push code to the `main` branch:
```bash
git push origin main
```

### Step 2: GitHub Actions Build
The workflow (`.github/workflows/deploy.yml`) automatically:
1. Checks out the code
2. Builds a Docker image with your application
3. Injects Firebase environment variables during build
4. Tags the image with the git commit SHA and `latest`
5. Pushes the image to DockerHub

### Step 3: Deployment to EC2
After the image is pushed:
1. GitHub Actions connects to EC2 via SSH
2. Copies the deployment script to EC2
3. Pulls the latest Docker image from DockerHub
4. Stops the old container
5. Starts a new container with the updated image
6. Performs a health check

### Step 4: Zero-Downtime Deployment
The deployment process ensures:
- Old container keeps running until new one is ready
- Health checks verify the new container is working
- If deployment fails, the old container continues serving traffic

## Monitoring Deployments

### View GitHub Actions Logs
1. Go to your GitHub repository
2. Click on "Actions" tab
3. Select the latest workflow run
4. View logs for each step

### Check Deployment Status on EC2
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check running containers
docker ps

# View application logs
docker logs design-flow-app

# View last 100 lines of logs
docker logs --tail 100 design-flow-app

# Follow logs in real-time
docker logs -f design-flow-app
```

## Rollback Procedure

If a deployment causes issues, you can rollback:

### Method 1: Rollback via Git
```bash
# Revert the last commit
git revert HEAD

# Push to trigger new deployment
git push origin main
```

### Method 2: Deploy Previous Image
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Find previous image SHA from GitHub Actions history
docker pull your-dockerhub-username/design-flow-credits-hub:PREVIOUS_SHA

# Stop current container
docker stop design-flow-app
docker rm design-flow-app

# Start container with previous image
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  your-dockerhub-username/design-flow-credits-hub:PREVIOUS_SHA

# Verify
docker ps
```

## SSL Certificate Management

### Automatic Renewal
Certificates renew automatically via cron job (twice daily).

### Manual Certificate Renewal
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Renew certificates
sudo certbot renew

# Reload nginx
docker exec nginx-proxy nginx -s reload
```

### Check Certificate Expiry
```bash
sudo certbot certificates
```

## Environment Variables

Environment variables are managed through GitHub Secrets and injected during the Docker build process. See [ENVIRONMENT_VARS.md](./ENVIRONMENT_VARS.md) for details.

## DNS Configuration

Both domains point to your EC2 instance:
- `www.designuiux.com` → Primary site (HTTPS)
- `designuiux.com` → Redirects to www (HTTPS)

### DNS Records Required
```
Type: A
Name: www
Value: YOUR_EC2_PUBLIC_IP
TTL: 300

Type: A
Name: @
Value: YOUR_EC2_PUBLIC_IP
TTL: 300
```

## Security Considerations

1. **Secrets Management**: All sensitive data stored in GitHub Secrets
2. **SSL/TLS**: Enforced HTTPS with automatic redirects
3. **Security Headers**: Added via Nginx configuration
4. **Rate Limiting**: Prevents abuse
5. **Firewall**: EC2 Security Groups restrict access
6. **Container Isolation**: Application runs in isolated Docker container

## Performance Optimization

1. **Docker Layer Caching**: Speeds up builds
2. **Gzip Compression**: Reduces bandwidth
3. **Static Asset Caching**: Browser caching for 1 year
4. **HTTP/2**: Enabled for faster loading
5. **Multi-stage Build**: Smaller Docker images

## Deployment Frequency

- **Automatic**: Every push to `main` branch
- **Manual**: Can trigger via GitHub Actions UI
- **Recommended**: Deploy during low-traffic periods for major changes

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).
