# Tesla Camera AI Streaming System

A complete solution for capturing Tesla camera footage via Raspberry Pi 5, streaming to Cloudflare, and running AI-based object detection in real-time.

## System Overview

This system transforms your Tesla's camera recordings into an intelligent surveillance platform with:
- Local storage on RPi5 (appears as USB drive to Tesla)
- Automatic streaming to Cloudflare
- AI object detection (people, vehicles, license plates)
- Real-time alerts and notifications
- Web dashboard for viewing and analysis

## Architecture

```
Tesla Model 3 → RPi5 (USB Storage) → Cloudflare Stream → Workers AI → Dashboard
                 ↓                      ↓                   ↓
            Local Storage          R2 Archive        Object Detection
```

## Features

- ✅ Plug-and-play Tesla USB storage emulation
- ✅ Automatic video file detection and upload
- ✅ Real-time streaming to Cloudflare
- ✅ AI object detection (vehicles, people, events)
- ✅ License plate recognition
- ✅ Motion detection and alerts
- ✅ Web dashboard with live view
- ✅ Mobile app support
- ✅ Long-term archival in R2
- ✅ Event search and playback

## Quick Start

### Prerequisites
- Raspberry Pi 5 (8GB recommended)
- 1TB+ SSD/NVMe storage
- Cloudflare account with Stream enabled
- USB-C cable for Tesla connection

### Installation

1. **Flash RPi5 OS**
   ```bash
   # Use Raspberry Pi Imager with 64-bit OS
   ```

2. **Install Tesla Cam AI**
   ```bash
   curl -sSL https://get.tesla-cam-ai.com | bash
   ```

3. **Configure**
   ```bash
   sudo tesla-cam-ai configure
   # Enter your Cloudflare credentials
   ```

4. **Connect to Tesla**
   - Plug RPi5 into Tesla USB port
   - Format drive when prompted in Tesla

## Components

- **RPi5 Software**: USB gadget mode, file monitoring, upload agent
- **Cloudflare Workers**: API, video processing, AI integration
- **Stream**: Video hosting and transcoding
- **Workers AI**: Object detection and analysis
- **R2**: Long-term storage
- **D1**: Metadata and events database
- **Pages**: Web dashboard

## Documentation

- [Installation Guide](./docs/INSTALLATION.md)
- [Configuration](./docs/CONFIGURATION.md)
- [API Reference](./docs/API.md)
- [Troubleshooting](./docs/TROUBLESHOOTING.md)
