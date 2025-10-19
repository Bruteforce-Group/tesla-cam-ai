# Tesla Camera AI - Development Mode Guide

## 🧪 What is Development Mode?

Development mode allows you to test the entire Tesla Camera AI system without connecting to an actual Tesla vehicle. It generates realistic dummy video feeds simulating all Tesla cameras.

Perfect for:
- Testing the upload pipeline
- Verifying AI detection
- Testing alert system
- Dashboard development
- Load testing
- Demo purposes

## 🎬 Available Scenarios

### 1. Person Approaching (Sentry)
- **Cameras**: Front, Left Repeater
- **Duration**: 60 seconds
- **Purpose**: Tests person detection and Sentry alerts

### 2. Vehicle Passing (Dashcam)
- **Cameras**: Front, Back
- **Duration**: 30 seconds
- **Purpose**: Tests vehicle detection

### 3. Parking Lot (Sentry)
- **Cameras**: Front, Back, Left Repeater, Right Repeater
- **Duration**: 120 seconds
- **Purpose**: Tests multi-camera surveillance

### 4. Driving (Dashcam)
- **Cameras**: Front, Left Pillar, Right Pillar
- **Duration**: 60 seconds
- **Purpose**: Tests normal driving scenario

### 5. Track Mode
- **Cameras**: Front, Narrow Front, Back
- **Duration**: 180 seconds
- **Purpose**: Tests high-performance recording

## 🚀 Quick Start

### Option 1: Interactive Script (Easiest)

```bash
./scripts/start-dev-mode.sh
```

Follow the menu to select your scenario.

### Option 2: Direct Commands

```bash
# SSH into Pi
ssh danielborrowman@192.168.222.60

# Activate environment
cd /opt/tesla-cam-ai
source venv/bin/activate

# Run dev mode
python rpi5/dev_mode.py --mode single --scenario person_approaching
```

## 📋 Usage Examples

### Generate Single Event

```bash
# Person approaching (Sentry mode)
python rpi5/dev_mode.py --mode single --scenario person_approaching

# Vehicle passing
python rpi5/dev_mode.py --mode single --scenario vehicle_passing

# Parking lot surveillance
python rpi5/dev_mode.py --mode single --scenario parking_lot
```

### Continuous Feed

Generate events continuously:

```bash
# Generate event every 60 seconds
python rpi5/dev_mode.py --mode continuous --interval 60

# Generate event every 30 seconds
python rpi5/dev_mode.py --mode continuous --interval 30
```

**Stop with**: `Ctrl+C`

### Complete Test Suite

Generate all scenarios at once:

```bash
python rpi5/dev_mode.py --mode test-suite
```

This creates one event for each scenario, spaced 15 minutes apart in timestamp.

### Stress Test

Generate many random events for load testing:

```bash
# Generate 10 random events
python rpi5/dev_mode.py --mode stress --count 10

# Generate 50 events
python rpi5/dev_mode.py --mode stress --count 50
```

### List All Scenarios

```bash
python rpi5/dev_mode.py --list-scenarios
```

## 📊 What Gets Created

### File Structure

```
/mnt/tesla-cam/
├── TeslaSentry/
│   ├── 2025-10-19_14-30-00/
│   │   ├── 2025-10-19_14-30-00-front.mp4
│   │   ├── 2025-10-19_14-30-00-left_repeater.mp4
│   │   └── ...
│   └── ...
├── TeslaCam/
│   ├── 2025-10-19_14-00-00-front.mp4
│   └── ...
└── TeslaTrackMode/
    └── ...
```

### Video Specifications

Each video file:
- **Resolution**: 1920x1080
- **Frame Rate**: 30 FPS
- **Format**: H.264 (MP4)
- **Audio**: AAC
- **Overlays**:
  - Camera name
  - Timestamp
  - Scenario description

## 🔄 Complete Test Workflow

### 1. Generate Test Data

```bash
ssh danielborrowman@192.168.222.60 << 'EOF'
cd /opt/tesla-cam-ai
source venv/bin/activate
python rpi5/dev_mode.py --mode test-suite
EOF
```

### 2. Watch Upload Process

```bash
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log'
```

You should see:
- File detection
- Upload queue
- Cloudflare Stream upload
- AI analysis triggered

### 3. Verify in Cloudflare

1. Go to: https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/stream
2. Check for uploaded videos
3. Videos should appear within 1-2 minutes

### 4. Check API

```bash
# Check events
curl https://tesla-cam-ai.bruteforce.workers.dev/api/events

# Check analytics
curl https://tesla-cam-ai.bruteforce.workers.dev/api/analytics
```

### 5. Verify Database

```bash
cd workers
npx wrangler d1 execute tesla-cam-db --command="SELECT COUNT(*) as total FROM events"
```

## 🎯 Testing Scenarios

### Test Person Detection

```bash
# Generate person approaching scenario
python rpi5/dev_mode.py --mode single --scenario person_approaching

# Wait for upload (1-2 minutes)
# Check alerts API
curl https://tesla-cam-ai.bruteforce.workers.dev/api/alerts
```

### Test Multiple Cameras

