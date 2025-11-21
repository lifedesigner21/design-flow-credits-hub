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
DOMAIN1="www.designuiux.com"
DOMAIN2="designuiux.com"

echo -e "${YELLOW}Installing Certbot...${NC}"
apt-get update
apt-get install -y certbot

# Create web root for ACME challenge
mkdir -p /var/www/certbot

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Obtaining SSL certificate for ${DOMAIN1}${NC}"
echo -e "${BLUE}========================================${NC}"

# Get certificate for www.designuiux.com
certbot certonly --webroot \
    -w /var/www/certbot \
    -d ${DOMAIN1} \
    --email ${EMAIL} \
    --agree-tos \
    --non-interactive \
    --force-renewal

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Obtaining SSL certificate for ${DOMAIN2}${NC}"
echo -e "${BLUE}========================================${NC}"

# Get certificate for designuiux.com
certbot certonly --webroot \
    -w /var/www/certbot \
    -d ${DOMAIN2} \
    --email ${EMAIL} \
    --agree-tos \
    --non-interactive \
    --force-renewal

# Set up auto-renewal cron job
echo -e "${YELLOW}Setting up automatic certificate renewal...${NC}"

# Create renewal script
cat > /usr/local/bin/renew-ssl.sh << 'SCRIPT'
#!/bin/bash
certbot renew --quiet --webroot -w /var/www/certbot
if [ $? -eq 0 ]; then
    docker exec nginx-proxy nginx -s reload
fi
SCRIPT

chmod +x /usr/local/bin/renew-ssl.sh

# Add cron job (run twice daily)
(crontab -l 2>/dev/null; echo "0 0,12 * * * /usr/local/bin/renew-ssl.sh >> /var/log/certbot-renewal.log 2>&1") | crontab -

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SSL Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Certificates obtained for:${NC}"
echo -e "${GREEN}  - ${DOMAIN1}${NC}"
echo -e "${GREEN}  - ${DOMAIN2}${NC}"
echo ""
echo -e "${YELLOW}Certificate locations:${NC}"
echo -e "  /etc/letsencrypt/live/${DOMAIN1}/fullchain.pem"
echo -e "  /etc/letsencrypt/live/${DOMAIN1}/privkey.pem"
echo -e "  /etc/letsencrypt/live/${DOMAIN2}/fullchain.pem"
echo -e "  /etc/letsencrypt/live/${DOMAIN2}/privkey.pem"
echo ""
echo -e "${YELLOW}Auto-renewal configured to run twice daily${NC}"
echo -e "${YELLOW}Manual renewal command: certbot renew${NC}"
echo ""
echo -e "${GREEN}You can now restart your nginx-proxy container${NC}"
echo -e "${GREEN}Command: docker restart nginx-proxy${NC}"
