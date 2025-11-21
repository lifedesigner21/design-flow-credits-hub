# Making Changes Guide

This guide explains how to make changes to your application and deploy them to production.

## Quick Start

The simplest workflow for making changes:

```bash
# 1. Make your code changes
# 2. Test locally
npm run dev

# 3. Commit your changes
git add .
git commit -m "Your change description"

# 4. Push to main branch
git push origin main

# 5. GitHub Actions automatically builds and deploys
# 6. Check GitHub Actions for deployment status
# 7. Verify on https://www.designuiux.com
```

That's it! The pipeline handles everything else automatically.

## Detailed Workflow

### 1. Local Development

#### Start Development Server
```bash
npm run dev
```

The app runs on http://localhost:8080

#### Make Your Changes
- Edit React components in `src/`
- Update styles in component files or `src/index.css`
- Modify Firebase logic in `src/lib/firebase.js`
- Add new routes in `src/App.tsx`

#### Test Locally
```bash
# Run linter
npm run lint

# Build to verify no errors
npm run build

# Preview production build
npm run preview
```

### 2. Commit Your Changes

```bash
# Check what files changed
git status

# Stage your changes
git add .

# Commit with descriptive message
git commit -m "Add feature: user profile editing"

# Or commit specific files
git add src/components/UserProfile.tsx
git commit -m "Fix: profile image upload issue"
```

### 3. Push to GitHub

```bash
# Push to main branch (triggers deployment)
git push origin main
```

### 4. Monitor Deployment

#### Watch GitHub Actions
1. Go to your GitHub repository
2. Click "Actions" tab
3. See your workflow running in real-time
4. Click on the workflow to see detailed logs

#### Deployment Steps You'll See
1. **Build and Push** (3-5 minutes)
   - Checkout code
   - Build Docker image
   - Push to DockerHub

2. **Deploy to EC2** (1-2 minutes)
   - SSH to EC2
   - Pull latest image
   - Stop old container
   - Start new container
   - Health check

3. **Success!**
   - Total time: 4-7 minutes

### 5. Verify Changes

```bash
# Check deployment logs
# SSH to EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# View container logs
docker logs design-flow-app

# Verify container is running
docker ps
```

Visit https://www.designuiux.com to see your changes live!

## Making Different Types of Changes

### UI/Component Changes

**Example: Update Header Component**

```bash
# Edit the component
nano src/components/layout/Header.tsx

# Test locally
npm run dev

# Commit and push
git add src/components/layout/Header.tsx
git commit -m "Update header navigation styling"
git push origin main
```

### Adding New Features

**Example: Add New Page**

```bash
# 1. Create new page component
touch src/pages/NewFeature.tsx

# 2. Add route in App.tsx
nano src/App.tsx

# 3. Test locally
npm run dev

# 4. Lint and build
npm run lint
npm run build

# 5. Commit all changes
git add src/pages/NewFeature.tsx src/App.tsx
git commit -m "Add new feature page with routing"
git push origin main
```

### Updating Dependencies

```bash
# Update a specific package
npm install package-name@latest

# Update all packages (be careful!)
npm update

# Test thoroughly
npm run dev
npm run build

# Commit package files
git add package.json package-lock.json
git commit -m "Update dependencies: package-name to vX.X.X"
git push origin main
```

### Fixing Bugs

```bash
# 1. Create a branch for the fix (optional but recommended)
git checkout -b fix/bug-description

# 2. Make your fix
nano src/path/to/buggy-file.tsx

# 3. Test the fix
npm run dev

# 4. Commit
git add src/path/to/buggy-file.tsx
git commit -m "Fix: description of bug and solution"

# 5. Merge to main
git checkout main
git merge fix/bug-description

# 6. Push to deploy
git push origin main
```

### Modifying Styles

```bash
# Global styles
nano src/index.css

# Tailwind config
nano tailwind.config.ts

# Component-specific styles (inline with Tailwind)
nano src/components/YourComponent.tsx

# Test and deploy
npm run dev
git add .
git commit -m "Update styling: improved responsive design"
git push origin main
```

## Environment Variable Changes

**IMPORTANT**: Environment variables are NOT in the code!

### Updating Firebase Configuration

If you need to change Firebase config:

1. **Update GitHub Secrets**:
   - Go to GitHub → Settings → Secrets and variables → Actions
   - Update the relevant `VITE_FIREBASE_*` secrets

2. **Trigger Rebuild**:
   ```bash
   # Make a small change to force rebuild
   git commit --allow-empty -m "Trigger rebuild for env var update"
   git push origin main
   ```

See [ENVIRONMENT_VARS.md](./ENVIRONMENT_VARS.md) for details.

## Docker/Infrastructure Changes

### Modifying Dockerfile

```bash
# Edit Dockerfile
nano Dockerfile

# Test build locally
docker build -t test-image .

# Run test container
docker run -p 8080:80 test-image

# If it works, commit and push
git add Dockerfile
git commit -m "Update Dockerfile: optimize build layers"
git push origin main
```

