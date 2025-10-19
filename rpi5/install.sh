#!/bin/bash
# Tesla Cam AI - Raspberry Pi 5 Installation Script

set -e

echo "==================================="
echo "Tesla Cam AI Installation Script"
echo "==================================="

# Check if running on Raspberry Pi 5
if ! grep -q "Raspberry Pi 5" /proc/device-tree/model 2>/dev/null; then
    echo "Warning: This script is optimized for Raspberry Pi 5"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    git \
    curl \
    ffmpeg \
    inotify-tools \
    ntfs-3g \
    exfat-fuse \
    exfat-utils \
    nodejs \
    npm \
    jq \
    rsync

# Install USB gadget dependencies
echo "Installing USB gadget dependencies..."
sudo apt-get install -y \
    linux-modules-extra-raspi

# Create application directory
echo "Creating application directory..."
sudo mkdir -p /opt/tesla-cam-ai
sudo chown $USER:$USER /opt/tesla-cam-ai

# Clone repository
echo "Cloning Tesla Cam AI repository..."
cd /opt/tesla-cam-ai
git clone https://github.com/yourusername/tesla-cam-ai.git . || echo "Using local files"

# Set up Python virtual environment
echo "Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create directories
echo "Creating directory structure..."
sudo mkdir -p /mnt/tesla-cam
sudo mkdir -p /mnt/tesla-storage
sudo mkdir -p /var/log/tesla-cam-ai
sudo mkdir -p /etc/tesla-cam-ai

# Set up USB gadget configuration
echo "Configuring USB gadget mode..."
sudo cp config/usb-gadget.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/usb-gadget.sh

# Create systemd service for USB gadget
sudo tee /etc/systemd/system/tesla-usb-gadget.service > /dev/null <<EOF
[Unit]
Description=Tesla USB Storage Gadget
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/usb-gadget.sh
ExecStop=/usr/local/bin/usb-gadget.sh stop

[Install]
WantedBy=multi-user.target
EOF

# Create main service
sudo tee /etc/systemd/system/tesla-cam-ai.service > /dev/null <<EOF
[Unit]
Description=Tesla Camera AI Streaming Service
After=network.target tesla-usb-gadget.service

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/tesla-cam-ai
Environment="PATH=/opt/tesla-cam-ai/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/tesla-cam-ai/venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create upload service
sudo tee /etc/systemd/system/tesla-cam-upload.service > /dev/null <<EOF
[Unit]
Description=Tesla Camera Upload Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/tesla-cam-ai
Environment="PATH=/opt/tesla-cam-ai/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/tesla-cam-ai/venv/bin/python upload_agent.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set up configuration
echo "Setting up configuration..."
if [ ! -f /etc/tesla-cam-ai/config.json ]; then
    sudo cp config/config.example.json /etc/tesla-cam-ai/config.json
    echo "Please edit /etc/tesla-cam-ai/config.json with your Cloudflare credentials"
fi

# Set up log rotation
sudo tee /etc/logrotate.d/tesla-cam-ai > /dev/null <<EOF
/var/log/tesla-cam-ai/*.log {
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

# Enable services
echo "Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable tesla-usb-gadget.service
sudo systemctl enable tesla-cam-ai.service
sudo systemctl enable tesla-cam-upload.service

# Create storage partition (if not exists)
echo "Setting up storage partition..."
if [ ! -e /dev/disk/by-label/TESLA-CAM ]; then
    echo "Please set up your storage device with label TESLA-CAM"
    echo "Example: sudo mkfs.exfat -n TESLA-CAM /dev/sda1"
fi

# Final setup
echo "Running final setup..."
sudo usermod -a -G video $USER
sudo usermod -a -G dialout $USER

echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. Edit /etc/tesla-cam-ai/config.json with your Cloudflare credentials"
echo "2. Set up your storage device with label TESLA-CAM"
echo "3. Reboot your Raspberry Pi: sudo reboot"
echo "4. Connect to your Tesla's USB port"
echo ""
echo "The Tesla should recognize the Pi as a USB drive after reboot."
