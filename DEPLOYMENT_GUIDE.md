# Tesla Camera AI System - Complete Deployment Guide

## System Overview

This guide will help you deploy a complete Tesla camera monitoring system that:
- Captures all Tesla camera footage via RPi5 USB connection
- Streams videos to Cloudflare for processing
- Runs AI object detection on all footage
- Provides real-time alerts and notifications
- Offers a web dashboard for viewing and analysis

## Prerequisites

### Hardware Requirements
- **Raspberry Pi 5** (8GB RAM recommended)
- **Storage**: 1TB+ NVMe SSD (via M.2 HAT)
- **Power**: USB-C PD power supply (5V/5A)
- **Cable**: USB-C to USB-A cable (for Tesla connection)
- **Optional**: 4G/LTE modem for mobile connectivity

### Software Requirements
- Cloudflare account with:
  - Stream enabled
  - Workers subscription
  - D1 database access
  - R2 storage
- Domain name (for API and dashboard)
- Basic command line knowledge

## Part 1: Cloudflare Setup

### 1.1 Enable Required Services

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Enable the following services:
   - **Stream**: Go to Stream → Enable
   - **Workers**: Should be enabled by default
   - **R2**: Go to R2 → Create bucket
   - **D1**: Available with Workers

### 1.2 Create API Token

1. Go to My Profile → API Tokens
2. Create token with permissions:
   - Account: Stream:Edit
   - Account: Workers Scripts:Edit
   - Account: D1:Edit
   - Account: R2:Edit

### 1.3 Deploy Workers

```bash
# Clone the repository
git clone https://github.com/yourusername/tesla-cam-ai.git
cd tesla-cam-ai/workers

# Install dependencies
npm install

# Configure wrangler.toml with your account details
nano wrangler.toml

# Create D1 database
wrangler d1 create tesla-cam-db

# Create R2 bucket
wrangler r2 bucket create tesla-cam-archive

# Create KV namespace
wrangler kv:namespace create DEVICE_STATUS

# Create Queue
wrangler queues create ai-processing

# Update wrangler.toml with the IDs from above commands

# Run database migrations
wrangler d1 execute tesla-cam-db --file=../migrations/schema.sql

# Deploy Workers
wrangler deploy
```

### 1.4 Configure Custom Domain

1. In Cloudflare Dashboard → Workers & Pages
2. Select your worker → Settings → Triggers
3. Add custom domain: `tesla-cam-api.yourdomain.com`

## Part 2: Raspberry Pi 5 Setup

### 2.1 Prepare the RPi5

1. **Flash OS**:
   ```bash
   # Download Raspberry Pi Imager
   # Select: Raspberry Pi OS (64-bit)
   # Configure: hostname, WiFi, SSH
   ```

2. **Initial Setup** (via SSH):
   ```bash
   ssh pi@tesla-cam.local
   
   # Expand filesystem
   sudo raspi-config --expand-rootfs
   
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Git
   sudo apt install git -y
   ```

### 2.2 Install Tesla Cam AI

```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/yourusername/tesla-cam-ai/main/rpi5/install.sh | bash

# Or clone and install manually
git clone https://github.com/yourusername/tesla-cam-ai.git
cd tesla-cam-ai/rpi5
chmod +x install.sh
./install.sh
```

### 2.3 Configure the System

1. **Edit Configuration**:
   ```bash
   sudo nano /etc/tesla-cam-ai/config.json
   ```

   Update with your Cloudflare credentials:
   ```json
   {
     "cloudflare": {
       "account_id": "YOUR_ACCOUNT_ID",
       "api_token": "YOUR_API_TOKEN",
       "worker_api": {
         "base_url": "https://tesla-cam-api.yourdomain.com",
         "api_key": "generate-secure-key-here"
       }
     }
   }
   ```

2. **Set Up Storage**:
   ```bash
   # If using external SSD
   sudo fdisk -l  # Find your SSD
   sudo mkfs.exfat -n TESLA-CAM /dev/sda1  # Format as exFAT
   
   # Test USB gadget
   sudo /usr/local/bin/usb-gadget.sh start
   sudo /usr/local/bin/usb-gadget.sh status
   ```

### 2.4 Connect to Tesla

1. **Prepare Tesla**:
   - Go to Controls → Safety → Dashcam
   - Remove any existing USB drive

2. **Connect RPi5**:
   - Power on RPi5 with external power
   - Connect USB-C to Tesla's USB port
   - Wait for Tesla to recognize the drive

3. **Format in Tesla**:
   - Touch the Dashcam icon
   - Select "Format USB Drive"
   - Confirm formatting

4. **Verify**:
   - Check for TeslaCam folders on RPi5:
   ```bash
   ls -la /mnt/tesla-cam/
   # Should see: TeslaCam, TeslaSentry folders
   ```

## Part 3: Dashboard Deployment

### 3.1 Build Dashboard

```bash
cd tesla-cam-ai/dashboard

# Install dependencies
npm install

# Configure API endpoint
echo "VITE_API_URL=https://tesla-cam-api.yourdomain.com" > .env

# Build for production
npm run build
```

### 3.2 Deploy to Cloudflare Pages

