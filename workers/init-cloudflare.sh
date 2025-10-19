#!/bin/bash
# Initialize Cloudflare services for Tesla Cam AI
# Run this once to set up all required Cloudflare infrastructure

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================="
echo "Tesla Cam AI - Cloudflare Setup"
echo "===================================${NC}"
echo ""

# Check if wrangler is logged in
if ! wrangler whoami &>/dev/null; then
    echo -e "${YELLOW}Not logged in to Cloudflare${NC}"
    echo "Running: wrangler login"
    wrangler login
fi

echo -e "${GREEN}✅ Authenticated with Cloudflare${NC}"
echo ""

# Get account ID
echo -e "${YELLOW}Getting account information...${NC}"
ACCOUNT_ID=$(wrangler whoami | grep "Account ID" | awk '{print $3}' | head -1)
echo -e "${GREEN}Account ID: ${ACCOUNT_ID}${NC}"
echo ""

# Create D1 database
echo -e "${YELLOW}[1/4] Creating D1 database...${NC}"
if wrangler d1 list | grep -q "tesla-cam-db"; then
    echo "✅ Database already exists"
    DB_ID=$(wrangler d1 list | grep "tesla-cam-db" | awk '{print $2}')
else
    DB_OUTPUT=$(wrangler d1 create tesla-cam-db)
    DB_ID=$(echo "$DB_OUTPUT" | grep "database_id" | cut -d'"' -f4)
    echo -e "${GREEN}✅ Created D1 database: ${DB_ID}${NC}"
fi
echo ""

# Create R2 bucket
echo -e "${YELLOW}[2/4] Creating R2 bucket...${NC}"
if wrangler r2 bucket list | grep -q "tesla-cam-archive"; then
    echo "✅ Bucket already exists"
else
    wrangler r2 bucket create tesla-cam-archive
    echo -e "${GREEN}✅ Created R2 bucket: tesla-cam-archive${NC}"
fi
echo ""

# Create KV namespace
echo -e "${YELLOW}[3/4] Creating KV namespace...${NC}"
if wrangler kv:namespace list | grep -q "DEVICE_STATUS"; then
    echo "✅ KV namespace already exists"
    KV_ID=$(wrangler kv:namespace list | grep "DEVICE_STATUS" | jq -r '.id')
else
    KV_OUTPUT=$(wrangler kv:namespace create DEVICE_STATUS)
    KV_ID=$(echo "$KV_OUTPUT" | grep "id" | cut -d'"' -f4)
    echo -e "${GREEN}✅ Created KV namespace: ${KV_ID}${NC}"
fi
echo ""

# Create Queue
echo -e "${YELLOW}[4/4] Creating Queue...${NC}"
if wrangler queues list | grep -q "ai-processing"; then
    echo "✅ Queue already exists"
else
    wrangler queues create ai-processing
    echo -e "${GREEN}✅ Created Queue: ai-processing${NC}"
fi
echo ""

# Update wrangler.toml with IDs
echo -e "${YELLOW}Updating wrangler.toml with service IDs...${NC}"

# Create backup
cp wrangler.toml wrangler.toml.backup

# Update account_id
sed -i.bak "s/account_id = \"YOUR_ACCOUNT_ID\"/account_id = \"${ACCOUNT_ID}\"/" wrangler.toml

# Update database_id
sed -i.bak "s/database_id = \"YOUR_D1_DATABASE_ID\"/database_id = \"${DB_ID}\"/" wrangler.toml

# Update KV id
sed -i.bak "s/id = \"YOUR_KV_NAMESPACE_ID\"/id = \"${KV_ID}\"/" wrangler.toml

rm wrangler.toml.bak

echo -e "${GREEN}✅ wrangler.toml updated${NC}"
echo ""

# Run database migrations
echo -e "${YELLOW}Running database migrations...${NC}"
wrangler d1 execute tesla-cam-db --file=../migrations/schema.sql || echo "Migrations may have already run"
echo -e "${GREEN}✅ Database schema created${NC}"
echo ""

# Summary
echo -e "${GREEN}==================================="
echo "Setup Complete!"
echo "===================================${NC}"
echo ""
echo "Your Cloudflare services:"
echo "  📊 D1 Database: tesla-cam-db (${DB_ID})"
echo "  🗄️  R2 Bucket: tesla-cam-archive"
echo "  💾 KV Namespace: DEVICE_STATUS (${KV_ID})"
echo "  📨 Queue: ai-processing"
echo ""
echo "Next steps:"
echo "  1. Update STREAM_API_TOKEN in wrangler.toml"
echo "  2. Update STREAM_ACCOUNT_ID in wrangler.toml"
echo "  3. Run: npx wrangler deploy"
echo ""
echo -e "${YELLOW}Get Stream API token from: https://dash.cloudflare.com → Stream → API${NC}"
echo ""
