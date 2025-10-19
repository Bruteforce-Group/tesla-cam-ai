# GitHub Secrets Setup - Quick Guide

## Step-by-Step Instructions

### 1. Navigate to GitHub Secrets

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2. Add SSH_PRIVATE_KEY

- **Name**: `SSH_PRIVATE_KEY`
- **Value**: Copy from `/tmp/github_ssh_key.txt` or the output above
  - Must include `-----BEGIN OPENSSH PRIVATE KEY-----`
  - Must include `-----END OPENSSH PRIVATE KEY-----`
  - Include all lines in between

### 3. Add CLOUDFLARE_API_TOKEN

**Get the token:**
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click **Create Token**
3. Use **Edit Cloudflare Workers** template
4. Add these permissions:
   - Account → Stream → Edit
   - Account → Workers Scripts → Edit  
   - Account → D1 → Edit
   - Account → R2 → Edit
5. Click **Continue to summary**
6. Click **Create Token**
7. **COPY THE TOKEN** (you can only see it once!)

**Add to GitHub:**
- **Name**: `CLOUDFLARE_API_TOKEN`
- **Value**: Paste the token you just copied

### 4. Add CLOUDFLARE_ACCOUNT_ID

**Get the Account ID:**
1. Go to https://dash.cloudflare.com
2. Click on any domain
3. Scroll down on the Overview page
4. Find **Account ID** in the right sidebar
5. Click the copy icon

**Add to GitHub:**
- **Name**: `CLOUDFLARE_ACCOUNT_ID`
- **Value**: Paste your account ID

### 5. Optional: Add API_URL

**Only needed if you want to specify the API URL:**
- **Name**: `API_URL`
- **Value**: `https://tesla-cam-api.yourdomain.workers.dev`

### 6. Optional: Add SLACK_WEBHOOK_URL

**For deployment notifications:**
- **Name**: `SLACK_WEBHOOK_URL`
- **Value**: Your Slack incoming webhook URL

## Verification

After adding all secrets, you should see:
- ✅ SSH_PRIVATE_KEY
- ✅ CLOUDFLARE_API_TOKEN
- ✅ CLOUDFLARE_ACCOUNT_ID

## Next Step

Once secrets are added, you can trigger deployments by:
```bash
git push origin main
```

GitHub Actions will automatically deploy to your Raspberry Pi!