```bash
# Generate parking lot (4 cameras)
python rpi5/dev_mode.py --mode single --scenario parking_lot

# Verify all 4 videos uploaded
```

### Test Continuous Recording

```bash
# Start continuous generation
python rpi5/dev_mode.py --mode continuous --interval 30

# Let it run for 5 minutes
# Should generate ~10 events
# Verify upload queue handling
```

### Load Testing

```bash
# Generate 50 events rapidly
python rpi5/dev_mode.py --mode stress --count 50

# Monitor system performance
# Check upload queue handling
# Verify no data loss
```

## 🔧 Advanced Usage

### Custom Scenario

Create your own scenario by editing `dev_mode.py`:

```python
SCENARIOS = {
    'my_custom_scenario': {
        'event_type': 'sentry',
        'cameras': ['front', 'back'],
        'duration': 45,
        'description': 'My custom test'
    }
}
```

### Configure Generation

Edit scenario parameters:
- Duration (seconds)
- Which cameras to use
- Event type (sentry/dashcam/track)

### Scheduled Generation

Use cron to generate events automatically:

```bash
# Add to crontab
crontab -e

# Generate event every hour
0 * * * * cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single
```

## 📊 Monitoring Dev Mode

### Watch File Creation

```bash
watch -n 1 'ls -lh /mnt/tesla-cam/TeslaSentry/ | tail -10'
```

### Monitor Upload Queue

```bash
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log | grep -i "queued\|upload"'
```

### Check Cloudflare Stream

```bash
# List recent videos
cd workers
npx wrangler tail
```

## 🧹 Cleanup

### Remove All Test Files

```bash
ssh danielborrowman@192.168.222.60 << 'EOF'
sudo rm -rf /mnt/tesla-cam/TeslaSentry/*
sudo rm -rf /mnt/tesla-cam/TeslaCam/*
sudo rm -rf /mnt/tesla-cam/TeslaTrackMode/*
echo "✅ Test files cleaned"
EOF
```

### Remove from Cloudflare Stream

```bash
# Use Cloudflare dashboard or API to delete test videos
# Dashboard: https://dash.cloudflare.com/stream
```

### Clean Database

```bash
cd workers
npx wrangler d1 execute tesla-cam-db --command="DELETE FROM events WHERE stream_id LIKE 'test%'"
```

## 🎯 Development Workflow

### 1. Setup Dev Environment

```bash
# Make sure service is running
ssh danielborrowman@192.168.222.60 'sudo systemctl status tesla-cam-ai'

# Create storage directories
ssh danielborrowman@192.168.222.60 'sudo mkdir -p /mnt/tesla-cam/{TeslaSentry,TeslaCam,TeslaTrackMode}'
```

### 2. Generate Test Data

```bash
# Run the helper script
./scripts/start-dev-mode.sh

# Or SSH and run manually
ssh danielborrowman@192.168.222.60
cd /opt/tesla-cam-ai
source venv/bin/activate
python rpi5/dev_mode.py --mode test-suite
```

### 3. Watch Processing

```bash
# Terminal 1: Watch logs
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log'

# Terminal 2: Watch Workers
cd workers && npx wrangler tail

# Terminal 3: Watch file system
ssh danielborrowman@192.168.222.60 'watch -n 2 "ls -lh /mnt/tesla-cam/TeslaSentry/ | tail -5"'
```

### 4. Verify Results

```bash
# Check API
curl https://tesla-cam-ai.bruteforce.workers.dev/api/events

# Check Stream
open https://dash.cloudflare.com/0b0ee2b5eaf1fb8a2612e40ab6488052/stream

# Check database
cd workers
npx wrangler d1 execute tesla-cam-db --command="SELECT * FROM events LIMIT 10"
```

## 💡 Pro Tips

1. **Start with test-suite** to verify all components
2. **Use continuous mode** for real-time testing
3. **Stress test** before production use
4. **Monitor logs** to catch issues early
5. **Clean up** test data regularly

## 🐛 Troubleshooting

### Videos Not Being Detected

```bash
# Check file permissions
ssh danielborrowman@192.168.222.60 'ls -la /mnt/tesla-cam/TeslaSentry/'

# Check service is monitoring
ssh danielborrowman@192.168.222.60 'sudo journalctl -u tesla-cam-ai -f | grep "Scanning"'
```

### Videos Not Uploading

```bash
# Check network connectivity
ssh danielborrowman@192.168.222.60 'ping -c 3 api.cloudflare.com'

# Check config
ssh danielborrowman@192.168.222.60 'cat /etc/tesla-cam-ai/config.json | jq .cloudflare'

# Check logs for errors
ssh danielborrowman@192.168.222.60 'grep ERROR /var/log/tesla-cam-ai/main.log | tail -20'
```

### FFmpeg Not Found

```bash
# Install ffmpeg
ssh danielborrowman@192.168.222.60 'sudo apt install ffmpeg -y'
```

## 🎊 Ready to Test!

Run this command to start:

```bash
./scripts/start-dev-mode.sh
```

Or for quick test:

```bash
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode test-suite'
```

Then watch the magic happen! 📹🤖✨
