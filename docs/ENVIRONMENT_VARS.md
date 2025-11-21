# Environment Variables Management

This guide explains how environment variables are managed in the Design Flow Credits Hub application.

## Overview

Environment variables contain sensitive configuration like Firebase credentials. They are:
- **NOT stored in code** (security risk)
- **Stored in GitHub Secrets** (encrypted)
- **Injected during Docker build** (via build arguments)
- **Embedded in the built JavaScript** (safe for client-side Firebase)

## Architecture

```
GitHub Secrets → GitHub Actions → Docker Build Args → Vite Build → Embedded in JS Bundle
```

## Required Environment Variables

### Firebase Configuration

All variables are **REQUIRED** for the application to work:

| Variable Name                        | Description                    | Example                                |
|--------------------------------------|--------------------------------|----------------------------------------|
| `VITE_FIREBASE_API_KEY`              | Firebase API Key               | `AIzaSyXxxx...`                        |
| `VITE_FIREBASE_AUTH_DOMAIN`          | Firebase Auth Domain           | `your-project.firebaseapp.com`         |
| `VITE_FIREBASE_PROJECT_ID`           | Firebase Project ID            | `your-project-id`                      |
| `VITE_FIREBASE_STORAGE_BUCKET`       | Firebase Storage Bucket        | `your-project.appspot.com`             |
| `VITE_FIREBASE_MESSAGING_SENDER_ID`  | Firebase Messaging Sender ID   | `123456789`                            |
| `VITE_FIREBASE_APP_ID`               | Firebase App ID                | `1:123456789:web:xxxxx`                |
| `VITE_FIREBASE_MEASUREMENT_ID`       | Firebase Analytics ID          | `G-XXXXXXXXXX`                         |

### Deployment Configuration

| Variable Name       | Description                    | Example                          |
|---------------------|--------------------------------|----------------------------------|
| `DOCKERHUB_USERNAME`| Your DockerHub username        | `johndoe`                        |
| `DOCKERHUB_TOKEN`   | DockerHub access token         | `dckr_pat_xxxxx`                 |
| `EC2_HOST`          | EC2 instance public IP         | `52.12.34.56`                    |
| `EC2_USER`          | SSH username for EC2           | `ubuntu`                         |
| `EC2_SSH_KEY`       | Private SSH key for EC2        | `-----BEGIN RSA PRIVATE KEY---` |

## Getting Firebase Credentials

### Step 1: Access Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project (`credit-tracker-236c3`)
3. Click on Settings (gear icon) → Project settings

### Step 2: Find Configuration
1. Scroll down to "Your apps" section
2. Select your web app
3. Under "SDK setup and configuration", select "Config"
4. Copy the configuration values

