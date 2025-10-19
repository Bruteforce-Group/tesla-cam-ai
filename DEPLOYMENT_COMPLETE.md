# 🚀 Tesla Cam AI - Deployment Setup Complete

## What's Been Created

A complete CI/CD pipeline for automated deployment of the Tesla Camera AI system with GitHub Actions integration.

## 📁 Files Created

### GitHub Actions Workflow
- `.github/workflows/deploy.yml` - Complete CI/CD pipeline

### Deployment Scripts
- `scripts/initial-setup.sh` - First-time Raspberry Pi setup
- `scripts/remote-setup.sh` - Remote installation from your machine
- `scripts/deploy-to-endpoint.sh` - Manual deployment script
- `scripts/README.md` - Script documentation

### Documentation
- `GITHUB_SETUP.md` - Complete GitHub Actions configuration guide
- `DEPLOYMENT_COMPLETE.md` - This file

## 🎯 How to Deploy

### Option 1: Quick Start (Recommended)

Run this from your **local machine**:

```bash
# Navigate to project
cd tesla-cam-ai

# Make scripts executable
chmod +x scripts/*.sh

# Run remote setup
./scripts/remote-setup.sh
```

**What happens:**
1. Tests SSH connection to 192.168.230.28
2. Uploads setup files
3. Installs system dependencies
4. Creates services
5. Generates SSH keys
6. Shows you the key for GitHub

**Duration:** 10-15 minutes

### Option 2: Manual Setup

SSH into the endpoint and run:

```bash
ssh danielborrowman@192.168.230.28

# Download and run setup
curl -sSL https://raw.githubusercontent.com/your-repo/main/scripts/initial-setup.sh | bash
```

## 🔧 After Initial Setup

### 1. Configure Cloudflare Credentials

```bash
ssh danielborrowman@192.168.230.28
sudo nano /etc/tesla-cam-ai/config.json
```

Update these fields:
```json
{
  "cloudflare": {
    "account_id": "YOUR_CLOUDFLARE_ACCOUNT_ID",
    "api_token": "YOUR_CLOUDFLARE_API_TOKEN",
    "worker_api": {
      "base_url": "https://tesla-cam-api.yourdomain.workers.dev",
      "api_key": "GENERATE_SECURE_KEY"
    }
  }
}
```

### 2. Start Services

```bash
ssh danielborrowman@192.168.230.28 << 'EOF'
  sudo systemctl start tesla-usb-gadget
  sudo systemctl start tesla-cam-ai
  sudo systemctl start tesla-cam-upload
EOF
```

### 3. Verify Services

```bash
# Check status
ssh danielborrowman@192.168.230.28 'sudo systemctl status tesla-cam-ai'

# View logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -f'
```

### 4. Set Up GitHub Actions

#### Get SSH Private Key
```bash
ssh danielborrowman@192.168.230.28 'cat ~/.ssh/tesla_cam_deploy'
```

#### Add GitHub Secrets
Go to your repository → Settings → Secrets → Actions → New secret

Add these secrets:
1. **SSH_PRIVATE_KEY** - The private key from above
2. **CLOUDFLARE_API_TOKEN** - Your Cloudflare API token
3. **CLOUDFLARE_ACCOUNT_ID** - Your Cloudflare account ID
4. **API_URL** - Your Workers API URL (optional)

See [GITHUB_SETUP.md](./GITHUB_SETUP.md) for detailed instructions.

## 🔄 Automated Deployment Flow

Once GitHub Actions is configured:

```bash
# Make changes
git add .
git commit -m "Add new feature"
git push origin main
```

**GitHub Actions automatically:**
1. ✅ Runs tests
2. ✅ Deploys Cloudflare Workers
3. ✅ Deploys dashboard to Pages
4. ✅ Updates code on Raspberry Pi (192.168.230.28)
5. ✅ Restarts services
6. ✅ Verifies deployment
7. ✅ Sends notifications

## 📊 Deployment Targets

