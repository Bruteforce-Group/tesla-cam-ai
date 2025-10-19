#!/usr/bin/env python3
"""
Tesla Camera AI Main Service
Monitors Tesla camera files and coordinates upload/processing
"""

import os
import sys
import time
import json
import logging
import asyncio
import hashlib
from pathlib import Path
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import aiofiles
import httpx
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/tesla-cam-ai/main.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class TeslaFile:
    """Represents a Tesla camera file with metadata"""
    
    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.filename = filepath.name
        self.parse_filename()
        
    def parse_filename(self):
        """Parse Tesla filename format: YYYY-MM-DD_HH-MM-SS-camera.mp4"""
        try:
            parts = self.filename.split('_')
            date_part = parts[0]
            time_camera = parts[1].split('-')
            
            self.date = date_part
            self.time = f"{time_camera[0]}:{time_camera[1]}:{time_camera[2]}"
            self.camera = time_camera[3].replace('.mp4', '')
            
            # Determine file type based on directory
            parent_dir = self.filepath.parent.name
            if 'Sentry' in str(self.filepath):
                self.event_type = 'sentry'
            elif 'Track' in str(self.filepath):
                self.event_type = 'track'
            else:
                self.event_type = 'dashcam'
                
            # Create timestamp
            self.timestamp = datetime.strptime(
                f"{self.date} {self.time}", 
                "%Y-%m-%d %H:%M:%S"
            )
            
        except Exception as e:
            logger.error(f"Error parsing filename {self.filename}: {e}")
            self.camera = 'unknown'
            self.event_type = 'unknown'
            self.timestamp = datetime.now()

class TeslaCamHandler(FileSystemEventHandler):
    """Handles file system events from Tesla camera directories"""
    
    def __init__(self, config: dict, upload_queue: asyncio.Queue):
        self.config = config
        self.upload_queue = upload_queue
        self.processed_files = set()
        self.load_processed_files()
        
    def load_processed_files(self):
        """Load list of already processed files"""
        try:
            db_file = Path('/var/lib/tesla-cam-ai/processed_files.json')
            if db_file.exists():
                with open(db_file, 'r') as f:
                    self.processed_files = set(json.load(f))
        except Exception as e:
            logger.error(f"Error loading processed files: {e}")
            
    def save_processed_files(self):
        """Save list of processed files"""
        try:
            db_file = Path('/var/lib/tesla-cam-ai/processed_files.json')
            db_file.parent.mkdir(parents=True, exist_ok=True)
            with open(db_file, 'w') as f:
                json.dump(list(self.processed_files), f)
        except Exception as e:
            logger.error(f"Error saving processed files: {e}")
    
    def on_created(self, event):
        """Handle new file creation"""
        if not event.is_directory and event.src_path.endswith('.mp4'):
            self.process_new_file(event.src_path)
            
    def on_modified(self, event):
        """Handle file modification"""
        if not event.is_directory and event.src_path.endswith('.mp4'):
            # Wait a bit to ensure file is fully written
            time.sleep(1)
            self.process_new_file(event.src_path)
    
    def process_new_file(self, filepath: str):
        """Process a new Tesla camera file"""
        try:
            path = Path(filepath)
            
            # Skip if already processed
            file_hash = self.get_file_hash(path)
            if file_hash in self.processed_files:
                return
                
            # Check if file is complete (not being written)
            if not self.is_file_complete(path):
                return
                
            # Parse Tesla file
            tesla_file = TeslaFile(path)
            
            # Add to upload queue (use put_nowait for sync context)
            try:
                self.upload_queue.put_nowait({
                    'tesla_file': tesla_file,
                    'file_hash': file_hash,
                    'queued_at': datetime.now()
                })
                
                # Mark as processed
                self.processed_files.add(file_hash)
                self.save_processed_files()
                
                logger.info(f"Queued file: {tesla_file.filename} ({tesla_file.event_type})")
            except Exception as e:
                logger.error(f"Error queuing file: {e}")
            
        except Exception as e:
            logger.error(f"Error processing file {filepath}: {e}")
    
    def get_file_hash(self, filepath: Path) -> str:
        """Calculate file hash for deduplication"""
        hasher = hashlib.md5()
        with open(filepath, 'rb') as f:
            hasher.update(f.read(65536))  # Read first 64KB
        return hasher.hexdigest()
    
    def is_file_complete(self, filepath: Path) -> bool:
        """Check if file is completely written"""
        try:
            initial_size = filepath.stat().st_size
            time.sleep(0.5)
            return filepath.stat().st_size == initial_size
        except:
            return False
            
    async def queue_file(self, tesla_file: TeslaFile, file_hash: str):
        """Add file to upload queue"""
        await self.upload_queue.put({
            'tesla_file': tesla_file,
            'file_hash': file_hash,
            'queued_at': datetime.now()
        })
        
        # Mark as processed
        self.processed_files.add(file_hash)
        self.save_processed_files()
        
        logger.info(f"Queued file: {tesla_file.filename} ({tesla_file.event_type})")

