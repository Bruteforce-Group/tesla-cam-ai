# GitHub Actions Setup Guide

This guide will help you set up automated deployments using GitHub Actions.

## Prerequisites

- GitHub repository for this project
- Access to the Raspberry Pi endpoint (192.168.230.28)
- Cloudflare account with API token

## Step 1: Initial Endpoint Setup

Run the initial setup script on your Raspberry Pi:

```bash
# SSH into your Raspberry Pi
ssh danielborrowman@192.168.230.28

# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/your-repo/tesla-cam-ai/main/scripts/initial-setup.sh | bash

# Or if you have the repo cloned
cd tesla-cam-ai
chmod +x scripts/initial-setup.sh
./scripts/initial-setup.sh
```

This will:
- Install all dependencies
- Create systemd services
- Generate SSH keys for GitHub Actions
- Set up directory structure

## Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

### Navigate to Secrets
1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Required Secrets

#### 1. SSH_PRIVATE_KEY
The private key for SSH access to the endpoint.

**Get the key:**
```bash
ssh danielborrowman@192.168.230.28
cat ~/.ssh/tesla_cam_deploy
```

Copy the entire private key including:
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

**Add to GitHub:**
- Name: `SSH_PRIVATE_KEY`
- Value: Paste the private key

#### 2. CLOUDFLARE_API_TOKEN
Your Cloudflare API token with permissions for Workers, Stream, D1, and R2.

**Create token:**
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use template: "Edit Cloudflare Workers"
4. Add permissions:
   - Account > Stream > Edit
   - Account > Workers Scripts > Edit
   - Account > D1 > Edit
   - Account > R2 > Edit
5. Copy the token

**Add to GitHub:**
- Name: `CLOUDFLARE_API_TOKEN`
- Value: Paste your API token

#### 3. CLOUDFLARE_ACCOUNT_ID
Your Cloudflare account ID.

**Get your account ID:**
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select any domain
3. Scroll down on Overview page
4. Copy "Account ID" from the right sidebar

**Add to GitHub:**
- Name: `CLOUDFLARE_ACCOUNT_ID`
- Value: Paste your account ID

#### 4. API_URL (Optional)
The URL of your deployed Workers API.

**Add to GitHub:**
- Name: `API_URL`
- Value: `https://tesla-cam-api.yourdomain.workers.dev`

#### 5. SLACK_WEBHOOK_URL (Optional)
For Slack notifications on deployments.

**Add to GitHub:**
- Name: `SLACK_WEBHOOK_URL`
- Value: Your Slack webhook URL

## Step 3: Verify GitHub Actions Workflow

The workflow file is located at `.github/workflows/deploy.yml`

It will automatically run on:
- Push to `main` branch (production deployment)
- Push to `develop` branch (development deployment)
- Manual trigger via GitHub UI

### Workflow Jobs:

1. **Test** - Runs linting and tests
2. **Deploy Workers** - Deploys Cloudflare Workers API
3. **Deploy Dashboard** - Deploys web dashboard to Pages
4. **Deploy Endpoint** - Updates code on Raspberry Pi
5. **Notify** - Sends deployment notifications

## Step 4: Test Deployment

### Manual Test
Push a commit to trigger deployment:

```bash
git add .
git commit -m "Test deployment"
git push origin main
```

### Monitor Deployment
1. Go to your GitHub repository
2. Click **Actions** tab
3. Click on the latest workflow run
4. Watch each job execute

### Manual Deployment Script
For manual deployments without Git push:

```bash
# Make the script executable
chmod +x scripts/deploy-to-endpoint.sh

# Run deployment
./scripts/deploy-to-endpoint.sh
```

## Step 5: Verify on Endpoint

After deployment, verify everything is working:

```bash
# SSH into endpoint
ssh danielborrowman@192.168.230.28

# Check service status
sudo systemctl status tesla-cam-ai

# View logs
sudo journalctl -u tesla-cam-ai -f

# Check running processes
ps aux | grep python
```

## Troubleshooting

### SSH Connection Fails
```bash
# Test SSH manually
ssh -v danielborrowman@192.168.230.28

# Verify SSH key
ssh-keygen -l -f ~/.ssh/tesla_cam_deploy.pub

# Check authorized_keys on endpoint
ssh danielborrowman@192.168.230.28 'cat ~/.ssh/authorized_keys'
```

### Service Won't Start
```bash
# Check logs for errors
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -n 50'

# Check configuration
ssh danielborrowman@192.168.230.28 'cat /etc/tesla-cam-ai/config.json'

# Manual start for debugging
ssh danielborrowman@192.168.230.28
cd /opt/tesla-cam-ai
source venv/bin/activate
python rpi5/main.py
```

### GitHub Actions Fails
1. Check the Actions log for specific error
2. Verify all secrets are set correctly
3. Check SSH connectivity from GitHub:
   - GitHub uses specific IP ranges
   - Ensure endpoint firewall allows connections

### Rollback Deployment
If a deployment fails, rollback to previous version:

```bash
ssh danielborrowman@192.168.230.28 << 'EOF'
  LATEST_BACKUP=$(ls -t /opt/tesla-cam-ai.backup.* | head -1)
  sudo rm -rf /opt/tesla-cam-ai
  sudo mv "$LATEST_BACKUP" /opt/tesla-cam-ai
  sudo systemctl restart tesla-cam-ai
EOF
```

## Branch Strategy

### Main Branch (Production)
- Deploys to production Cloudflare Workers
- Updates production endpoint
- Runs database migrations
- Sends notifications

### Develop Branch (Development)
- Deploys to development Cloudflare Workers
- Updates development endpoint
- Does not run migrations
- For testing before production

### Feature Branches
- Create PR to develop or main
- Runs tests only
- No deployment

## Deployment Workflow

```mermaid
graph LR
    A[Push to GitHub] --> B[Run Tests]
    B --> C{Branch?}
    C -->|main| D[Deploy Workers]
    C -->|develop| D
    D --> E[Deploy Dashboard]
    E --> F[Deploy to Endpoint]
    F --> G[Verify]
    G -->|Success| H[Notify]
    G -->|Failure| I[Rollback]
```

## Security Best Practices

1. **Rotate SSH Keys Regularly**
   ```bash
   # Generate new key
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/tesla_cam_deploy_new
   
   # Update GitHub secret
   # Remove old key from authorized_keys
   ```

2. **Rotate Cloudflare API Tokens**
   - Create new token
   - Update GitHub secret
   - Revoke old token

3. **Review Access Logs**
   ```bash
   # Check who accessed endpoint
   ssh danielborrowman@192.168.230.28 'last'
   
   # Check sudo usage
   ssh danielborrowman@192.168.230.28 'sudo cat /var/log/auth.log'
   ```

## Advanced Configuration

### Multiple Endpoints
Deploy to multiple Raspberry Pis:

```yaml
# Add to .github/workflows/deploy.yml
strategy:
  matrix:
    endpoint:
      - host: 192.168.230.28
        name: garage
      - host: 192.168.230.29
        name: driveway
```

### Conditional Deployments
Only deploy specific components:

```bash
# Skip endpoint deployment
git commit -m "fix: dashboard typo [skip-endpoint]"

# Skip workers deployment
git commit -m "docs: update readme [skip-workers]"
```

## Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions logs
3. Check endpoint logs
4. Open an issue on GitHub
