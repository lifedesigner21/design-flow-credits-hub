#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Let's Encrypt SSL Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root or with sudo${NC}"
    exit 1
fi

# Prompt for email
read -p "Enter your email address for SSL certificate notifications: " EMAIL

if [ -z "$EMAIL" ]; then
    echo -e "${RED}Email is required!${NC}"
    exit 1
fi

# Domain configuration
DOMAIN="designuiux.com"

echo -e "${YELLOW}Installing Certbot...${NC}"
apt-get update
apt-get install -y certbot

# Create web root for ACME challenge
mkdir -p /var/www/certbot

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Obtaining SSL certificate for ${DOMAIN}${NC}"
echo -e "${BLUE}========================================${NC}"

# Stop any running containers on port 80
echo -e "${YELLOW}Stopping containers to free port 80...${NC}"
docker stop $(docker ps -q) 2>/dev/null || true

# Get certificate for designuiux.com using standalone mode
certbot certonly --standalone \
    -d ${DOMAIN} \
    --email ${EMAIL} \
    --agree-tos \
    --non-interactive \
    --force-renewal

# Restart containers
echo -e "${YELLOW}Restarting application...${NC}"
docker start design-flow-app 2>/dev/null || true

# Set up auto-renewal cron job
echo -e "${YELLOW}Setting up automatic certificate renewal...${NC}"

# Create renewal script
cat > /usr/local/bin/renew-ssl.sh << 'SCRIPT'
#!/bin/bash
# Stop containers to free port 80
docker stop $(docker ps -q) 2>/dev/null
# Renew certificate
certbot renew --quiet --standalone
# Restart containers
docker start design-flow-app nginx-proxy 2>/dev/null
SCRIPT

chmod +x /usr/local/bin/renew-ssl.sh

# Add cron job (run twice daily)
(crontab -l 2>/dev/null; echo "0 0,12 * * * /usr/local/bin/renew-ssl.sh >> /var/log/certbot-renewal.log 2>&1") | crontab -

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SSL Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Certificate obtained for:${NC}"
echo -e "${GREEN}  - ${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Certificate location:${NC}"
echo -e "  /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo -e "  /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
echo ""
echo -e "${YELLOW}Auto-renewal configured to run twice daily${NC}"
echo -e "${YELLOW}Manual renewal command: sudo /usr/local/bin/renew-ssl.sh${NC}"
echo ""
echo -e "${GREEN}You can now start your nginx-proxy container${NC}"
echo -e "${GREEN}Command: docker start nginx-proxy${NC}"
