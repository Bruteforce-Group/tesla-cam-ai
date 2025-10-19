# Tesla Cam AI - Copy/Paste Values

All the values you need in one place for quick copy/paste!

---

## 🔐 FOR GITHUB SECRETS

### SSH_PRIVATE_KEY
```bash
# Get the key:
cat /tmp/github_ssh_key.txt

# Or directly from Pi:
ssh danielborrowman@192.168.222.60 'cat ~/.ssh/tesla_cam_deploy'
```

### CLOUDFLARE_ACCOUNT_ID
```
0b0ee2b5eaf1fb8a2612e40ab6488052
```

### CLOUDFLARE_API_TOKEN
```
Get from: https://dash.cloudflare.com/profile/api-tokens
(Create new token with Stream, Workers, D1, R2 permissions)
```

---

## ⚙️ FOR WRANGLER.TOML

**File:** `workers/wrangler.toml`

**Account ID** (already set):
```toml
account_id = "0b0ee2b5eaf1fb8a2612e40ab6488052"
```

**Database ID** (already set):
```toml
database_id = "09f4ad01-e5b5-4625-b1bf-160c644c54d6"
```

**KV Namespace** (already set):
```toml
id = "011fb094f2eb4ee6b3212ef05da9d857"
```

**Stream values** (NEED TO UPDATE):
```toml
STREAM_API_TOKEN = "GET_FROM_STREAM_API_PAGE"
STREAM_ACCOUNT_ID = "0b0ee2b5eaf1fb8a2612e40ab6488052"
WORKER_API_KEY = "KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w="
```

---

## 🤖 FOR PI CONFIG.JSON

**File:** `/etc/tesla-cam-ai/config.json` (on Pi)

**Values to replace:**

```json
{
  "cloudflare": {
    "account_id": "0b0ee2b5eaf1fb8a2612e40ab6488052",
    "api_token": "PASTE_YOUR_CLOUDFLARE_API_TOKEN",
    "worker_api": {
      "base_url": "https://tesla-cam-ai.bozza.au.workers.dev",
      "api_key": "KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w="
    }
  }
}
```

---

## 🔗 QUICK LINKS

**Cloudflare Stream:**
https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/stream

**Create API Token:**
https://dash.cloudflare.com/profile/api-tokens

**Your Workers:**
https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/workers

**D1 Database:**
https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/workers/d1

**R2 Storage:**
https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/r2

---

## 📝 COMMANDS

### View SSH Key
```bash
cat /tmp/github_ssh_key.txt
```

### Edit Wrangler Config
```bash
cd workers
nano wrangler.toml
```

### Edit Pi Config
```bash
ssh danielborrowman@192.168.222.60 'sudo nano /etc/tesla-cam-ai/config.json'
```

### Deploy Workers
```bash
cd workers
npx wrangler deploy
```

### Start Service
```bash
ssh danielborrowman@192.168.222.60 'sudo systemctl start tesla-cam-ai'
```

### Check Status
```bash
ssh danielborrowman@192.168.222.60 'sudo systemctl status tesla-cam-ai'
```

### View Logs
```bash
ssh danielborrowman@192.168.222.60 'sudo journalctl -u tesla-cam-ai -f'
```

---

## 📋 GENERATED VALUES

**Worker API Key** (for config.json and wrangler.toml):
```
KqwfqrQ4x0IOSmVp/pHn/vsgeku/jCUEeg0vzaCHU1w=
```

**Cloudflare Account ID:**
```
0b0ee2b5eaf1fb8a2612e40ab6488052
```

**D1 Database ID:**
```
09f4ad01-e5b5-4625-b1bf-160c644c54d6
```

**KV Namespace ID:**
```
011fb094f2eb4ee6b3212ef05da9d857
```

**Raspberry Pi:**
```
danielborrowman@192.168.222.60
```

---

This file has all the values you need for quick copy/paste! 📋✨
