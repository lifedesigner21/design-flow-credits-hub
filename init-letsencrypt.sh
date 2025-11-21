#!/bin/bash

# SSL Certificate Setup Script for Docker Compose
# This script handles the initial Let's Encrypt SSL certificate setup

set -e

domains=(designuiux.com www.designuiux.com)
rsa_key_size=4096
data_path="./nginx/ssl"
email="pod.support@lifedesigner.io" # Change this!
staging=0 # Set to 1 if you're testing to avoid rate limits

echo "### Preparing SSL setup for ${domains[0]} ..."

# Create necessary directories
mkdir -p "$data_path"
mkdir -p "/var/www/certbot"

# Generate self-signed certificate for initial nginx startup
if [ ! -e "$data_path/self-signed.crt" ]; then
  echo "### Creating self-signed certificate for initial setup ..."
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
    -keyout "$data_path/self-signed.key" \
    -out "$data_path/self-signed.crt" \
    -subj "/CN=${domains[0]}"
  echo
fi

# Start nginx-proxy and app containers (without certbot for now)
echo "### Starting nginx-proxy and app containers ..."
docker-compose -f docker-compose.prod.yml up -d app nginx-proxy

# Wait for nginx to be ready
echo "### Waiting for nginx to start ..."
sleep 5

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/${domains[0]}" ]; then
  echo "### Certificate already exists for ${domains[0]}, skipping generation ..."
else
  echo "### Requesting Let's Encrypt certificate for ${domains[0]} ..."

  # Join domains for certbot
  domain_args=""
  for domain in "${domains[@]}"; do
    domain_args="$domain_args -d $domain"
  done

  # Select appropriate email arg
  case "$email" in
    "your-email@example.com") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $email" ;;
  esac

  # Enable staging mode if needed
  if [ $staging != "0" ]; then staging_arg="--staging"; fi

  # Request certificate
  docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal \
    --non-interactive

  echo
  echo "### Certificate obtained successfully!"
fi

# Reload nginx to use the new certificate
echo "### Reloading nginx configuration ..."
docker-compose -f docker-compose.prod.yml exec nginx-proxy nginx -s reload

echo "### Starting certbot renewal service ..."
docker-compose -f docker-compose.prod.yml up -d certbot

echo
echo "### SSL setup complete!"
echo "### Your site should now be accessible at https://${domains[0]}"
echo
echo "Note: If you used staging mode, remember to:"
echo "1. Set staging=0 in this script"
echo "2. Delete /etc/letsencrypt directory"
echo "3. Run this script again to get production certificates"
