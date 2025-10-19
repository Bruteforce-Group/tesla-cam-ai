# Tesla Cam AI - Quick Commands Reference

## 🚀 Initial Setup

```bash
# One-line setup from your local machine
./scripts/remote-setup.sh

# Or SSH and run directly on Pi
ssh danielborrowman@192.168.230.28
curl -sSL https://get.tesla-cam-ai.com | bash
```

## 🔧 Service Management

```bash
# Start services
ssh danielborrowman@192.168.230.28 'sudo systemctl start tesla-cam-ai'

# Stop services
ssh danielborrowman@192.168.230.28 'sudo systemctl stop tesla-cam-ai'

# Restart services
ssh danielborrowman@192.168.230.28 'sudo systemctl restart tesla-cam-ai'

# Check status
ssh danielborrowman@192.168.230.28 'sudo systemctl status tesla-cam-ai'

# Enable auto-start on boot
ssh danielborrowman@192.168.230.28 'sudo systemctl enable tesla-cam-ai'
```

## 📊 Monitoring

```bash
# Live logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -f'

# Last 50 lines
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -n 50'

# Logs with errors only
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -p err'

# Today's logs
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai --since today'
```

## 💾 Storage

```bash
# Check storage usage
ssh danielborrowman@192.168.230.28 'df -h /mnt/tesla-cam'

# List recordings
ssh danielborrowman@192.168.230.28 'ls -lh /mnt/tesla-cam/TeslaCam/'

# Count videos
ssh danielborrowman@192.168.230.28 'find /mnt/tesla-cam -name "*.mp4" | wc -l'

# Storage by folder
ssh danielborrowman@192.168.230.28 'du -sh /mnt/tesla-cam/*'
```

## 📤 Deployment

```bash
# Auto deploy via GitHub (just push)
git add .
git commit -m "Your changes"
git push origin main

# Manual deployment
./scripts/deploy-to-endpoint.sh

# Deploy specific branch
git checkout develop
./scripts/deploy-to-endpoint.sh
```

## ⚙️ Configuration

```bash
# Edit config
ssh danielborrowman@192.168.230.28 'sudo nano /etc/tesla-cam-ai/config.json'

# View config
ssh danielborrowman@192.168.230.28 'sudo cat /etc/tesla-cam-ai/config.json'

# Backup config
ssh danielborrowman@192.168.230.28 'sudo cp /etc/tesla-cam-ai/config.json ~/config.backup.json'

# Validate JSON
ssh danielborrowman@192.168.230.28 'cat /etc/tesla-cam-ai/config.json | jq .'
```

## 🔄 USB Gadget

```bash
# Restart USB gadget
ssh danielborrowman@192.168.230.28 'sudo systemctl restart tesla-usb-gadget'

# Check USB status
ssh danielborrowman@192.168.230.28 'sudo systemctl status tesla-usb-gadget'

# Manual USB start
ssh danielborrowman@192.168.230.28 'sudo /usr/local/bin/usb-gadget.sh start'

# Manual USB stop
ssh danielborrowman@192.168.230.28 'sudo /usr/local/bin/usb-gadget.sh stop'
```

## 🐛 Debugging

```bash
# Run app manually (for debugging)
ssh danielborrowman@192.168.230.28 << 'EOF'
  cd /opt/tesla-cam-ai
  source venv/bin/activate
  python rpi5/main.py
EOF

# Check Python errors
ssh danielborrowman@192.168.230.28 'python3 -c "import sys; print(sys.path)"'

# Test API connection
ssh danielborrowman@192.168.230.28 'curl -I https://api.cloudflare.com'

# Check network
ssh danielborrowman@192.168.230.28 'ping -c 3 cloudflare.com'
```

## 🔐 SSH & Keys

```bash
# Generate new SSH key
ssh danielborrowman@192.168.230.28 'ssh-keygen -t rsa -b 4096 -f ~/.ssh/tesla_cam_deploy'

# View public key
ssh danielborrowman@192.168.230.28 'cat ~/.ssh/tesla_cam_deploy.pub'

# View private key (for GitHub Secrets)
ssh danielborrowman@192.168.230.28 'cat ~/.ssh/tesla_cam_deploy'

# Test SSH from GitHub
curl https://api.github.com/meta | jq -r .hooks
```

## 📈 System Info

```bash
# System stats
ssh danielborrowman@192.168.230.28 'top -bn1 | head -20'

# Memory usage
ssh danielborrowman@192.168.230.28 'free -h'

# CPU temperature
ssh danielborrowman@192.168.230.28 'vcgencmd measure_temp'

# Uptime
ssh danielborrowman@192.168.230.28 'uptime'

# Disk I/O
ssh danielborrowman@192.168.230.28 'iostat'
```