class CloudflareUploader:
    """Handles uploading files to Cloudflare Stream"""
    
    def __init__(self, config: dict):
        self.config = config
        self.client = httpx.AsyncClient(timeout=300.0)
        self.account_id = config['cloudflare']['account_id']
        self.api_token = config['cloudflare']['api_token']
        self.api_base = f"https://api.cloudflare.com/client/v4/accounts/{self.account_id}"
        
    async def upload_video(self, file_info: dict) -> Optional[str]:
        """Upload video to Cloudflare Stream"""
        tesla_file = file_info['tesla_file']
        
        try:
            # Create Stream upload URL
            create_response = await self.client.post(
                f"{self.api_base}/stream/direct_upload",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Content-Type": "application/json"
                },
                json={
                    "maxDurationSeconds": 3600,
                    "meta": {
                        "name": tesla_file.filename,
                        "camera": tesla_file.camera,
                        "event_type": tesla_file.event_type,
                        "timestamp": tesla_file.timestamp.isoformat(),
                        "file_hash": file_info['file_hash']
                    }
                }
            )
            
            if create_response.status_code != 200:
                logger.error(f"Failed to create upload URL: {create_response.text}")
                return None
                
            upload_data = create_response.json()
            upload_url = upload_data['result']['uploadURL']
            stream_id = upload_data['result']['uid']
            
            # Upload file
            async with aiofiles.open(tesla_file.filepath, 'rb') as f:
                file_data = await f.read()
                
            upload_response = await self.client.post(
                upload_url,
                files={'file': (tesla_file.filename, file_data, 'video/mp4')}
            )
            
            if upload_response.status_code != 200:
                logger.error(f"Failed to upload file: {upload_response.text}")
                return None
                
            logger.info(f"Successfully uploaded {tesla_file.filename} - Stream ID: {stream_id}")
            
            # Trigger AI analysis
            await self.trigger_ai_analysis(stream_id, tesla_file)
            
            return stream_id
            
        except Exception as e:
            logger.error(f"Upload error for {tesla_file.filename}: {e}")
            return None
    
    async def trigger_ai_analysis(self, stream_id: str, tesla_file: TeslaFile):
        """Trigger AI analysis via Worker"""
        try:
            await self.client.post(
                self.config['worker_api']['base_url'] + '/api/ai/analyze',
                headers={
                    "Authorization": f"Bearer {self.config['worker_api']['api_key']}",
                    "Content-Type": "application/json"
                },
                json={
                    "stream_id": stream_id,
                    "camera": tesla_file.camera,
                    "event_type": tesla_file.event_type,
                    "timestamp": tesla_file.timestamp.isoformat(),
                    "analysis_types": ["object_detection", "license_plate", "motion"]
                }
            )
            logger.info(f"Triggered AI analysis for {stream_id}")
        except Exception as e:
            logger.error(f"Failed to trigger AI analysis: {e}")

