#!/bin/bash
# Remote setup script - Run this from your local machine
# It will SSH into the endpoint and run the initial setup
# Usage: ./remote-setup.sh

set -e

ENDPOINT_HOST="192.168.222.60"
ENDPOINT_USER="danielborrowman"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Tesla Cam AI - Remote Setup${NC}"
echo -e "${YELLOW}Target: $ENDPOINT_USER@$ENDPOINT_HOST${NC}"
echo ""

# Test connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 $ENDPOINT_USER@$ENDPOINT_HOST "echo 'Connected'"; then
    echo -e "${RED}❌ Cannot connect to endpoint${NC}"
    echo "Please ensure:"
    echo "  1. Raspberry Pi is powered on and connected to network"
    echo "  2. You have SSH access (password or key)"
    echo "  3. IP address is correct (currently: $ENDPOINT_HOST)"
    exit 1
fi

echo -e "${GREEN}✅ Connection successful${NC}"
echo ""

# Ask for confirmation
read -p "This will set up Tesla Cam AI on the endpoint. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Upload setup script
echo -e "${YELLOW}📤 Uploading setup script...${NC}"
scp scripts/initial-setup.sh $ENDPOINT_USER@$ENDPOINT_HOST:/tmp/

# Upload repository files
echo -e "${YELLOW}📤 Uploading application files...${NC}"
tar --exclude='rpi5/__pycache__' \
    --exclude='rpi5/*.pyc' \
    --exclude='rpi5/.pytest_cache' \
    -czf /tmp/tesla-cam-ai.tar.gz \
    rpi5/ \
    scripts/ \
    migrations/

scp /tmp/tesla-cam-ai.tar.gz $ENDPOINT_USER@$ENDPOINT_HOST:/tmp/
rm /tmp/tesla-cam-ai.tar.gz

# Run setup on endpoint
echo -e "${YELLOW}🚀 Running setup on endpoint...${NC}"
echo -e "${YELLOW}This may take 10-15 minutes...${NC}"
echo ""

ssh -t $ENDPOINT_USER@$ENDPOINT_HOST << 'ENDSSH'
    set -e
    
    # Create and populate the deploy directory first
    echo "Preparing application directory..."
    sudo mkdir -p /opt/tesla-cam-ai
    sudo chown -R $USER:$USER /opt/tesla-cam-ai
    
    # Extract files to deploy directory
    cd /opt/tesla-cam-ai
    tar -xzf /tmp/tesla-cam-ai.tar.gz
    
    # Make setup script executable
    chmod +x /tmp/initial-setup.sh
    
    # Run setup
    /tmp/initial-setup.sh
    
    # Cleanup
    rm /tmp/tesla-cam-ai.tar.gz
    rm /tmp/initial-setup.sh
    
    echo ""
    echo "Setup script completed!"
ENDSSH

echo ""
echo -e "${GREEN}✅ Remote setup complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure Cloudflare credentials:"
echo "   ssh $ENDPOINT_USER@$ENDPOINT_HOST"
echo "   sudo nano /etc/tesla-cam-ai/config.json"
echo ""
echo "2. Start services:"
echo "   ssh $ENDPOINT_USER@$ENDPOINT_HOST 'sudo systemctl start tesla-cam-ai'"
echo ""
echo "3. View logs:"
echo "   ssh $ENDPOINT_USER@$ENDPOINT_HOST 'sudo journalctl -u tesla-cam-ai -f'"
echo ""
echo "4. Set up GitHub Actions (see GITHUB_SETUP.md)"
echo ""
echo -e "${YELLOW}SSH key for GitHub Actions:${NC}"
echo "   ssh $ENDPOINT_USER@$ENDPOINT_HOST 'cat ~/.ssh/tesla_cam_deploy'"
echo ""