```bash
# Deploy to Pages
npx wrangler pages deploy dist --project-name=tesla-cam-dashboard

# Or use GitHub integration:
# 1. Push to GitHub
# 2. In Cloudflare → Pages → Create project
# 3. Connect GitHub repo
# 4. Build settings:
#    - Build command: npm run build
#    - Build directory: dist
```

### 3.3 Configure Domain

1. In Pages project → Custom domains
2. Add: `tesla-cam.yourdomain.com`
3. Wait for SSL certificate

## Part 4: System Configuration

### 4.1 Set Up Notifications

1. **Email Notifications** (Mailgun):
   ```bash
   # Add to wrangler.toml
   MAILGUN_API_KEY = "your-mailgun-api-key"
   MAILGUN_DOMAIN = "mg.yourdomain.com"
   ```

2. **Configure in Dashboard**:
   - Visit https://tesla-cam.yourdomain.com/settings
   - Set up notification preferences
   - Add email/phone for alerts

### 4.2 Configure AI Detection

1. **Adjust Sensitivity**:
   ```javascript
   // In workers/api/ai-processor.js
   const DETECTION_THRESHOLD = 0.7; // Adjust 0-1
   const ALERT_COOLDOWN = 300; // 5 minutes
   ```

2. **Enable/Disable Features**:
   ```json
   // In RPi5 config.json
   "features": {
     "license_plate_detection": true,
     "face_detection": false,
     "motion_detection": true
   }
   ```

## Part 5: Testing & Verification

### 5.1 Test Upload Pipeline

1. **Trigger Test Recording**:
   - In Tesla: Hold dashcam icon to save clip
   - Or trigger Sentry mode

2. **Monitor Upload**:
   ```bash
   # On RPi5
   sudo journalctl -u tesla-cam-ai -f
   
   # Check upload queue
   tail -f /var/log/tesla-cam-ai/main.log
   ```

3. **Verify in Dashboard**:
   - Visit https://tesla-cam.yourdomain.com
   - Check Events page for new recordings
   - Verify AI detections appear

### 5.2 Test Alerts

1. **Simulate Sentry Event**:
   - Approach vehicle to trigger Sentry
   - Check for person detection alert
   - Verify notification delivery

2. **Check Alert Channels**:
   - Email delivery
   - Dashboard real-time updates
   - Mobile notifications (if configured)

## Part 6: Maintenance

### 6.1 Regular Maintenance

1. **Storage Management**:
   ```bash
   # Check storage usage
   df -h /mnt/tesla-cam
   
   # Clean old files (automated via config)
   # Manual cleanup if needed:
   find /mnt/tesla-cam/TeslaCam -mtime +30 -delete
   ```

2. **Update System**:
   ```bash
   # Update RPi5 software
   cd /opt/tesla-cam-ai
   git pull
   pip install -r requirements.txt
   sudo systemctl restart tesla-cam-ai
   
   # Update Workers
   cd workers
   npm update
   wrangler deploy
   ```

### 6.2 Troubleshooting

**RPi5 Not Recognized by Tesla**:
```bash
# Check USB gadget
sudo systemctl status tesla-usb-gadget
sudo dmesg | grep gadget

# Restart gadget
sudo systemctl restart tesla-usb-gadget
```

**Upload Failures**:
```bash
# Check network
ping api.cloudflare.com

# Check API key
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
  https://api.cloudflare.com/client/v4/user/tokens/verify

# Check logs
grep ERROR /var/log/tesla-cam-ai/main.log
```

**No AI Detections**:
- Check Workers logs in Cloudflare Dashboard
- Verify AI queue is processing
- Check D1 database for records

## Part 7: Advanced Configuration

### 7.1 Mobile Connectivity

For parking lot monitoring without WiFi:

```bash
# Install mobile network tools
sudo apt install modemmanager network-manager

# Configure 4G modem
sudo nmcli connection add type gsm ifname "*" con-name "mobile" apn "your.apn"
sudo nmcli connection up mobile
```

### 7.2 Multi-Camera Support

For multiple Teslas:

1. Deploy multiple RPi5 units with unique device IDs
2. Dashboard automatically aggregates all devices
3. Filter by device in Events view

### 7.3 Custom AI Models

Extend AI capabilities:

```javascript
// In workers/api/ai-processor.js
// Add custom model calls
const customDetection = await ai.run('@cf/custom/model', {
  image: frameData
});
```

## Security Best Practices

1. **API Security**:
   - Use strong API keys
   - Rotate tokens regularly
   - Enable Cloudflare WAF

2. **Device Security**:
   - Change default passwords
   - Enable firewall on RPi5
   - Use VPN for remote access

3. **Data Privacy**:
   - Enable video encryption
   - Set retention policies
   - Comply with local laws

## Support & Resources

- **Documentation**: https://github.com/yourusername/tesla-cam-ai/wiki
- **Issues**: https://github.com/yourusername/tesla-cam-ai/issues
- **Discord**: https://discord.gg/tesla-cam-ai
- **Email**: support@tesla-cam-ai.com

## Conclusion

Your Tesla Camera AI system is now fully deployed! The system will:
- Automatically capture all Tesla camera footage
- Stream to Cloudflare for AI processing
- Detect people, vehicles, and other objects
- Send real-time alerts for security events
- Provide a comprehensive dashboard for review

Monitor the dashboard regularly and adjust settings based on your needs. The system is designed to run 24/7 with minimal maintenance.