class TeslaCamAI:
    """Main application orchestrator"""
    
    def __init__(self):
        self.config = self.load_config()
        self.upload_queue = asyncio.Queue()
        self.uploader = CloudflareUploader(self.config)
        
    def load_config(self) -> dict:
        """Load configuration from file"""
        config_file = Path('/etc/tesla-cam-ai/config.json')
        if not config_file.exists():
            logger.error("Configuration file not found!")
            sys.exit(1)
            
        with open(config_file, 'r') as f:
            return json.load(f)
    
    async def process_upload_queue(self):
        """Process files in the upload queue"""
        while True:
            try:
                # Get file from queue
                file_info = await self.upload_queue.get()
                
                # Upload to Cloudflare
                stream_id = await self.uploader.upload_video(file_info)
                
                if stream_id:
                    # Clean up old files if configured
                    if self.config.get('auto_cleanup', {}).get('enabled', False):
                        await self.cleanup_old_file(file_info['tesla_file'])
                        
            except Exception as e:
                logger.error(f"Error processing upload queue: {e}")
                
            # Rate limit
            await asyncio.sleep(1)
    
    async def cleanup_old_file(self, tesla_file: TeslaFile):
        """Clean up old files to save space"""
        try:
            # Only cleanup dashcam files older than configured days
            if tesla_file.event_type == 'dashcam':
                age_days = (datetime.now() - tesla_file.timestamp).days
                max_age = self.config['auto_cleanup']['max_age_days']
                
                if age_days > max_age:
                    tesla_file.filepath.unlink()
                    logger.info(f"Deleted old file: {tesla_file.filename}")
        except Exception as e:
            logger.error(f"Error cleaning up file: {e}")
    
    def scan_existing_files(self):
        """Scan for existing files on startup"""
        logger.info("Scanning for existing files...")
        
        base_path = Path('/mnt/tesla-cam')
        patterns = ['TeslaCam/*.mp4', 'TeslaSentry/*/*.mp4', 'TeslaTrackMode/*.mp4']
        
        handler = TeslaCamHandler(self.config, self.upload_queue)
        
        for pattern in patterns:
            for filepath in base_path.glob(pattern):
                if filepath.is_file():
                    handler.process_new_file(str(filepath))
                    
        logger.info("Initial scan complete")
    
    async def monitor_storage_health(self):
        """Monitor storage health and capacity"""
        while True:
            try:
                # Check storage usage
                usage = os.statvfs('/mnt/tesla-cam')
                total = usage.f_blocks * usage.f_frsize
                free = usage.f_bavail * usage.f_frsize
                used_percent = ((total - free) / total) * 100 if total > 0 else 0
                
                if used_percent > 90:
                    logger.warning(f"Storage usage critical: {used_percent:.1f}%")
                elif used_percent > 80:
                    logger.warning(f"Storage usage high: {used_percent:.1f}%")
                    
                # Report to dashboard
                await self.report_status({
                    'storage_used_percent': used_percent,
                    'storage_free_gb': free / (1024**3),
                    'upload_queue_size': self.upload_queue.qsize()
                })
                
            except Exception as e:
                logger.error(f"Error monitoring storage: {e}")
                
            await asyncio.sleep(60)  # Check every minute
    
    async def report_status(self, status: dict):
        """Report status to Cloudflare Worker"""
        try:
            await self.uploader.client.post(
                self.config['worker_api']['base_url'] + '/api/device/status',
                headers={
                    "Authorization": f"Bearer {self.config['worker_api']['api_key']}",
                    "Content-Type": "application/json"
                },
                json={
                    "device_id": self.config['device']['id'],
                    "status": status,
                    "timestamp": datetime.now().isoformat()
                }
            )
        except Exception as e:
            logger.error(f"Failed to report status: {e}")
    
    def run(self):
        """Run the main application"""
        logger.info("Starting Tesla Cam AI Service...")
        
        # Set up file system monitoring
        event_handler = TeslaCamHandler(self.config, self.upload_queue)
        observer = Observer()
        observer.schedule(event_handler, '/mnt/tesla-cam', recursive=True)
        observer.start()
        
        # Scan existing files
        self.scan_existing_files()
        
        # Create async tasks
        loop = asyncio.get_event_loop()
        
        tasks = [
            loop.create_task(self.process_upload_queue()),
            loop.create_task(self.monitor_storage_health())
        ]
        
        try:
            logger.info("Tesla Cam AI Service is running")
            loop.run_until_complete(asyncio.gather(*tasks))
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            observer.stop()
        finally:
            observer.join()
            loop.close()

if __name__ == "__main__":
    app = TeslaCamAI()
    app.run()
