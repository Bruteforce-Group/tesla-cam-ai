#!/bin/bash
# Tesla Cam AI - Initial Setup Script for Raspberry Pi 5
# Run this script once to set up the system for the first time
# Usage: ./initial-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DEPLOY_PATH="/opt/tesla-cam-ai"
CONFIG_PATH="/etc/tesla-cam-ai"
LOG_PATH="/var/log/tesla-cam-ai"
DATA_PATH="/var/lib/tesla-cam-ai"

echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              Tesla Camera AI System Setup                  ║
║            Raspberry Pi 5 Initial Configuration           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running on Raspberry Pi
echo -e "${YELLOW}[1/12]${NC} Checking system requirements..."
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Not running on Raspberry Pi${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check internet connectivity
if ! ping -c 1 cloudflare.com &> /dev/null; then
    echo -e "${RED}❌ No internet connection. Please connect to WiFi/Ethernet.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ System requirements met${NC}"

# Update system
echo -e "${YELLOW}[2/12]${NC} Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# Install system dependencies
echo -e "${YELLOW}[3/12]${NC} Installing system dependencies..."
sudo apt-get install -y -qq \
    python3-pip \
    python3-venv \
    git \
    curl \
    ffmpeg \
    inotify-tools \
    ntfs-3g \
    exfatprogs \
    jq \
    rsync \
    libgpiod-dev || echo "Some optional packages not available"

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Create directory structure
echo -e "${YELLOW}[4/12]${NC} Creating directory structure..."
sudo mkdir -p $DEPLOY_PATH
sudo mkdir -p $CONFIG_PATH
sudo mkdir -p $LOG_PATH
sudo mkdir -p $DATA_PATH
sudo mkdir -p /mnt/tesla-cam
sudo mkdir -p /mnt/tesla-storage

sudo chown -R $USER:$USER $DEPLOY_PATH
sudo chown -R $USER:$USER $LOG_PATH
sudo chown -R $USER:$USER $DATA_PATH

echo -e "${GREEN}✅ Directories created${NC}"

# Clone repository if not already present
echo -e "${YELLOW}[5/12]${NC} Setting up application code..."
if [ ! -d "$DEPLOY_PATH/.git" ]; then
    read -p "Enter GitHub repository URL (or press Enter to skip): " REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone $REPO_URL $DEPLOY_PATH
    else
        echo -e "${YELLOW}⚠️  Skipping git clone. Please manually copy files to $DEPLOY_PATH${NC}"
    fi
else
    echo "Repository already cloned"
fi

cd $DEPLOY_PATH

# Set up Python virtual environment
echo -e "${YELLOW}[6/12]${NC} Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r rpi5/requirements.txt -q

echo -e "${GREEN}✅ Python environment ready${NC}"

# Configure USB gadget
echo -e "${YELLOW}[7/12]${NC} Setting up USB gadget mode..."
sudo cp rpi5/config/usb-gadget.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/usb-gadget.sh

# Enable necessary kernel modules
if ! grep -q "dwc2" /boot/config.txt; then
    echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
fi

if ! grep -q "modules-load=dwc2" /boot/cmdline.txt; then
    sudo sed -i '$ s/$/ modules-load=dwc2/' /boot/cmdline.txt
fi

echo -e "${GREEN}✅ USB gadget configured${NC}"

# Create systemd services
echo -e "${YELLOW}[8/12]${NC} Creating systemd services..."

# USB Gadget Service
sudo tee /etc/systemd/system/tesla-usb-gadget.service > /dev/null <<EOF
[Unit]
Description=Tesla USB Storage Gadget
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/usb-gadget.sh start
ExecStop=/usr/local/bin/usb-gadget.sh stop

[Install]
WantedBy=multi-user.target
EOF

# Main Service
sudo tee /etc/systemd/system/tesla-cam-ai.service > /dev/null <<EOF
[Unit]
Description=Tesla Camera AI Service
After=network.target tesla-usb-gadget.service
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$DEPLOY_PATH
Environment="PATH=$DEPLOY_PATH/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=$DEPLOY_PATH/venv/bin/python $DEPLOY_PATH/rpi5/main.py
Restart=always
RestartSec=10
StandardOutput=append:$LOG_PATH/main.log
StandardError=append:$LOG_PATH/error.log

[Install]
WantedBy=multi-user.target
EOF

# Upload Service
sudo tee /etc/systemd/system/tesla-cam-upload.service > /dev/null <<EOF
[Unit]
Description=Tesla Camera Upload Service
After=network-online.target tesla-cam-ai.service
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$DEPLOY_PATH
Environment="PATH=$DEPLOY_PATH/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=$DEPLOY_PATH/venv/bin/python $DEPLOY_PATH/rpi5/upload_agent.py
Restart=always
RestartSec=10
StandardOutput=append:$LOG_PATH/upload.log
StandardError=append:$LOG_PATH/error.log

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✅ Systemd services created${NC}"

# Set up log rotation
echo -e "${YELLOW}[9/12]${NC} Configuring log rotation..."
sudo tee /etc/logrotate.d/tesla-cam-ai > /dev/null <<EOF
$LOG_PATH/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 $USER $USER
    sharedscripts
    postrotate
        systemctl reload tesla-cam-ai >/dev/null 2>&1 || true
    endscript
}
EOF

