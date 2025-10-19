#!/usr/bin/env python3
"""
Tesla Camera AI - Development Mode
Generates dummy camera feeds simulating Tesla Sentry/Dashcam footage
"""

import os
import sys
import time
import random
import logging
from pathlib import Path
from datetime import datetime, timedelta
import subprocess
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TeslaCameraSimulator:
    """Simulates Tesla camera feeds for development/testing"""
    
    # Tesla camera names
    CAMERAS = [
        'front',
        'back',
        'left_repeater',
        'right_repeater',
        'left_pillar',
        'right_pillar',
        'cabin',
        'narrow_front'  # For newer models
    ]
    
    # Event types
    EVENT_TYPES = {
        'sentry': '/mnt/tesla-cam/TeslaSentry',
        'dashcam': '/mnt/tesla-cam/TeslaCam',
        'track': '/mnt/tesla-cam/TeslaTrackMode'
    }
    
    # Scenarios for testing
    SCENARIOS = {
        'person_approaching': {
            'event_type': 'sentry',
            'cameras': ['front', 'left_repeater'],
            'duration': 60,
            'description': 'Person approaching vehicle'
        },
        'vehicle_passing': {
            'event_type': 'dashcam',
            'cameras': ['front', 'back'],
            'duration': 30,
            'description': 'Vehicle passing by'
        },
        'parking_lot': {
            'event_type': 'sentry',
            'cameras': ['front', 'back', 'left_repeater', 'right_repeater'],
            'duration': 120,
            'description': 'Parking lot surveillance'
        },
        'driving': {
            'event_type': 'dashcam',
            'cameras': ['front', 'left_pillar', 'right_pillar'],
            'duration': 60,
            'description': 'Normal driving'
        },
        'track_mode': {
            'event_type': 'track',
            'cameras': ['front', 'narrow_front', 'back'],
            'duration': 180,
            'description': 'Track mode racing'
        }
    }
    
    def __init__(self, config_path='/etc/tesla-cam-ai/config.json'):
        self.config = self.load_config(config_path)
        self.base_path = Path('/mnt/tesla-cam')
        self.ensure_directories()
        
    def load_config(self, config_path):
        """Load configuration"""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.warning(f"Could not load config: {e}")
            return {'debug': {'log_level': 'INFO'}}
    
    def ensure_directories(self):
        """Create Tesla directory structure"""
        for event_type, path in self.EVENT_TYPES.items():
            Path(path).mkdir(parents=True, exist_ok=True)
            logger.info(f"Ensured directory exists: {path}")
            
            # Create event-specific subdirectories for Sentry mode
            if event_type == 'sentry':
                for i in range(1, 4):
                    event_dir = Path(path) / f"2025-10-19_{10+i}-00-00"
                    event_dir.mkdir(exist_ok=True)
    
    def generate_filename(self, camera, timestamp=None):
        """Generate Tesla-style filename"""
        if timestamp is None:
            timestamp = datetime.now()
        
        # Format: YYYY-MM-DD_HH-MM-SS-camera.mp4
        return f"{timestamp.strftime('%Y-%m-%d_%H-%M-%S')}-{camera}.mp4"
    
    def create_dummy_video(self, output_path, duration=10, scenario='default'):
        """Create a dummy video file with test pattern"""
        try:
            # Create simple test video using ffmpeg
            camera_name = Path(output_path).stem.split('-')[-1]
            
            # Simple command without complex filters
            cmd = [
                'ffmpeg',
                '-f', 'lavfi',
                '-i', f'testsrc=duration={duration}:size=1920x1080:rate=30',
                '-f', 'lavfi',
                '-i', f'sine=frequency=1000:duration={duration}',
                '-c:v', 'libx264',
                '-preset', 'ultrafast',
                '-pix_fmt', 'yuv420p',
                '-c:a', 'aac',
                '-b:a', '128k',
                '-y',
                str(output_path)
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=duration + 30
            )
            
            if result.returncode == 0:
                file_size = Path(output_path).stat().st_size / (1024 * 1024)
                logger.info(f"Created {output_path.name} ({file_size:.2f} MB, {duration}s)")
                return True
            else:
                logger.error(f"ffmpeg error: {result.stderr[:500]}")
                return False
                
        except FileNotFoundError:
            logger.warning("ffmpeg not installed, creating placeholder file")
            # Create a placeholder file instead
            placeholder_size = max(duration * 1024 * 100, 1024 * 100)  # ~100KB per second minimum
            with open(output_path, 'wb') as f:
                f.write(b'0' * placeholder_size)
            logger.info(f"Created placeholder: {output_path.name} ({placeholder_size / 1024:.2f} KB)")
            return True
        except Exception as e:
            logger.error(f"Error creating video: {e}")
            return False
    
    def generate_sentry_event(self, scenario='person_approaching', timestamp=None):
        """Generate a complete Sentry event with multiple cameras"""
        if timestamp is None:
            timestamp = datetime.now()
        
        scenario_config = self.SCENARIOS.get(scenario, self.SCENARIOS['person_approaching'])
        event_type = scenario_config['event_type']
        cameras = scenario_config['cameras']
        duration = scenario_config['duration']
        
        # Create event directory for Sentry mode
        if event_type == 'sentry':
            event_dir = (
                Path(self.EVENT_TYPES[event_type]) / 
                timestamp.strftime('%Y-%m-%d_%H-%M-%S')
            )
            event_dir.mkdir(parents=True, exist_ok=True)
        else:
            event_dir = Path(self.EVENT_TYPES[event_type])
        
        logger.info(f"Generating {scenario} event with {len(cameras)} cameras")
        
        # Generate video for each camera
        for camera in cameras:
            filename = self.generate_filename(camera, timestamp)
            output_path = event_dir / filename
            
            self.create_dummy_video(output_path, duration, scenario)
            
        logger.info(f"Generated {len(cameras)} camera feeds in {event_dir}")
        return event_dir
    
    def continuous_feed(self, interval=60, scenarios=None):
        """Continuously generate events at intervals"""
        if scenarios is None:
            scenarios = list(self.SCENARIOS.keys())
        
        logger.info(f"Starting continuous feed (interval: {interval}s)")
        logger.info(f"Scenarios: {', '.join(scenarios)}")
        
        try:
            iteration = 0
            while True:
                iteration += 1
                scenario = random.choice(scenarios)
                
                logger.info(f"[Iteration {iteration}] Generating {scenario} event")
                
                # Vary timestamp slightly
                timestamp = datetime.now() - timedelta(seconds=random.randint(0, 300))
                
                self.generate_sentry_event(scenario, timestamp)
                
                logger.info(f"Waiting {interval} seconds before next event...")
                time.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Stopped continuous feed generation")
    
    def generate_test_suite(self):
        """Generate a complete test suite with all scenarios"""
        logger.info("Generating complete test suite...")
        
        base_time = datetime.now() - timedelta(hours=2)
        
        for idx, (scenario_name, scenario) in enumerate(self.SCENARIOS.items()):
            timestamp = base_time + timedelta(minutes=idx * 15)
            logger.info(f"Generating scenario {idx+1}/{len(self.SCENARIOS)}: {scenario_name}")
            self.generate_sentry_event(scenario_name, timestamp)
            
        logger.info("Test suite generation complete!")
        logger.info(f"Generated {len(self.SCENARIOS)} scenarios")
    
    def generate_stress_test(self, num_events=10, concurrent_cameras=4):
        """Generate multiple events for stress testing"""
        logger.info(f"Generating {num_events} events for stress testing...")
        
        for i in range(num_events):
            cameras = random.sample(self.CAMERAS, concurrent_cameras)
            timestamp = datetime.now() - timedelta(minutes=random.randint(0, 120))
            
            scenario = random.choice(list(self.SCENARIOS.keys()))
            
            # Temporarily override cameras for variety
            original_cameras = self.SCENARIOS[scenario]['cameras']
            self.SCENARIOS[scenario]['cameras'] = cameras
            
            self.generate_sentry_event(scenario, timestamp)
            
            # Restore original
            self.SCENARIOS[scenario]['cameras'] = original_cameras
            
            logger.info(f"Generated stress test event {i+1}/{num_events}")
            time.sleep(1)  # Small delay to avoid overwhelming
        
        logger.info("Stress test generation complete!")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Tesla Camera AI - Development Mode Feed Generator'
    )
    
    parser.add_argument(
        '--mode',
        choices=['single', 'continuous', 'test-suite', 'stress'],
        default='single',
        help='Generation mode'
    )
    
    parser.add_argument(
        '--scenario',
        choices=list(TeslaCameraSimulator.SCENARIOS.keys()),
        default='person_approaching',
        help='Scenario to generate'
    )
    
    parser.add_argument(
        '--interval',
        type=int,
        default=60,
        help='Interval between events in continuous mode (seconds)'
    )
    
    parser.add_argument(
        '--count',
        type=int,
        default=10,
        help='Number of events for stress test'
    )
    
    parser.add_argument(
        '--list-scenarios',
        action='store_true',
        help='List all available scenarios'
    )
    
    args = parser.parse_args()
    
    simulator = TeslaCameraSimulator()
    
    if args.list_scenarios:
        print("\nAvailable Scenarios:")
        print("=" * 60)
        for name, config in simulator.SCENARIOS.items():
            print(f"\n{name}:")
            print(f"  Type: {config['event_type']}")
            print(f"  Cameras: {', '.join(config['cameras'])}")
            print(f"  Duration: {config['duration']}s")
            print(f"  Description: {config['description']}")
        print("\n" + "=" * 60)
        return
    
    logger.info("Tesla Camera AI - Development Mode")
    logger.info(f"Mode: {args.mode}")
    
    if args.mode == 'single':
        simulator.generate_sentry_event(args.scenario)
        
    elif args.mode == 'continuous':
        simulator.continuous_feed(args.interval)
        
    elif args.mode == 'test-suite':
        simulator.generate_test_suite()
        
    elif args.mode == 'stress':
        simulator.generate_stress_test(args.count)
    
    logger.info("Development mode complete")

if __name__ == "__main__":
    main()