### Production (main branch)
- **Workers:** `https://tesla-cam-api.yourdomain.workers.dev`
- **Dashboard:** `https://tesla-cam.yourdomain.com`
- **Endpoint:** `danielborrowman@192.168.230.28`

### Development (develop branch)
- **Workers:** Development environment
- **Endpoint:** Same endpoint, different config

## 🛠️ Manual Deployment

For emergency deployments or testing:

```bash
./scripts/deploy-to-endpoint.sh
```

This bypasses GitHub Actions and deploys directly to the endpoint.

## 📋 Verification Checklist

After deployment, verify:

- [ ] SSH access to endpoint works
- [ ] Services are running
- [ ] Configuration file is correct
- [ ] GitHub secrets are set
- [ ] GitHub Actions workflow runs successfully
- [ ] Logs show no errors
- [ ] USB gadget is active
- [ ] Tesla recognizes the device

## 🔍 Monitoring

### Check Service Status
```bash
ssh danielborrowman@192.168.230.28 'systemctl status tesla-cam-ai'
```

### View Live Logs
```bash
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -f'
```

### Check Storage
```bash
ssh danielborrowman@192.168.230.28 'df -h /mnt/tesla-cam'
```

### Check Upload Queue
```bash
ssh danielborrowman@192.168.230.28 'ls -lh /mnt/tesla-cam/TeslaCam/'
```

## 🚨 Troubleshooting

### GitHub Actions fails
- Check Actions logs in GitHub
- Verify all secrets are set
- Test SSH connection manually

### Service won't start
```bash
# Check logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -xe'

# Check configuration
ssh danielborrowman@192.168.230.28 'cat /etc/tesla-cam-ai/config.json'
```

### USB not recognized
```bash
# Restart USB gadget
ssh danielborrowman@192.168.230.28 'sudo systemctl restart tesla-usb-gadget'

# Check status
ssh danielborrowman@192.168.230.28 'sudo systemctl status tesla-usb-gadget'
```

### Rollback deployment
```bash
ssh danielborrowman@192.168.230.28 << 'EOF'
  LATEST=$(ls -t /opt/tesla-cam-ai.backup.* | head -1)
  sudo rm -rf /opt/tesla-cam-ai
  sudo mv "$LATEST" /opt/tesla-cam-ai
  sudo systemctl restart tesla-cam-ai
EOF
```

## 📚 Additional Resources

- [GITHUB_SETUP.md](./GITHUB_SETUP.md) - Detailed GitHub Actions setup
- [scripts/README.md](./scripts/README.md) - Script usage guide
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Full deployment documentation
- [README.md](./README.md) - Project overview

## 🎉 Next Steps

1. **Run Initial Setup**
   ```bash
   ./scripts/remote-setup.sh
   ```

2. **Configure Credentials**
   Edit `/etc/tesla-cam-ai/config.json` on endpoint

3. **Set Up GitHub Secrets**
   Add SSH key and Cloudflare credentials

4. **Test Deployment**
   ```bash
   git commit -m "test: deployment" --allow-empty
   git push origin main
   ```

5. **Connect to Tesla**
   Plug in USB-C cable and format in car

6. **Monitor Dashboard**
   Visit `https://tesla-cam.yourdomain.com`

## 💡 Pro Tips

- Use `develop` branch for testing
- Manual deploy with `deploy-to-endpoint.sh` for hotfixes
- Check logs before and after deployment
- Keep backups of configuration
- Monitor storage usage regularly

## 🔐 Security Reminders

- Never commit private keys
- Rotate SSH keys monthly
- Rotate API tokens quarterly
- Review access logs regularly
- Use strong passwords

## ✅ Deployment Checklist

- [x] Created GitHub Actions workflow
- [x] Created deployment scripts
- [x] Made scripts executable
- [x] Documented setup process
- [ ] Run initial setup on endpoint
- [ ] Configure Cloudflare credentials
- [ ] Add GitHub secrets
- [ ] Test automated deployment
- [ ] Connect to Tesla
- [ ] Verify recording

---

**Ready to deploy!** 🚗📹🤖

Run `./scripts/remote-setup.sh` to get started.