echo -e "${GREEN}✅ Log rotation configured${NC}"

# Create configuration file
echo -e "${YELLOW}[10/12]${NC} Setting up configuration..."
if [ ! -f "$CONFIG_PATH/config.json" ]; then
    sudo cp rpi5/config/config.example.json $CONFIG_PATH/config.json
    echo -e "${YELLOW}⚠️  Configuration file created at $CONFIG_PATH/config.json${NC}"
    echo -e "${YELLOW}⚠️  Please update it with your Cloudflare credentials${NC}"
fi

# Set up storage
echo -e "${YELLOW}[11/12]${NC} Setting up storage..."
echo -e "Storage setup options:"
echo "1) Use external SSD/USB drive (recommended)"
echo "2) Create file-based storage on SD card (testing only)"
read -p "Choose option (1/2): " STORAGE_OPTION

if [ "$STORAGE_OPTION" == "1" ]; then
    echo "Available drives:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    read -p "Enter device path (e.g., /dev/sda1): " DEVICE_PATH
    
    if [ -b "$DEVICE_PATH" ]; then
        read -p "Format device as exFAT? This will erase all data! (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo mkfs.exfat -n TESLA-CAM $DEVICE_PATH
            echo -e "${GREEN}✅ Device formatted${NC}"
        fi
        
        # Add to fstab
        UUID=$(sudo blkid -s UUID -o value $DEVICE_PATH)
        if ! grep -q "$UUID" /etc/fstab; then
            echo "UUID=$UUID /mnt/tesla-storage exfat defaults,uid=$UID,gid=$GID 0 0" | sudo tee -a /etc/fstab
            sudo mount -a
        fi
    else
        echo -e "${RED}❌ Invalid device path${NC}"
    fi
else
    # Create file-based storage
    sudo dd if=/dev/zero of=/mnt/tesla-storage/tesla-cam.img bs=1M count=102400 status=progress
    sudo mkfs.exfat -n TESLA-CAM /mnt/tesla-storage/tesla-cam.img
fi

echo -e "${GREEN}✅ Storage configured${NC}"

# Enable and start services
echo -e "${YELLOW}[12/12]${NC} Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable tesla-usb-gadget.service
sudo systemctl enable tesla-cam-ai.service
sudo systemctl enable tesla-cam-upload.service

echo -e "${GREEN}✅ Services enabled${NC}"

# Generate SSH key for GitHub Actions
echo -e "${YELLOW}[BONUS]${NC} Setting up GitHub Actions SSH key..."
if [ ! -f "$HOME/.ssh/tesla_cam_deploy" ]; then
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/tesla_cam_deploy" -N "" -C "tesla-cam-deploy"
    cat "$HOME/.ssh/tesla_cam_deploy.pub" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    
    echo -e "${GREEN}✅ SSH key generated${NC}"
    echo -e "${YELLOW}Add this private key to GitHub Secrets as SSH_PRIVATE_KEY:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    cat "$HOME/.ssh/tesla_cam_deploy"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

# Summary
echo
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║                  ✅ Setup Complete!                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo "Next steps:"
echo ""
echo "1. Edit configuration:"
echo "   sudo nano $CONFIG_PATH/config.json"
echo ""
echo "2. Add your Cloudflare credentials"
echo ""
echo "3. Start services:"
echo "   sudo systemctl start tesla-usb-gadget"
echo "   sudo systemctl start tesla-cam-ai"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status tesla-cam-ai"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u tesla-cam-ai -f"
echo ""
echo "6. Connect to Tesla USB port"
echo ""
echo -e "${YELLOW}For GitHub Actions deployment:${NC}"
echo "Add these secrets to your GitHub repository:"
echo "  - SSH_PRIVATE_KEY: (shown above)"
echo "  - CLOUDFLARE_API_TOKEN: Your Cloudflare API token"
echo "  - CLOUDFLARE_ACCOUNT_ID: Your Cloudflare account ID"
echo ""
echo -e "${GREEN}Happy monitoring! 🚗📹🤖${NC}"
