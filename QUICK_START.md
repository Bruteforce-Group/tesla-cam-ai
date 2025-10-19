# Tesla Camera AI - Quick Start Guide 🚀

Get your Tesla camera AI system running in under 30 minutes!

## What You'll Get

- 🎥 All Tesla cameras streaming to the cloud
- 🤖 AI detection of people, vehicles, and events  
- 📱 Real-time alerts on your phone
- 💻 Web dashboard to view everything
- 🔒 Secure, encrypted storage

## Requirements

- Tesla Model 3/Y/S/X (2020+)
- Raspberry Pi 5 (8GB)
- 1TB+ SSD storage
- USB-C cable
- Cloudflare account

## 5-Minute Quick Start

### 1️⃣ Flash Your Pi
```bash
# Use Raspberry Pi Imager
# Select: Raspberry Pi OS (64-bit)
# Enable SSH, set hostname: tesla-cam
```

### 2️⃣ Run Installer (on Pi)
```bash
curl -sSL https://get.tesla-cam-ai.com | bash
```

### 3️⃣ Configure Cloudflare
```bash
# The installer will guide you through:
# - Cloudflare login
# - API token creation  
# - Service deployment
```

### 4️⃣ Connect to Tesla
1. Plug Pi into Tesla USB port
2. Tesla screen → Dashcam icon → Format USB
3. Done! Recording starts automatically

### 5️⃣ Access Dashboard
```
https://tesla-cam.yourdomain.com
```

## That's It! 🎉

Your Tesla now has:
- ✅ 24/7 camera recording
- ✅ AI security monitoring
- ✅ Cloud backup of all footage
- ✅ Instant alerts for events

## First Recording Test

1. **Save a clip**: Hold dashcam icon for 1 second
2. **Check dashboard**: Video appears in ~30 seconds
3. **View AI results**: Click video to see detections

## Common Commands

```bash
# Check system status
sudo systemctl status tesla-cam-ai

# View logs
sudo journalctl -u tesla-cam-ai -f

# Manual upload trigger
tesla-cam-ai upload --all

# Storage check
tesla-cam-ai storage status
```

## Mobile App

Coming soon! For now, the web dashboard is mobile-friendly.

## Need Help?

- 📖 [Full Documentation](./README.md)
- 💬 [Discord Community](https://discord.gg/tesla-cam)
- 📧 [Email Support](support@tesla-cam-ai.com)

---

**Pro Tip**: Enable Sentry Mode for automatic security recordings when parked! 🚗🔐
