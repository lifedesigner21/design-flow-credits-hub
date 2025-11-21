# Troubleshooting Guide

Common issues and solutions for the Design Flow Credits Hub deployment.

## Table of Contents

- [GitHub Actions Issues](#github-actions-issues)
- [Docker Build Issues](#docker-build-issues)
- [Deployment Issues](#deployment-issues)
- [SSL Certificate Issues](#ssl-certificate-issues)
- [Application Runtime Issues](#application-runtime-issues)
- [Firebase Issues](#firebase-issues)
- [Networking Issues](#networking-issues)
- [Performance Issues](#performance-issues)

---

## GitHub Actions Issues

### Issue: Workflow Not Triggering

**Symptoms**: Pushed to main but no workflow runs

**Causes & Solutions**:

1. **Check workflow file location**
   ```bash
   # Verify file exists
   ls -la .github/workflows/deploy.yml
   ```
   Must be exactly in `.github/workflows/` directory

2. **Check workflow syntax**
   ```bash
   # Validate YAML syntax online
   # Copy contents of deploy.yml to yamllint.com
   ```

3. **Check branch name**
   ```bash
   git branch
   # Ensure you're on 'main' branch
   # Workflow triggers only on 'main'
   ```

### Issue: GitHub Actions Failing at Build Step

**Symptoms**: Build fails with "Docker build failed"

**Check Build Logs**:
1. Go to Actions tab
2. Click failed workflow
3. Expand "Build and push Docker image"
4. Look for error message

**Common Causes**:

1. **Missing environment variables**
   ```
   Error: VITE_FIREBASE_API_KEY is not set
   ```
   **Solution**: Add missing secret in GitHub → Settings → Secrets

2. **NPM dependency issues**
   ```
   Error: Cannot find module 'package-name'
   ```
   **Solution**:
   ```bash
   # Ensure package-lock.json is committed
   git add package-lock.json
   git commit -m "Add package-lock.json"
   git push
   ```

3. **Build errors in code**
   ```
   Error: TypeScript compilation failed
   ```
   **Solution**: Fix TypeScript errors locally first
   ```bash
   npm run build
   # Fix any errors shown
   ```

### Issue: DockerHub Push Failed

**Symptoms**: "unauthorized: incorrect username or password"

**Solutions**:

1. **Verify DockerHub credentials**
   - Go to GitHub → Settings → Secrets
   - Check `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
   - Ensure token hasn't expired

2. **Create new DockerHub token**
   - Login to hub.docker.com
   - Account Settings → Security → New Access Token
   - Update `DOCKERHUB_TOKEN` in GitHub Secrets

3. **Verify DockerHub username format**
   - Should be just username, not email
   - Example: `johndoe` not `johndoe@email.com`

### Issue: SSH Connection to EC2 Failed

**Symptoms**: "Permission denied (publickey)" or "Connection refused"

**Solutions**:

1. **Check EC2_SSH_KEY format**
   - Must include `-----BEGIN RSA PRIVATE KEY-----`
   - Must include `-----END RSA PRIVATE KEY-----`
   - No extra spaces or characters

2. **Verify EC2 security group**
   ```bash
   # Check if EC2 allows SSH from GitHub IPs
   # AWS Console → EC2 → Security Groups
   # Inbound rule: SSH (22) from 0.0.0.0/0 or GitHub IPs
   ```

3. **Check EC2_HOST is correct**
   - Should be public IP, not private IP
   - Verify in AWS Console → EC2 → Instances

4. **Test SSH manually**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   # If this fails, fix EC2 access first
   ```

---

## Docker Build Issues

### Issue: Build Fails Locally

**Symptoms**: `docker build` command fails

**Solutions**:

1. **Check Docker is running**
   ```bash
   docker --version
   docker ps
   ```

2. **Check Dockerfile syntax**
   ```bash
   # Build with verbose output
   docker build --no-cache -t test-image .
   ```

3. **Clear Docker cache**
   ```bash
   docker builder prune -a
   docker build -t test-image .
   ```

### Issue: Image Size Too Large

**Symptoms**: Docker image > 1GB

**Solutions**:

1. **Check .dockerignore**
   ```bash
   cat .dockerignore
   # Ensure node_modules is excluded
   ```

2. **Use multi-stage build** (already implemented)
   - Build stage has all dependencies
   - Final stage has only built assets + nginx

3. **Check for large files**
   ```bash
   # Find large files in repo
   find . -type f -size +10M
   ```

---

## Deployment Issues

### Issue: Container Won't Start

**Symptoms**: Container starts then immediately exits

**Check Logs**:
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
docker logs design-flow-app
```

**Common Causes**:

1. **Port already in use**
   ```bash
   # Check if port 3000 is in use
   sudo lsof -i :3000

   # Kill process using the port
   sudo kill -9 PID
   ```

2. **Missing environment variables in container**
   ```bash
   # Check container environment
   docker inspect design-flow-app | grep -A 20 "Env"
   ```

3. **Nginx configuration error**
   ```bash
   # Test nginx config
   docker exec design-flow-app nginx -t
   ```

### Issue: Container Runs But Shows 502 Bad Gateway

**Symptoms**: Nginx returns 502 when accessing site

**Solutions**:

1. **Check if app container is running**
   ```bash
   docker ps | grep design-flow-app
   ```

2. **Check app container logs**
   ```bash
   docker logs design-flow-app
   ```

3. **Check nginx-proxy logs**
   ```bash
   docker logs nginx-proxy
   ```

4. **Verify internal networking**
   ```bash
   # Check if nginx can reach app
   docker exec nginx-proxy ping app
   ```

5. **Restart containers**
   ```bash
   docker restart design-flow-app
   docker restart nginx-proxy
   ```

### Issue: Deployment Succeeds But Site Not Updated

**Symptoms**: Push succeeded but site shows old version

**Solutions**:

1. **Clear browser cache**
   - Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
   - Clear browser cache completely

2. **Check image tag deployed**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   docker ps | grep design-flow-app
   # Check IMAGE column shows :latest
   ```

3. **Verify container was restarted**
   ```bash
   docker ps -a | grep design-flow-app
   # Check STATUS and uptime
   ```

4. **Force pull latest image**
   ```bash
   docker pull YOUR_USERNAME/design-flow-credits-hub:latest
   docker restart design-flow-app
   ```

---

## SSL Certificate Issues

### Issue: SSL Certificate Not Found

**Symptoms**: "SSL certificate not found" or "cert.pem not found"

**Solutions**:

1. **Check if certificates exist**
   ```bash
   sudo ls -la /etc/letsencrypt/live/www.designuiux.com/
   sudo ls -la /etc/letsencrypt/live/designuiux.com/
   ```

2. **Run SSL setup script**
   ```bash
   sudo ~/setup-ssl.sh
   ```

3. **Verify DNS is pointing to EC2**
   ```bash
   nslookup www.designuiux.com
   nslookup designuiux.com
   # Both should return EC2 public IP
   ```

### Issue: Certificate Expired

**Symptoms**: Browser shows "Certificate expired" warning

**Solutions**:

1. **Check certificate expiry**
   ```bash
   sudo certbot certificates
   ```

2. **Renew certificate manually**
   ```bash
   sudo certbot renew
   docker exec nginx-proxy nginx -s reload
   ```

3. **Check auto-renewal cron**
   ```bash
   crontab -l | grep certbot
   # Should show: 0 0,12 * * * /usr/local/bin/renew-ssl.sh
   ```

4. **Test renewal**
   ```bash
   sudo certbot renew --dry-run
   ```

### Issue: Mixed Content Errors

**Symptoms**: "Mixed Content" warnings in browser console

**Solutions**:

1. **Ensure all resources use HTTPS**
   - Check external CDN links
   - Firebase automatically uses HTTPS

2. **Check nginx configuration**
   ```bash
   # Verify X-Forwarded-Proto header
   docker exec nginx-proxy cat /etc/nginx/nginx.conf | grep X-Forwarded-Proto
   ```

---

## Application Runtime Issues

### Issue: White Screen / Blank Page

**Symptoms**: Site loads but shows nothing

**Check Browser Console**:
1. Open DevTools (F12)
2. Check Console tab for errors

**Common Causes**:

1. **Firebase initialization error**
   ```
   Error: Firebase App not initialized
   ```
   **Solution**: Check environment variables (see ENVIRONMENT_VARS.md)

2. **JavaScript errors**
   ```
   Uncaught ReferenceError: X is not defined
   ```
   **Solution**: Fix the error in code and redeploy

3. **Router configuration issue**
   - Check `src/App.tsx` routing setup
   - Verify nginx.conf has `try_files $uri $uri/ /index.html;`

### Issue: Authentication Not Working

**Symptoms**: Can't login with Google

**Solutions**:

1. **Check Firebase configuration**
   ```bash
   # Verify Firebase env vars are set
   # See ENVIRONMENT_VARS.md
   ```

2. **Check authorized domains in Firebase**
   - Firebase Console → Authentication → Settings
   - Add `www.designuiux.com` and `designuiux.com` to authorized domains

3. **Check browser console for auth errors**
   - Open DevTools → Console
   - Look for Firebase auth errors

### Issue: Firestore Permissions Error

**Symptoms**: "Missing or insufficient permissions"

**Solutions**:

1. **Check Firestore security rules**
   - Firebase Console → Firestore → Rules
   - Ensure rules allow authenticated users

2. **Verify user is authenticated**
   ```javascript
   // Check in browser console
   firebase.auth().currentUser
   ```

3. **Check user role/permissions**
   - Verify user document in Firestore has correct role

---

## Firebase Issues

### Issue: Firebase Quota Exceeded

**Symptoms**: "Quota exceeded" error

**Solutions**:

1. **Check Firebase usage**
   - Firebase Console → Usage tab
   - See which quota is exceeded

2. **Upgrade Firebase plan**
   - Blaze plan for production recommended
   - Pay-as-you-go pricing

3. **Optimize queries**
   - Add indexes for common queries
   - Limit query results
   - Implement pagination

### Issue: Firebase Rules Rejecting Requests

**Symptoms**: All database operations fail

**Temporary Fix** (TESTING ONLY):
```javascript
// Firebase Console → Firestore → Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Production Fix**:
- Implement proper role-based rules
- See Firebase documentation for security rules

---

## Networking Issues

### Issue: Can't Access Site

**Symptoms**: "This site can't be reached"

**Solutions**:

1. **Check DNS**
   ```bash
   nslookup www.designuiux.com
   # Should return EC2 IP
   ```

2. **Check EC2 is running**
   - AWS Console → EC2 → Instances
   - Verify instance state is "running"

3. **Check Security Group**
   - Inbound rules must allow:
     - Port 80 (HTTP) from 0.0.0.0/0
     - Port 443 (HTTPS) from 0.0.0.0/0

4. **Check nginx is running**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   docker ps | grep nginx-proxy
   ```

5. **Check DNS propagation**
   - Use: https://www.whatsmydns.net/
   - Enter: www.designuiux.com
   - Verify it resolves to EC2 IP globally

### Issue: Slow Loading Times

**Symptoms**: Site takes >5 seconds to load

**Solutions**:

1. **Check EC2 instance resources**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   htop  # CPU and RAM usage
   ```

2. **Check Docker container resources**
   ```bash
   docker stats
   ```

3. **Consider upgrading EC2 instance**
   - From t3.small to t3.medium or larger
   - More CPU and RAM

4. **Enable CloudFront CDN**
   - AWS CloudFront in front of EC2
   - Caches static assets globally

---

## Performance Issues

### Issue: High Memory Usage

**Symptoms**: EC2 running out of memory

**Solutions**:

1. **Check memory usage**
   ```bash
   free -h
   docker stats
   ```

2. **Restart containers**
   ```bash
   docker restart design-flow-app
   docker restart nginx-proxy
   ```

3. **Clean up Docker resources**
   ```bash
   docker system prune -a
   ```

4. **Upgrade EC2 instance**
   - Increase RAM by choosing larger instance type

### Issue: High CPU Usage

**Symptoms**: Site slow, EC2 CPU at 100%

**Solutions**:

1. **Check what's using CPU**
   ```bash
   top
   docker stats
   ```

2. **Check application logs for errors**
   ```bash
   docker logs design-flow-app | tail -100
   ```

3. **Optimize Firestore queries**
   - Add composite indexes
   - Limit query results
   - Implement pagination

---

## Emergency Procedures

### Complete System Failure

If everything is broken:

1. **Check GitHub Actions logs** - What failed?
2. **SSH to EC2** - Is server accessible?
3. **Check Docker** - Are containers running?
4. **Check logs** - What errors are shown?
5. **Rollback** - Deploy previous working version

### Rollback Procedure

```bash
# Option 1: Revert via Git
git revert HEAD
git push origin main

# Option 2: Manual rollback on EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
docker pull YOUR_USERNAME/design-flow-credits-hub:PREVIOUS_SHA
docker stop design-flow-app
docker rm design-flow-app
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  YOUR_USERNAME/design-flow-credits-hub:PREVIOUS_SHA
```

### Nuclear Option: Complete Rebuild

If nothing works:

```bash
# On EC2
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)

# Pull fresh image
docker pull YOUR_USERNAME/design-flow-credits-hub:latest

# Start fresh
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  YOUR_USERNAME/design-flow-credits-hub:latest

# Restart nginx
cd ~/design-flow-credits-hub
docker compose -f docker-compose.prod.yml up -d nginx-proxy
```

---

## Getting More Help

### Useful Commands Reference

```bash
# View container logs
docker logs -f design-flow-app

# Check container status
docker ps -a

# Check resource usage
docker stats

# Restart container
docker restart design-flow-app

# Check nginx config
docker exec nginx-proxy nginx -t

# View recent system logs
sudo journalctl -u docker -n 100

# Check disk space
df -h

# Check memory
free -h

# Network connectivity test
curl -I https://www.designuiux.com
```

### Log Locations

- **Application logs**: `docker logs design-flow-app`
- **Nginx logs**: `docker logs nginx-proxy`
- **SSL renewal logs**: `/var/log/certbot-renewal.log`
- **System logs**: `sudo journalctl -f`

### Monitoring Tools

1. **GitHub Actions logs** - Build and deployment
2. **Docker logs** - Runtime errors
3. **Browser DevTools** - Frontend errors
4. **Firebase Console** - Database errors
5. **AWS CloudWatch** - EC2 metrics (if enabled)

---

## Prevention Tips

1. **Test locally before deploying**
   ```bash
   npm run lint
   npm run build
   npm run preview
   ```

2. **Use feature branches for big changes**
   ```bash
   git checkout -b feature/new-feature
   # Make changes, test, then merge to main
   ```

3. **Monitor deployments**
   - Watch GitHub Actions after each push
   - Check application after deployment

4. **Keep backups**
   - EC2 snapshots weekly
   - Export Firestore data monthly

5. **Regular maintenance**
   - Update dependencies monthly
   - Renew SSL certs (automatic)
   - Clean up Docker images weekly

---

## Still Having Issues?

1. Check all documentation:
   - [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
   - [EC2_SETUP.md](./EC2_SETUP.md)
   - [MAKING_CHANGES.md](./MAKING_CHANGES.md)
   - [ENVIRONMENT_VARS.md](./ENVIRONMENT_VARS.md)

2. Review GitHub Actions logs carefully

3. Check Docker and application logs

4. Verify all secrets are configured correctly

5. Test each component individually:
   - GitHub Actions build
   - Docker image locally
   - EC2 connectivity
   - DNS resolution
   - SSL certificates
