# Deployment Scripts

This directory contains scripts for deploying and managing the Tesla Cam AI system.

## Scripts Overview

### 🚀 Initial Setup

#### `remote-setup.sh` - RECOMMENDED
Run this from your **local machine** to set up the endpoint remotely.

```bash
./scripts/remote-setup.sh
```

**What it does:**
- Tests SSH connection
- Uploads setup files
- Runs installation automatically
- Shows next steps

**Prerequisites:**
- SSH access to danielborrowman@192.168.230.28
- Network connectivity to endpoint

---

#### `initial-setup.sh`
Run this **on the Raspberry Pi** for first-time setup.

```bash
# SSH into the Pi first
ssh danielborrowman@192.168.230.28

# Then run
curl -sSL https://raw.githubusercontent.com/your-repo/main/scripts/initial-setup.sh | bash

# Or if you have the files
./scripts/initial-setup.sh
```

**What it does:**
- Installs system dependencies
- Creates directory structure
- Sets up USB gadget mode
- Creates systemd services
- Generates SSH keys for GitHub Actions
- Configures log rotation

**Duration:** 10-15 minutes

---

### 📦 Deployment

#### `deploy-to-endpoint.sh`
Manual deployment script for pushing code updates.

```bash
./scripts/deploy-to-endpoint.sh
```

**What it does:**
- Creates deployment package
- Uploads to endpoint
- Backs up current version
- Deploys new version
- Restarts services
- Verifies deployment

**When to use:**
- Testing changes before git push
- Emergency hotfixes
- Debugging deployment issues

**Note:** GitHub Actions handles automatic deployments. This is for manual overrides only.

---

## Usage Guide

### First Time Setup

1. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Run remote setup:**
   ```bash
   ./scripts/remote-setup.sh
   ```

3. **Configure credentials:**
   ```bash
   ssh danielborrowman@192.168.230.28
   sudo nano /etc/tesla-cam-ai/config.json
   # Add your Cloudflare credentials
   ```

4. **Start services:**
   ```bash
   ssh danielborrowman@192.168.230.28 'sudo systemctl start tesla-cam-ai'
   ```

5. **Set up GitHub Actions:**
   - See [GITHUB_SETUP.md](../GITHUB_SETUP.md)

### Ongoing Deployments

For normal development workflow:

```bash
# Make changes
git add .
git commit -m "Your changes"
git push origin main

# GitHub Actions automatically deploys!
```

For manual deployment:

```bash
./scripts/deploy-to-endpoint.sh
```

### Checking Status

```bash
# Service status
ssh danielborrowman@192.168.230.28 'sudo systemctl status tesla-cam-ai'

# Live logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -f'

# Storage usage
ssh danielborrowman@192.168.230.28 'df -h /mnt/tesla-cam'
```

## Configuration Files

Scripts will look for these files:

- **Config:** `/etc/tesla-cam-ai/config.json`
- **Logs:** `/var/log/tesla-cam-ai/`
- **App:** `/opt/tesla-cam-ai/`
- **Data:** `/var/lib/tesla-cam-ai/`

## Troubleshooting

### Script won't run
```bash
# Make executable
chmod +x scripts/script-name.sh
```

### SSH connection fails
```bash
# Test connection
ssh danielborrowman@192.168.230.28 echo "OK"

# Check SSH key
ls -la ~/.ssh/
```

### Deployment fails
```bash
# Check endpoint logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -n 100'

# Manual rollback
ssh danielborrowman@192.168.230.28 'ls -lt /opt/tesla-cam-ai.backup.*'
```

### Service won't start
```bash
# Check configuration
ssh danielborrowman@192.168.230.28 'cat /etc/tesla-cam-ai/config.json'

# Test manually
ssh danielborrowman@192.168.230.28
cd /opt/tesla-cam-ai
source venv/bin/activate
python rpi5/main.py
```

## Environment Variables

Some scripts support environment variables:

```bash
# Custom endpoint
ENDPOINT_HOST=192.168.1.100 ./scripts/deploy-to-endpoint.sh

# Custom user
ENDPOINT_USER=pi ./scripts/deploy-to-endpoint.sh

# Both
ENDPOINT_USER=pi ENDPOINT_HOST=192.168.1.100 ./scripts/deploy-to-endpoint.sh
```

## Security Notes

- SSH keys are generated during setup
- Private key is displayed once (for GitHub Secrets)
- Keys are stored in `~/.ssh/tesla_cam_deploy`
- Never commit private keys to git!

## Support

If scripts fail:
1. Check the error message
2. Review logs on endpoint
3. Try manual steps
4. Open GitHub issue with error details
