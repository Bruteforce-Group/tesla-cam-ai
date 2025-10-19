#!/bin/bash
# Quick configuration helper script
# Run this after you get your Stream API token

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Tesla Cam AI - Configuration Helper${NC}"
echo ""

# Get Stream API Token
read -p "Enter your Cloudflare Stream API token: " STREAM_TOKEN
if [ -z "$STREAM_TOKEN" ]; then
    echo -e "${RED}Stream API token is required!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Updating configurations...${NC}"

# Update wrangler.toml
cd workers
cp wrangler.toml wrangler.toml.backup

sed -i.bak "s/STREAM_API_TOKEN = \"YOUR_STREAM_API_TOKEN\"/STREAM_API_TOKEN = \"${STREAM_TOKEN}\"/" wrangler.toml
sed -i.bak "s/STREAM_ACCOUNT_ID = \"YOUR_STREAM_ACCOUNT_ID\"/STREAM_ACCOUNT_ID = \"0b0ee2b5eaf1fb8a2612e40ab6488052\"/" wrangler.toml
sed -i.bak "s/WORKER_API_KEY = \"YOUR_WORKER_API_KEY\"/WORKER_API_KEY = \"KqwfqrQ4x0IOSmVp\/pHn\/vsgeku\/jCUEeg0vzaCHU1w=\"/" wrangler.toml

rm wrangler.toml.bak

echo -e "${GREEN}✅ wrangler.toml updated${NC}"
cd ..

# Update Pi configuration
echo ""
echo -e "${YELLOW}Updating Pi configuration...${NC}"

ssh danielborrowman@192.168.222.60 << EOF
    # Create temp config with values
    cat /etc/tesla-cam-ai/config.json | \
    sed 's/"account_id": "YOUR_CLOUDFLARE_ACCOUNT_ID"/"account_id": "0b0ee2b5eaf1fb8a2612e40ab6488052"/' | \
    sed 's/"api_token": "YOUR_CLOUDFLARE_API_TOKEN"/"api_token": "${STREAM_TOKEN}"/' | \
    sed 's/"api_key": "YOUR_WORKER_API_KEY"/"api_key": "KqwfqrQ4x0IOSmVp\/pHn\/vsgeku\/jCUEeg0vzaCHU1w="/' | \
    sed 's/"base_url": "https:\/\/tesla-cam-api.yourdomain.workers.dev"/"base_url": "https:\/\/tesla-cam-ai.bozza.au.workers.dev"/' | \
    sudo tee /etc/tesla-cam-ai/config.json.new > /dev/null
    
    sudo mv /etc/tesla-cam-ai/config.json.new /etc/tesla-cam-ai/config.json
EOF

echo -e "${GREEN}✅ Pi configuration updated${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Configuration Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Deploy Workers:"
echo "   cd workers && npx wrangler deploy"
echo ""
echo "2. Start service:"
echo "   ssh danielborrowman@192.168.222.60 'sudo systemctl start tesla-cam-ai'"
echo ""
echo "3. View logs:"
echo "   ssh danielborrowman@192.168.222.60 'sudo journalctl -u tesla-cam-ai -f'"
echo ""
echo "4. Test API:"
echo "   curl https://tesla-cam-ai.bozza.au.workers.dev/api/health"
echo ""
