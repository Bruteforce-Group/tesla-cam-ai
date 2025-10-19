# 🧪 Tesla Camera AI - Development Mode Ready!

## ✅ Development Mode Deployed!

You can now test the entire Tesla Camera AI pipeline without connecting to an actual Tesla!

---

## 🎯 What's Available

### 5 Pre-Configured Scenarios

**1. Person Approaching** (Sentry Mode)
- Cameras: Front + Left Repeater
- Duration: 60 seconds
- Tests: Person detection, Sentry alerts

**2. Vehicle Passing** (Dashcam)
- Cameras: Front + Back
- Duration: 30 seconds
- Tests: Vehicle detection, dashcam recording

**3. Parking Lot** (Sentry Mode)
- Cameras: Front + Back + Both Repeaters (4 cameras!)
- Duration: 120 seconds
- Tests: Multi-camera surveillance, complex scenarios

**4. Driving** (Dashcam)
- Cameras: Front + Both Pillars
- Duration: 60 seconds
- Tests: Normal driving, multi-angle recording

**5. Track Mode** (Track)
- Cameras: Front + Narrow Front + Back
- Duration: 180 seconds
- Tests: High-performance recording, extended duration

---

## 🚀 Quick Start

### Method 1: Interactive Menu (Easiest)

```bash
./scripts/start-dev-mode.sh
```

Follow the menu to select your scenario!

### Method 2: Direct Command

```bash
# List scenarios
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --list-scenarios'

# Generate single event
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario person_approaching'

# Run test suite (all scenarios)
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode test-suite'
```

---

## 🎬 What Gets Generated

### Realistic Tesla Files

Each scenario creates MP4 files with:
- **Tesla-style filenames**: `2025-10-19_14-30-00-front.mp4`
- **Proper directory structure**: `TeslaSentry/2025-10-19_14-30-00/`
- **H.264 video codec**: 1920x1080 @ 30fps
- **Overlay information**: Camera name, timestamp, scenario
- **Test patterns**: Color bars for visual verification

### Example Output

```
/mnt/tesla-cam/
├── TeslaSentry/
│   └── 2025-10-19_14-30-00/
│       ├── 2025-10-19_14-30-00-front.mp4
│       └── 2025-10-19_14-30-00-left_repeater.mp4
├── TeslaCam/
│   ├── 2025-10-19_14-00-00-front.mp4
│   └── 2025-10-19_14-00-00-back.mp4
└── TeslaTrackMode/
    └── ...
```

---

## 🔄 Complete Test Workflow

### 1. Generate Test Event

```bash
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario person_approaching'
```

### 2. Watch the Pipeline

```bash
# Watch service logs (file detection + upload)
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log'
```

You'll see:
1. ✅ File detected
2. ✅ Queued for upload
3. ✅ Uploading to Cloudflare Stream
4. ✅ AI analysis triggered

### 3. Verify in Cloudflare

```bash
# Check Stream dashboard
open https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/stream

# Or check API
curl https://tesla-cam-ai.bruteforce.workers.dev/api/events
```

### 4. Check AI Results

```bash
# View detections
curl https://tesla-cam-ai.bruteforce.workers.dev/api/events | jq

# Check alerts
curl https://tesla-cam-ai.bruteforce.workers.dev/api/alerts
```

---

## 🎯 Testing Modes

### Single Event
Test one scenario at a time:
```bash
python rpi5/dev_mode.py --mode single --scenario parking_lot
```

### Continuous Feed
Generate events every N seconds:
```bash
python rpi5/dev_mode.py --mode continuous --interval 30
# Stop with Ctrl+C
```

### Complete Test Suite
All scenarios at once:
```bash
python rpi5/dev_mode.py --mode test-suite
```

### Stress Test
Multiple random events:
```bash
python rpi5/dev_mode.py --mode stress --count 20
```

---

## 📊 What Gets Tested

✓ File system monitoring
✓ Tesla filename parsing  
✓ Upload queue management
✓ Cloudflare Stream integration
✓ AI object detection
✓ Database storage
✓ Alert generation
✓ Real-time WebSocket updates
✓ Error handling
✓ Retry logic

**Basically: THE ENTIRE PIPELINE!** 🚀

---

## 💡 Development Tips

### Test AI Detection

```bash
# Generate person scenario
python rpi5/dev_mode.py --mode single --scenario person_approaching

# Wait 2 minutes for AI processing
# Check for person detection alert
curl https://tesla-cam-ai.bruteforce.workers.dev/api/alerts
```

### Test Multiple Cameras

```bash
# Parking lot has 4 cameras
python rpi5/dev_mode.py --mode single --scenario parking_lot

# Verify all 4 videos upload
```

### Test Load Handling

```bash
# Generate 50 events
python rpi5/dev_mode.py --mode stress --count 50

# Monitor queue and upload performance
```

### Test Continuous Operation

```bash
# Run overnight
nohup python rpi5/dev_mode.py --mode continuous --interval 120 &

# Check in the morning for any errors
```

---

## 🧹 Cleanup Test Data

### Remove Generated Files

```bash
ssh danielborrowman@192.168.222.60 'sudo rm -rf /mnt/tesla-cam/TeslaSentry/* /mnt/tesla-cam/TeslaCam/* /mnt/tesla-cam/TeslaTrackMode/*'
```

### Clear Database

```bash
cd workers
npx wrangler d1 execute tesla-cam-db --remote --command="DELETE FROM events WHERE camera IN ('front', 'back', 'left_repeater')"
```

### Delete from Stream

Use Cloudflare dashboard to remove test videos

---

## 🎨 Customization

### Add Your Own Scenario

Edit `rpi5/dev_mode.py`:

```python
SCENARIOS = {
    'my_test': {
        'event_type': 'sentry',
        'cameras': ['front', 'back', 'left_repeater'],
        'duration': 45,
        'description': 'My custom test scenario'
    }
}
```

### Modify Video Properties

In `create_dummy_video()` function:
- Change resolution
- Adjust frame rate
- Customize overlays
- Add different test patterns

---

## 📋 Quick Commands

```bash
# List scenarios
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --list-scenarios'

# Generate person approaching
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario person_approaching'

# Run test suite
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode test-suite'

# Watch logs
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log | grep -i "queued\|upload"'
```

---

## ✨ Benefits of Dev Mode

✅ **No Tesla Required** - Test everything locally
✅ **Repeatable Tests** - Same scenarios every time
✅ **Fast Iteration** - No waiting for real events
✅ **Complete Coverage** - All cameras, all scenarios
✅ **Load Testing** - Generate 100s of events
✅ **Demo Ready** - Show off the system

---

## 🎊 Dev Mode Is Ready!

**Try it now:**
```bash
./scripts/start-dev-mode.sh
```

Or generate a quick test:
```bash
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario person_approaching'
```

**Then watch the magic:**
```bash
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log'
```

---

**Full Documentation:** See `DEV_MODE_GUIDE.md` for complete instructions!

🧪 Happy testing! 📹🤖✨