## 🔄 Backup & Restore

```bash
# Backup current version
ssh danielborrowman@192.168.230.28 'sudo cp -r /opt/tesla-cam-ai /opt/tesla-cam-ai.backup'

# List backups
ssh danielborrowman@192.168.230.28 'ls -lt /opt/tesla-cam-ai.backup.*'

# Restore from backup
ssh danielborrowman@192.168.230.28 << 'EOF'
  sudo rm -rf /opt/tesla-cam-ai
  sudo mv /opt/tesla-cam-ai.backup.YYYYMMDD_HHMMSS /opt/tesla-cam-ai
  sudo systemctl restart tesla-cam-ai
EOF
```

## 🧹 Cleanup

```bash
# Clean old recordings (older than 30 days)
ssh danielborrowman@192.168.230.28 'find /mnt/tesla-cam/TeslaCam -mtime +30 -name "*.mp4" -delete'

# Clean Python cache
ssh danielborrowman@192.168.230.28 'find /opt/tesla-cam-ai -type d -name __pycache__ -exec rm -rf {} +'

# Clean old backups (keep last 3)
ssh danielborrowman@192.168.230.28 'ls -t /opt/tesla-cam-ai.backup.* | tail -n +4 | xargs sudo rm -rf'

# Clean logs older than 7 days
ssh danielborrowman@192.168.230.28 'sudo journalctl --vacuum-time=7d'
```

## 📦 Updates

```bash
# Update system packages
ssh danielborrowman@192.168.230.28 'sudo apt update && sudo apt upgrade -y'

# Update Python packages
ssh danielborrowman@192.168.230.28 << 'EOF'
  cd /opt/tesla-cam-ai
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r rpi5/requirements.txt --upgrade
EOF

# Update from git (manual)
ssh danielborrowman@192.168.230.28 << 'EOF'
  cd /opt/tesla-cam-ai
  git pull
  source venv/bin/activate
  pip install -r rpi5/requirements.txt
  sudo systemctl restart tesla-cam-ai
EOF
```

## 🎯 One-Liners

```bash
# Quick status check
ssh danielborrowman@192.168.230.28 'systemctl is-active tesla-cam-ai && echo "✅ Running" || echo "❌ Stopped"'

# Quick restart
ssh danielborrowman@192.168.230.28 'sudo systemctl restart tesla-cam-ai && echo "✅ Restarted"'

# Storage percentage
ssh danielborrowman@192.168.230.28 'df -h /mnt/tesla-cam | awk NR==2{print $5}'

# Count today's recordings
ssh danielborrowman@192.168.230.28 'find /mnt/tesla-cam -name "*.mp4" -mtime -1 | wc -l'

# Last 5 log entries
ssh danielborrowman@192.168.230.28 'sudo journalctl -u tesla-cam-ai -n 5 --no-pager'
```

## 🆘 Emergency Commands

```bash
# Force kill service
ssh danielborrowman@192.168.230.28 'sudo systemctl kill -s SIGKILL tesla-cam-ai'

# Immediate rollback
ssh danielborrowman@192.168.230.28 << 'EOF'
  LATEST=$(ls -t /opt/tesla-cam-ai.backup.* | head -1)
  sudo rm -rf /opt/tesla-cam-ai
  sudo mv "$LATEST" /opt/tesla-cam-ai
  sudo systemctl restart tesla-cam-ai
EOF

# Reboot system
ssh danielborrowman@192.168.230.28 'sudo reboot'

# Safe mode (disable auto-start)
ssh danielborrowman@192.168.230.28 'sudo systemctl disable tesla-cam-ai'
```

## 💡 Aliases

Add to your `~/.bashrc` for quick access:

```bash
# Add these aliases
alias tca-ssh='ssh danielborrowman@192.168.230.28'
alias tca-status='ssh danielborrowman@192.168.230.28 "sudo systemctl status tesla-cam-ai"'
alias tca-logs='ssh danielborrowman@192.168.230.28 "sudo journalctl -u tesla-cam-ai -f"'
alias tca-restart='ssh danielborrowman@192.168.230.28 "sudo systemctl restart tesla-cam-ai"'
alias tca-deploy='./scripts/deploy-to-endpoint.sh'
alias tca-storage='ssh danielborrowman@192.168.230.28 "df -h /mnt/tesla-cam"'

# Then just use:
# tca-logs
# tca-restart
# etc.
```

---

**Tip:** Save this file and keep it handy for quick reference!
