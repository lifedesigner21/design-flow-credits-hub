# SSL Setup Commands for designuiux.com

## Run These Commands on Your EC2 Server

### Step 1: Get SSL Certificate

```bash
# Make sure containers are stopped
docker stop design-flow-app

# Make sure nothing is on port 80
sudo lsof -i :80

# Get SSL certificate
sudo certbot certonly --standalone \
  -d designuiux.com \
  --email pod.support@lifedesigner.io \
  --agree-tos \
  --non-interactive
```

**Expected Output:**
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/designuiux.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/designuiux.com/privkey.pem
```

---

### Step 2: Create Nginx Config Directory

```bash
mkdir -p ~/design-flow-credits-hub/nginx
```

---

### Step 3: Copy nginx-proxy.conf to EC2

From your local machine:

```bash
scp -i /path/to/your-key.pem \
  nginx/nginx-proxy.conf \
  ubuntu@YOUR_EC2_IP:~/design-flow-credits-hub/nginx/
```

---

### Step 4: Restart Application Container

```bash
docker start design-flow-app
```

---

### Step 5: Start Nginx Proxy with SSL

```bash
docker run -d \
  --name nginx-proxy \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v ~/design-flow-credits-hub/nginx/nginx-proxy.conf:/etc/nginx/nginx.conf:ro \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  -v /var/www/certbot:/var/www/certbot \
  --link design-flow-app:app \
  nginx:alpine
```

---

### Step 6: Verify Everything is Running

```bash
docker ps
```

You should see:
- `design-flow-app` (running)
- `nginx-proxy` (running)

---

### Step 7: Test Your Site

```bash
# Test HTTP redirect
curl -I http://designuiux.com
# Should return: 301 Moved Permanently

# Test HTTPS
curl -I https://designuiux.com
# Should return: 200 OK
```

**Open in browser:** https://designuiux.com

---

## Setup Auto-Renewal

### Create Renewal Script

```bash
sudo tee /usr/local/bin/renew-ssl.sh > /dev/null << 'EOF'
#!/bin/bash
# Stop containers
docker stop design-flow-app nginx-proxy
# Renew certificate
certbot renew --quiet --standalone
# Restart containers
docker start design-flow-app nginx-proxy
EOF

sudo chmod +x /usr/local/bin/renew-ssl.sh
```

### Add Cron Job

```bash
sudo crontab -e
```

Add this line:
```
0 3 * * * /usr/local/bin/renew-ssl.sh >> /var/log/certbot-renewal.log 2>&1
```

---

## Troubleshooting

### If Port 80 is Still Busy

```bash
# Check what's using port 80
sudo lsof -i :80

# Stop nginx if it exists
sudo systemctl stop nginx
sudo systemctl disable nginx

# Stop all containers
docker stop $(docker ps -aq)
```

### If Certificate Fails

Check DNS:
```bash
nslookup designuiux.com
# Should return your EC2 IP
```

### View Nginx Logs

```bash
docker logs nginx-proxy
```

### Restart Everything

```bash
docker restart design-flow-app nginx-proxy
```

---

## Final Result

- ✅ http://designuiux.com → https://designuiux.com (redirect)
- ✅ https://designuiux.com → Your app (secure!)
- ✅ SSL certificate auto-renews every 60 days
- ✅ A+ SSL rating

Done! 🎉