### Changing Nginx Configuration

```bash
# Edit nginx config
nano nginx.conf

# Test locally (if using Docker)
docker build -t test-nginx .
docker run -p 8080:80 test-nginx

# Deploy
git add nginx.conf
git commit -m "Update nginx: add caching headers"
git push origin main
```

### Updating CI/CD Pipeline

```bash
# Edit workflow
nano .github/workflows/deploy.yml

# Commit and push
git add .github/workflows/deploy.yml
git commit -m "Update CI/CD: add testing step"
git push origin main
```

## Deployment Best Practices

### 1. Test Before Deploying

Always test locally before pushing to main:
```bash
npm run lint        # Check for code issues
npm run build       # Ensure build succeeds
npm run preview     # Test production build locally
```

### 2. Commit Message Guidelines

Write clear commit messages:

**Good Examples:**
```bash
git commit -m "Add feature: CSV export for projects"
git commit -m "Fix: authentication timeout issue"
git commit -m "Update: improve mobile responsive design"
git commit -m "Refactor: optimize Firebase queries for performance"
```

**Bad Examples:**
```bash
git commit -m "changes"
git commit -m "fix stuff"
git commit -m "update"
```

### 3. Deploy During Low-Traffic Periods

For major changes:
- Deploy during off-peak hours
- Monitor for errors after deployment
- Keep an eye on GitHub Actions logs

### 4. Small, Incremental Changes

Instead of:
- One huge commit with 50 file changes

Do:
- Multiple smaller commits, each with a specific purpose
- Easier to track issues
- Easier to rollback if needed

### 5. Use Feature Branches (Recommended)

```bash
# Create feature branch
git checkout -b feature/user-dashboard

# Make changes and commit
git add .
git commit -m "Add user dashboard layout"

# Push feature branch
git push origin feature/user-dashboard

# Create Pull Request on GitHub
# Review changes
# Merge to main when ready (triggers deployment)
```

## Monitoring After Deployment

### Check Application Logs

```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# View real-time logs
docker logs -f design-flow-app

# View last 100 lines
docker logs --tail 100 design-flow-app
```

### Check Container Health

```bash
# Check if container is running
docker ps | grep design-flow-app

# Check container resource usage
docker stats design-flow-app
```

### Test Application

```bash
# Test HTTP to HTTPS redirect
curl -I http://www.designuiux.com

# Test HTTPS response
curl -I https://www.designuiux.com

# Test specific endpoint
curl https://www.designuiux.com/health
```

### Monitor GitHub Actions

- Check Actions tab for deployment status
- Review build logs for errors
- Verify deployment completed successfully

## Emergency Rollback

If your changes break production, rollback immediately:

### Option 1: Revert via Git
```bash
# Revert the last commit
git revert HEAD

# Push to trigger new deployment with reverted changes
git push origin main
```

### Option 2: Manual Rollback on EC2
```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Find the previous working image SHA from GitHub Actions history
# Deploy that image
docker pull YOUR_USERNAME/design-flow-credits-hub:PREVIOUS_SHA
docker stop design-flow-app
docker rm design-flow-app
docker run -d \
  --name design-flow-app \
  --restart unless-stopped \
  -p 3000:80 \
  YOUR_USERNAME/design-flow-credits-hub:PREVIOUS_SHA
```

## Common Scenarios

### Scenario 1: Quick Text Change

```bash
# Edit file
nano src/components/Header.tsx

# Save, commit, push
git add src/components/Header.tsx
git commit -m "Update header text"
git push origin main

# Wait 5 minutes, check website
```

### Scenario 2: Adding New NPM Package

```bash
# Install package
npm install new-package

# Use in code
# Test locally
npm run dev

# Commit package files
git add package.json package-lock.json src/
git commit -m "Add new-package for feature X"
git push origin main
```

### Scenario 3: Update Firebase Security Rules

Firebase rules are managed in Firebase Console, not in code:
1. Go to Firebase Console
2. Navigate to Firestore → Rules
3. Update rules
4. Publish

No code deployment needed!

### Scenario 4: Database Schema Changes

Since you're using Firestore (NoSQL), there's no schema:
- Just update your TypeScript types in `src/types/`
- Update code to handle new structure
- Deploy via normal git push

```bash
git add src/types/
git commit -m "Update types: add new user profile fields"
git push origin main
```

## Getting Help

If you encounter issues:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review GitHub Actions logs
3. Check EC2 container logs
4. Review Firebase logs in Firebase Console

## Summary

**The Golden Rule**:
> Push to `main` = Automatic deployment to production in ~5 minutes

Always:
- ✅ Test locally first
- ✅ Write clear commit messages
- ✅ Monitor deployment in GitHub Actions
- ✅ Verify changes on live site
- ✅ Check logs if something seems wrong
