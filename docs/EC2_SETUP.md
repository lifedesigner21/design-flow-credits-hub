# EC2 Setup Guide

This guide walks you through setting up your AWS EC2 instance for hosting the Design Flow Credits Hub application.

## Prerequisites

- AWS Account
- Basic understanding of AWS EC2
- Your domain DNS configured to point to EC2

## Step 1: Launch EC2 Instance

### Instance Configuration

1. **AMI**: Ubuntu Server 22.04 LTS
2. **Instance Type**: t3.small or larger (minimum)
   - Recommended: t3.medium for production
3. **Storage**: 20 GB GP3 SSD (minimum)
4. **Key Pair**: Create or use existing SSH key pair

### Security Group Configuration

Create a security group with the following inbound rules:

| Type  | Protocol | Port Range | Source    | Description           |
|-------|----------|------------|-----------|-----------------------|
| SSH   | TCP      | 22         | Your IP   | SSH access            |
| HTTP  | TCP      | 80         | 0.0.0.0/0 | HTTP traffic          |
| HTTPS | TCP      | 443        | 0.0.0.0/0 | HTTPS traffic         |

**Important**: Restrict SSH access to your IP address for security.

## Step 2: Connect to EC2 Instance

```bash
# Replace with your key and EC2 public IP
ssh -i /path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# If permission error on key file:
chmod 400 /path/to/your-key.pem
```

## Step 3: Install Docker

```bash
# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Log out and log back in for group changes to take effect
exit
```

### Verify Docker Installation

```bash
# After logging back in
docker --version
docker compose version
```

## Step 4: Install Docker Compose (if needed)

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

## Step 5: Configure Firewall (UFW)

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (important - do this first!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

## Step 6: Setup Project Directory

```bash
# Create directory for the application
mkdir -p ~/design-flow-credits-hub
cd ~/design-flow-credits-hub

# Create nginx config directory
mkdir -p nginx/ssl
```

## Step 7: Copy Configuration Files to EC2

From your local machine, copy necessary files:

```bash
# Copy docker-compose file
scp -i /path/to/your-key.pem \
    docker-compose.prod.yml \
    ubuntu@YOUR_EC2_PUBLIC_IP:~/design-flow-credits-hub/

# Copy nginx proxy configuration
scp -i /path/to/your-key.pem \
    nginx/nginx-proxy.conf \
    ubuntu@YOUR_EC2_PUBLIC_IP:~/design-flow-credits-hub/nginx/

# Copy SSL setup script
scp -i /path/to/your-key.pem \
    scripts/setup-ssl.sh \
    ubuntu@YOUR_EC2_PUBLIC_IP:~/
```

## Step 8: Setup DNS Records

Before setting up SSL, configure your DNS:

### In Your Domain Registrar's DNS Settings:

**For www.designuiux.com:**
```
Type: A
Name: www
Value: YOUR_EC2_PUBLIC_IP
TTL: 300 (5 minutes)
```

**For designuiux.com:**
```
Type: A
Name: @
Value: YOUR_EC2_PUBLIC_IP
TTL: 300 (5 minutes)
```

### Verify DNS Propagation

```bash
# From your local machine
nslookup www.designuiux.com
nslookup designuiux.com

# Both should return your EC2 IP
```

Wait for DNS to propagate (can take 5-60 minutes).

## Step 9: Setup SSL Certificates

```bash
# SSH into EC2
ssh -i /path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# Make script executable
chmod +x ~/setup-ssl.sh

# Run SSL setup (requires sudo)
sudo ~/setup-ssl.sh

# Follow the prompts:
# - Enter your email for certificate notifications
# - Certificates will be obtained for both domains
```

The script will:
- Install Certbot
- Obtain SSL certificates for both domains
- Setup automatic renewal (twice daily)

## Step 10: Login to DockerHub

```bash
# Login to DockerHub
docker login

# Enter your DockerHub username and password
```

## Step 11: Initial Deployment (Manual)

```bash
cd ~/design-flow-credits-hub

# Pull the latest image
docker pull YOUR_DOCKERHUB_USERNAME/design-flow-credits-hub:latest

# Start the application
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  YOUR_DOCKERHUB_USERNAME/design-flow-credits-hub:latest

# Verify container is running
docker ps

# Check logs
docker logs design-flow-app
```

## Step 12: Start Nginx Proxy with SSL

```bash
cd ~/design-flow-credits-hub

# Start nginx proxy and certbot renewal
docker compose -f docker-compose.prod.yml up -d nginx-proxy certbot

# Verify all containers are running
docker ps

# Should see:
# - design-flow-app
# - nginx-proxy
# - certbot
```

## Step 13: Verify Application

```bash
# Test HTTP to HTTPS redirect
curl -I http://www.designuiux.com
# Should return: 301 Moved Permanently

# Test HTTPS
curl -I https://www.designuiux.com
# Should return: 200 OK

# Test domain redirect
curl -I https://designuiux.com
# Should redirect to https://www.designuiux.com
```

Open in browser: https://www.designuiux.com

## Step 14: Setup GitHub Actions SSH Access

### Generate SSH Key (if not done already)

Your existing EC2 key pair will be used. Add it to GitHub Secrets:

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your DockerHub username
   - `DOCKERHUB_TOKEN`: DockerHub access token
   - `EC2_HOST`: Your EC2 public IP
   - `EC2_USER`: `ubuntu`
   - `EC2_SSH_KEY`: Contents of your .pem file
   - All Firebase environment variables (see ENVIRONMENT_VARS.md)

## EC2 Instance Monitoring

### View System Resources

```bash
# CPU and Memory usage
htop

# Disk usage
df -h

# Docker container stats
docker stats
```

### View Logs

```bash
# Application logs
docker logs -f design-flow-app

# Nginx proxy logs
docker logs -f nginx-proxy

# System logs
sudo journalctl -f
```

## Maintenance

### Update Docker Images

```bash
# Pull latest image
docker pull YOUR_DOCKERHUB_USERNAME/design-flow-credits-hub:latest

# Restart application
docker stop design-flow-app
docker rm design-flow-app
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  YOUR_DOCKERHUB_USERNAME/design-flow-credits-hub:latest
```

### Clean Up Docker Resources

```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Full cleanup (be careful!)
docker system prune -a --volumes
```

## Backup and Recovery

### Backup Strategy

Since the application uses Firebase, no database backup is needed on EC2. However:

1. **Configuration Backup**: Keep a copy of all config files
2. **SSL Certificates**: Backed up in `/etc/letsencrypt/`

### Create Snapshot

1. Go to AWS Console → EC2 → Volumes
2. Select your instance's volume
3. Actions → Create Snapshot
4. Tag and save

## Security Best Practices

1. **Regular Updates**:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

2. **Monitor Access Logs**:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

3. **Fail2ban** (Optional but recommended):
   ```bash
   sudo apt-get install -y fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

4. **Automatic Security Updates**:
   ```bash
   sudo apt-get install -y unattended-upgrades
   sudo dpkg-reconfigure --priority=low unattended-upgrades
   ```

## Cost Optimization

1. **Stop instance when not needed** (development only)
2. **Use Reserved Instances** for production (save up to 70%)
3. **Monitor billing** via AWS Cost Explorer
4. **Setup billing alerts** in AWS Console

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

## Next Steps

After EC2 setup is complete:
1. Configure GitHub Secrets (see [ENVIRONMENT_VARS.md](./ENVIRONMENT_VARS.md))
2. Push to main branch to trigger first automated deployment
3. Monitor GitHub Actions workflow
4. Verify deployment on https://www.designuiux.com
