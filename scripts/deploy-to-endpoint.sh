#!/bin/bash
# Manual deployment script to push changes to the endpoint
# Usage: ./deploy-to-endpoint.sh

set -e

# Configuration
ENDPOINT_HOST="192.168.222.60"
ENDPOINT_USER="danielborrowman"
DEPLOY_PATH="/opt/tesla-cam-ai"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying to $ENDPOINT_USER@$ENDPOINT_HOST${NC}"

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 $ENDPOINT_USER@$ENDPOINT_HOST "echo 'Connection OK'"; then
    echo -e "${RED}❌ Cannot connect to endpoint${NC}"
    echo "Make sure:"
    echo "  1. The endpoint is powered on"
    echo "  2. You have SSH access"
    echo "  3. The IP address is correct"
    exit 1
fi

# Create deployment package
echo -e "${YELLOW}📦 Creating deployment package...${NC}"
tar --exclude='rpi5/__pycache__' \
    --exclude='rpi5/*.pyc' \
    --exclude='rpi5/.pytest_cache' \
    --exclude='rpi5/venv' \
    -czf /tmp/tesla-cam-deploy.tar.gz \
    rpi5/

# Upload package
echo -e "${YELLOW}📤 Uploading to endpoint...${NC}"
scp /tmp/tesla-cam-deploy.tar.gz $ENDPOINT_USER@$ENDPOINT_HOST:/tmp/

# Deploy on endpoint
echo -e "${YELLOW}🔧 Deploying on endpoint...${NC}"
ssh $ENDPOINT_USER@$ENDPOINT_HOST << 'ENDSSH'
    set -e
    
    DEPLOY_PATH="/opt/tesla-cam-ai"
    BACKUP_DIR="$DEPLOY_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo "Creating backup..."
    if [ -d "$DEPLOY_PATH" ]; then
        sudo cp -r $DEPLOY_PATH $BACKUP_DIR
        echo "Backup created at $BACKUP_DIR"
    fi
    
    echo "Extracting new version..."
    sudo mkdir -p $DEPLOY_PATH
    sudo tar -xzf /tmp/tesla-cam-deploy.tar.gz -C $DEPLOY_PATH --strip-components=1
    sudo chown -R $USER:$USER $DEPLOY_PATH
    
    echo "Updating dependencies..."
    cd $DEPLOY_PATH
    if [ -d "venv" ]; then
        source venv/bin/activate
        pip install --upgrade pip -q
        pip install -r requirements.txt -q
    fi
    
    echo "Restarting services..."
    sudo systemctl daemon-reload
    sudo systemctl restart tesla-cam-ai.service
    sudo systemctl restart tesla-cam-upload.service
    
    echo "Checking service status..."
    if systemctl is-active --quiet tesla-cam-ai.service; then
        echo "✅ Service is running"
    else
        echo "❌ Service failed to start"
        echo "Rolling back..."
        sudo rm -rf $DEPLOY_PATH
        sudo mv $BACKUP_DIR $DEPLOY_PATH
        sudo systemctl restart tesla-cam-ai.service
        exit 1
    fi
    
    # Cleanup
    rm /tmp/tesla-cam-deploy.tar.gz
    
    echo "Deployment complete!"
ENDSSH

# Cleanup local
rm /tmp/tesla-cam-deploy.tar.gz

echo -e "${GREEN}✅ Deployment successful!${NC}"
echo ""
echo "View logs:"
echo "  ssh $ENDPOINT_USER@$ENDPOINT_HOST 'sudo journalctl -u tesla-cam-ai -f'"
echo ""
echo "Check status:"
echo "  ssh $ENDPOINT_USER@$ENDPOINT_HOST 'sudo systemctl status tesla-cam-ai'"
