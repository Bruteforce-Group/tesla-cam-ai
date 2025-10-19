# Tesla Cam AI - Final Setup Steps

## ✅ What's Already Done

- ✅ Raspberry Pi 5 fully configured (`192.168.222.60`)
- ✅ All Cloudflare services created
- ✅ Database schema deployed (36 tables)
- ✅ Wrangler upgraded to v4.43.0
- ✅ SSH key generated
- ✅ Worker API key generated

## 🎯 3 Quick Actions to Complete

### ACTION 1: Enable Stream & Get API Token (2 min)

**I opened the Stream dashboard for you!**

If not open, go to: https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/stream

**Steps:**
1. Click **Enable Stream** if needed
2. Go to **Stream** → **API** (left menu)
3. Click **Create Token** or use existing
4. Copy the API token shown

**Update wrangler.toml:**
```bash
cd workers
nano wrangler.toml
```

Find the `[vars]` section and replace:
```toml
STREAM_API_TOKEN = "paste_your_stream_token_here"
STREAM_ACCOUNT_ID = "0b0ee2b5eaf1fb8a2612e40ab6488052"
WORKER_API_KEY = "KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w="
```

---

### ACTION 2: Update Pi Configuration (2 min)

```bash
ssh danielborrowman@192.168.222.60
sudo nano /etc/tesla-cam-ai/config.json
```

**Replace these values:**

```json
{
  "cloudflare": {
    "account_id": "0b0ee2b5eaf1fb8a2612e40ab6488052",
    "api_token": "PASTE_YOUR_CLOUDFLARE_API_TOKEN_HERE",
    "worker_api": {
      "base_url": "https://tesla-cam-ai.bozza.au.workers.dev",
      "api_key": "KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w="
    }
  }
}
```

**Save:** `Ctrl+X` → `Y` → `Enter`

**For the API token:** Use the same one from Stream, or create a new one at:
https://dash.cloudflare.com/profile/api-tokens

---

### ACTION 3: Add GitHub Secrets (3 min)

**Go to your GitHub repository:**
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

**Add these 3 secrets:**

#### 1. SSH_PRIVATE_KEY
```bash
# Get the key:
cat /tmp/github_ssh_key.txt
```

- **Name**: `SSH_PRIVATE_KEY`
- **Value**: Copy the entire output (including BEGIN/END lines)

#### 2. CLOUDFLARE_API_TOKEN
- **Name**: `CLOUDFLARE_API_TOKEN`
- **Value**: Same token you used in wrangler.toml

#### 3. CLOUDFLARE_ACCOUNT_ID
- **Name**: `CLOUDFLARE_ACCOUNT_ID`
- **Value**: `0b0ee2b5eaf1fb8a2612e40ab6488052`

---

## 🚀 Deploy Everything!

### Step 1: Deploy Workers
```bash
cd workers
npx wrangler deploy
```

### Step 2: Start Service on Pi
```bash
ssh danielborrowman@192.168.222.60 'sudo systemctl start tesla-cam-ai'
```

### Step 3: Verify It's Running
```bash
# Check service status
ssh danielborrowman@192.168.222.60 'sudo systemctl status tesla-cam-ai'

# View logs
ssh danielborrowman@192.168.222.60 'sudo journalctl -u tesla-cam-ai -f'
```

### Step 4: Test API
```bash
curl https://tesla-cam-ai.bozza.au.workers.dev/api/health
```

### Step 5: Push to GitHub (Triggers Auto-Deployment)
```bash
cd ..
git add .
git commit -m "feat: Tesla Cam AI production deployment"
git push origin main
```

---

## 📋 Values Summary

**All your configuration values in one place:**

| Setting | Value |
|---------|-------|
| **Account ID** | `0b0ee2b5eaf1fb8a2612e40ab6488052` |
| **D1 Database ID** | `09f4ad01-e5b5-4625-b1bf-160c644c54d6` |
| **KV Namespace ID** | `011fb094f2eb4ee6b3212ef05da9d857` |
| **R2 Bucket** | `tesla-cam-archive` |
| **Queue** | `ai-processing` |
| **Worker API Key** | `KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w=` |
| **Pi Address** | `danielborrowman@192.168.222.60` |
| **Worker URL** | `https://tesla-cam-ai.bozza.au.workers.dev` |

---

## 🎯 Completion Timeline

1. **Enable Stream** - 2 minutes ⏰
2. **Update wrangler.toml** - 1 minute
3. **Update Pi config** - 2 minutes
4. **Add GitHub Secrets** - 3 minutes
5. **Deploy Workers** - 2 minutes
6. **Start service** - 1 minute

**Total: ~11 minutes to full operation!**

---

## 🆘 Quick Help

### View SSH Key
```bash
cat /tmp/github_ssh_key.txt
```

### Check Service
```bash
ssh danielborrowman@192.168.222.60 'sudo systemctl status tesla-cam-ai'
```

### View Logs
```bash
ssh danielborrowman@192.168.222.60 'sudo journalctl -u tesla-cam-ai -f'
```

### Test Connection
```bash
ssh danielborrowman@192.168.222.60 'echo "Connected!"'
```

---

**Next:** Enable Stream in the browser window I opened, then follow the 3 actions above! 🚀