### Step 3: Extract Values
From the Firebase config object:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",           // → VITE_FIREBASE_API_KEY
  authDomain: "xxx.firebaseapp.com", // → VITE_FIREBASE_AUTH_DOMAIN
  projectId: "xxx",              // → VITE_FIREBASE_PROJECT_ID
  storageBucket: "xxx.appspot.com", // → VITE_FIREBASE_STORAGE_BUCKET
  messagingSenderId: "123456",   // → VITE_FIREBASE_MESSAGING_SENDER_ID
  appId: "1:123:web:xxx",        // → VITE_FIREBASE_APP_ID
  measurementId: "G-XXX"         // → VITE_FIREBASE_MEASUREMENT_ID
};
```

## Setting Up GitHub Secrets

### Step 1: Navigate to Secrets
1. Go to your GitHub repository
2. Click **Settings** tab
3. Navigate to **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: Add Each Secret

For each environment variable:

**Example: Adding Firebase API Key**

```
Name:  VITE_FIREBASE_API_KEY
Value: AIzaSyCk4mKaqaYNbtAeeCY77hhRhHlaVZXgCJg
```

Click "Add secret"

**Repeat for all variables:**

1. `VITE_FIREBASE_API_KEY`
2. `VITE_FIREBASE_AUTH_DOMAIN`
3. `VITE_FIREBASE_PROJECT_ID`
4. `VITE_FIREBASE_STORAGE_BUCKET`
5. `VITE_FIREBASE_MESSAGING_SENDER_ID`
6. `VITE_FIREBASE_APP_ID`
7. `VITE_FIREBASE_MEASUREMENT_ID`
8. `DOCKERHUB_USERNAME`
9. `DOCKERHUB_TOKEN`
10. `EC2_HOST`
11. `EC2_USER`
12. `EC2_SSH_KEY`

### Step 3: Verify Secrets

After adding all secrets, you should see them listed (values are hidden):

```
VITE_FIREBASE_API_KEY              Updated X minutes ago
VITE_FIREBASE_AUTH_DOMAIN          Updated X minutes ago
VITE_FIREBASE_PROJECT_ID           Updated X minutes ago
...
```

## Getting DockerHub Token

### Step 1: Login to DockerHub
1. Go to https://hub.docker.com/
2. Login to your account

### Step 2: Create Access Token
1. Click on your username → **Account Settings**
2. Navigate to **Security** tab
3. Click **New Access Token**
4. Description: "GitHub Actions Deploy"
5. Access permissions: **Read, Write, Delete**
6. Click **Generate**
7. **Copy the token immediately** (won't be shown again)

### Step 3: Add to GitHub Secrets
```
Name:  DOCKERHUB_TOKEN
Value: dckr_pat_xxxxxxxxxxxxxxxxxxxxx
```

## Getting EC2 SSH Key

Your EC2 SSH private key is the `.pem` file you downloaded when creating the EC2 instance.

### Step 1: Read the Key File
```bash
cat /path/to/your-ec2-key.pem
```

### Step 2: Copy Entire Contents
Copy everything including:
```
-----BEGIN RSA PRIVATE KEY-----
[entire key content]
-----END RSA PRIVATE KEY-----
```

### Step 3: Add to GitHub Secrets
```
Name:  EC2_SSH_KEY
Value: [paste entire key including BEGIN and END lines]
```

## How Environment Variables Are Used

### 1. GitHub Actions Workflow

`.github/workflows/deploy.yml` reads secrets:

```yaml
build-args: |
  VITE_FIREBASE_API_KEY=${{ secrets.VITE_FIREBASE_API_KEY }}
  VITE_FIREBASE_AUTH_DOMAIN=${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
  # ... other variables
```

### 2. Dockerfile

`Dockerfile` receives them as build arguments:

```dockerfile
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
# ... other args

ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY
ENV VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN
# ... other envs
```

### 3. Vite Build

During `npm run build`, Vite:
1. Reads environment variables prefixed with `VITE_`
2. Replaces `import.meta.env.VITE_*` with actual values
3. Bundles them into the JavaScript

### 4. Application Code

`src/lib/firebase.js` uses them:

```javascript
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  // ...
};
```

## Updating Environment Variables

### Scenario 1: Change Firebase Project

If switching to a different Firebase project:

1. Get new Firebase credentials from Firebase Console
2. Update ALL Firebase secrets in GitHub
3. Trigger new deployment:
   ```bash
   git commit --allow-empty -m "Update Firebase config"
   git push origin main
   ```

### Scenario 2: Rotate DockerHub Token

If DockerHub token is compromised:

1. Revoke old token in DockerHub
2. Create new token
3. Update `DOCKERHUB_TOKEN` in GitHub Secrets
4. Next deployment will use new token

### Scenario 3: Change EC2 Instance

If moving to a new EC2 instance:

1. Update `EC2_HOST` with new IP
2. Update `EC2_SSH_KEY` with new key (if changed)
3. Trigger deployment:
   ```bash
   git commit --allow-empty -m "Update EC2 instance"
   git push origin main
   ```

## Local Development

### Create .env.local File

For local development, create `.env.local` (already in `.gitignore`):

```bash
# DO NOT COMMIT THIS FILE
VITE_FIREBASE_API_KEY=AIzaSy...
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:xxxxx
VITE_FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX
```

### Start Development Server
```bash
npm run dev
```

Vite automatically loads `.env.local` variables.

## Security Best Practices

### ✅ DO:
- Store all secrets in GitHub Secrets
- Use `.env.local` for local development
- Keep `.env.local` in `.gitignore`
- Rotate tokens periodically
- Use different Firebase projects for dev/production

### ❌ DON'T:
- Commit secrets to git
- Share secrets in Slack/email
- Hard-code credentials in source files
- Push `.env` files to GitHub
- Use production credentials locally

## Verifying Configuration

### Check GitHub Secrets
1. Go to GitHub → Settings → Secrets and variables → Actions
2. Verify all required secrets are listed

### Test Deployment
```bash
# Trigger deployment
git commit --allow-empty -m "Test environment variables"
git push origin main
```

### Check GitHub Actions Logs
1. Go to Actions tab
2. Open the workflow run
3. Check "Build and push Docker image" step
4. Verify no errors related to missing env vars

### Check Production Site
1. Open https://www.designuiux.com
2. Open browser DevTools → Console
3. Should NOT see Firebase initialization errors
4. Try logging in with Google

## Troubleshooting

### Error: "Firebase app not initialized"
**Cause**: Missing or incorrect Firebase env vars

**Solution**:
1. Verify all `VITE_FIREBASE_*` secrets in GitHub
2. Check for typos in secret names
3. Trigger new deployment

### Error: "Cannot read env variable"
**Cause**: Environment variable not available at build time

**Solution**:
1. Ensure variable name starts with `VITE_`
2. Check it's in GitHub Secrets
3. Verify it's in Dockerfile `ARG` and `ENV`

### Error: Docker push failed
**Cause**: Invalid DockerHub credentials

**Solution**:
1. Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
2. Create new token if needed
3. Update GitHub Secret

### Error: SSH connection failed
**Cause**: Invalid EC2 SSH key or IP

**Solution**:
1. Verify `EC2_HOST` is correct public IP
2. Verify `EC2_SSH_KEY` includes full key content
3. Check EC2 security group allows SSH from GitHub IPs

## Reference: Current Firebase Project

**Production Project**: `credit-tracker-236c3`

If you need to use a different Firebase project, get credentials from Firebase Console and update all GitHub Secrets.

## Summary Checklist

Before first deployment:

- [ ] All 7 Firebase env vars added to GitHub Secrets
- [ ] DockerHub username and token added
- [ ] EC2 host, user, and SSH key added
- [ ] Total 12 secrets configured
- [ ] `.env.local` created for local development
- [ ] `.env.local` in `.gitignore` (already done)
- [ ] Verified all secrets in GitHub Settings

Now you're ready to deploy!
