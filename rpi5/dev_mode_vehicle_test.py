#!/usr/bin/env python3
"""
Tesla Camera AI - Vehicle Detection Test Mode
Generates test scenarios specifically for vehicle detection:
- License plates
- Vehicle color
- Make and model
- Vehicle type
"""

import json
import random
from pathlib import Path
from datetime import datetime
from dev_mode import TeslaCameraSimulator

class VehicleTestGenerator(TeslaCameraSimulator):
    """Enhanced simulator for vehicle detection testing"""
    
    # Test vehicle database
    TEST_VEHICLES = [
        {
            'plate': 'ABC-123',
            'make': 'Tesla',
            'model': 'Model 3',
            'color': 'Red',
            'type': 'sedan',
            'year': 2024
        },
        {
            'plate': 'XYZ-789',
            'make': 'Tesla',
            'model': 'Model Y',
            'color': 'Blue',
            'type': 'suv',
            'year': 2023
        },
        {
            'plate': 'DEF-456',
            'make': 'BMW',
            'model': 'X5',
            'color': 'Black',
            'type': 'suv',
            'year': 2024
        },
        {
            'plate': 'GHI-789',
            'make': 'Mercedes',
            'model': 'C-Class',
            'color': 'White',
            'type': 'sedan',
            'year': 2023
        },
        {
            'plate': 'JKL-012',
            'make': 'Audi',
            'model': 'A4',
            'color': 'Silver',
            'type': 'sedan',
            'year': 2024
        },
        {
            'plate': 'MNO-345',
            'make': 'Ford',
            'model': 'F-150',
            'color': 'Gray',
            'type': 'truck',
            'year': 2023
        },
        {
            'plate': 'PQR-678',
            'make': 'Toyota',
            'model': 'Camry',
            'color': 'Blue',
            'type': 'sedan',
            'year': 2022
        },
        {
            'plate': 'STU-901',
            'make': 'Honda',
            'model': 'Civic',
            'color': 'Red',
            'type': 'sedan',
            'year': 2024
        },
    ]
    
    # Vehicle detection scenarios
    VEHICLE_SCENARIOS = {
        'single_vehicle_close': {
            'event_type': 'sentry',
            'cameras': ['front', 'left_repeater'],
            'duration': 30,
            'vehicles': 1,
            'distance': 'close',
            'description': 'Single vehicle close-up for plate detection'
        },
        'parking_detection': {
            'event_type': 'sentry',
            'cameras': ['front', 'back', 'left_repeater', 'right_repeater'],
            'duration': 60,
            'vehicles': 2,
            'distance': 'medium',
            'description': 'Multiple vehicles in parking scenario'
        },
        'traffic_scene': {
            'event_type': 'dashcam',
            'cameras': ['front', 'back'],
            'duration': 45,
            'vehicles': 3,
            'distance': 'various',
            'description': 'Traffic with multiple vehicles'
        },
        'plate_focus': {
            'event_type': 'sentry',
            'cameras': ['front'],
            'duration': 20,
            'vehicles': 1,
            'distance': 'very_close',
            'description': 'Focus on license plate for OCR testing'
        },
        'multi_vehicle_lot': {
            'event_type': 'sentry',
            'cameras': ['front', 'back', 'left_repeater', 'right_repeater'],
            'duration': 90,
            'vehicles': 5,
            'distance': 'various',
            'description': 'Parking lot with multiple vehicles'
        }
    }
    
    def generate_vehicle_event(self, scenario='single_vehicle_close', timestamp=None):
        """Generate event with vehicle metadata"""
        if timestamp is None:
            timestamp = datetime.now()
        
        scenario_config = self.VEHICLE_SCENARIOS.get(
            scenario,
            self.VEHICLE_SCENARIOS['single_vehicle_close']
        )
        
        # Select random vehicles for this scenario
        num_vehicles = scenario_config['vehicles']
        vehicles = random.sample(self.TEST_VEHICLES, min(num_vehicles, len(self.TEST_VEHICLES)))
        
        # Generate the event
        event_dir = super().generate_sentry_event(scenario, timestamp)
        
        # Create metadata file with vehicle info
        metadata = {
            'timestamp': timestamp.isoformat(),
            'scenario': scenario,
            'cameras': scenario_config['cameras'],
            'vehicles': vehicles,
            'distance': scenario_config['distance'],
            'expected_detections': {
                'plates': [v['plate'] for v in vehicles],
                'makes': [v['make'] for v in vehicles],
                'models': [v['model'] for v in vehicles],
                'colors': [v['color'] for v in vehicles],
                'types': [v['type'] for v in vehicles]
            }
        }
        
        # Save metadata
        metadata_path = event_dir / 'vehicle_metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"\n{'='*60}")
        print(f"Generated Vehicle Detection Test: {scenario}")
        print(f"{'='*60}")
        print(f"Location: {event_dir}")
        print(f"Cameras: {len(scenario_config['cameras'])}")
        print(f"Vehicles: {num_vehicles}")
        print(f"\nExpected Detections:")
        for i, vehicle in enumerate(vehicles, 1):
            print(f"  Vehicle {i}:")
            print(f"    Plate: {vehicle['plate']}")
            print(f"    Make/Model: {vehicle['make']} {vehicle['model']}")
            print(f"    Color: {vehicle['color']}")
            print(f"    Type: {vehicle['type']}")
            print(f"    Year: {vehicle['year']}")
        print(f"{'='*60}\n")
        
        return event_dir, metadata
    
    def generate_plate_test_suite(self):
        """Generate complete test suite for plate detection"""
        print("\n" + "="*60)
        print("VEHICLE DETECTION TEST SUITE")
        print("="*60)
        print("Generating all vehicle scenarios...")
        print()
        
        results = []
        for idx, (scenario_name, scenario) in enumerate(self.VEHICLE_SCENARIOS.items()):
            print(f"[{idx+1}/{len(self.VEHICLE_SCENARIOS)}] {scenario_name}...")
            event_dir, metadata = self.generate_vehicle_event(scenario_name)
            results.append({
                'scenario': scenario_name,
                'dir': str(event_dir),
                'metadata': metadata
            })
            print(f"  ✓ Generated {len(metadata['vehicles'])} vehicles")
            print()
        
        # Create summary file
        summary_path = Path('/opt/tesla-cam-ai/vehicle_test_summary.json')
        with open(summary_path, 'w') as f:
            json.dump(results, f, indent=2)
        
        print("="*60)
        print(f"✅ Test Suite Complete!")
        print(f"   Total scenarios: {len(results)}")
        print(f"   Summary saved: {summary_path}")
        print("="*60)
        print()
        print("Expected AI Detections:")
        total_plates = sum(len(r['metadata']['expected_detections']['plates']) for r in results)
        print(f"  • License Plates: {total_plates}")
        print(f"  • Vehicle Makes: {len(set(v['make'] for r in results for v in r['metadata']['vehicles']))}")
        print(f"  • Vehicle Colors: {len(set(v['color'] for r in results for v in r['metadata']['vehicles']))}")
        print()
        
        return results
    
    def generate_specific_plate_test(self, plate_number, make, model, color):
        """Generate test for a specific vehicle"""
        vehicle = {
            'plate': plate_number,
            'make': make,
            'model': model,
            'color': color,
            'type': 'sedan',
            'year': 2024
        }
        
        timestamp = datetime.now()
        event_dir = super().generate_sentry_event('plate_focus', timestamp)
        
        metadata = {
            'timestamp': timestamp.isoformat(),
            'scenario': 'custom_vehicle_test',
            'vehicle': vehicle
        }
        
        metadata_path = event_dir / 'vehicle_metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"\nCustom Vehicle Test Generated:")
        print(f"  Plate: {plate_number}")
        print(f"  Vehicle: {color} {make} {model}")
        print(f"  Location: {event_dir}\n")
        
        return event_dir

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Tesla Camera AI - Vehicle Detection Test Mode'
    )
    
    parser.add_argument(
        '--mode',
        choices=['single', 'suite', 'custom'],
        default='single',
        help='Test mode'
    )
    
    parser.add_argument(
        '--scenario',
        choices=list(VehicleTestGenerator.VEHICLE_SCENARIOS.keys()),
        default='single_vehicle_close',
        help='Vehicle scenario to generate'
    )
    
    parser.add_argument(
        '--plate',
        type=str,
        help='Custom plate number (for custom mode)'
    )
    
    parser.add_argument(
        '--make',
        type=str,
        help='Custom vehicle make (for custom mode)'
    )
    
    parser.add_argument(
        '--model',
        type=str,
        help='Custom vehicle model (for custom mode)'
    )
    
    parser.add_argument(
        '--color',
        type=str,
        help='Custom vehicle color (for custom mode)'
    )
    
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all vehicle scenarios'
    )
    
    args = parser.parse_args()
    
    generator = VehicleTestGenerator()
    
    if args.list:
        print("\nAvailable Vehicle Detection Scenarios:")
        print("=" * 60)
        for name, config in generator.VEHICLE_SCENARIOS.items():
            print(f"\n{name}:")
            print(f"  Type: {config['event_type']}")
            print(f"  Cameras: {', '.join(config['cameras'])}")
            print(f"  Duration: {config['duration']}s")
            print(f"  Vehicles: {config['vehicles']}")
            print(f"  Distance: {config['distance']}")
            print(f"  Description: {config['description']}")
        print("\n" + "=" * 60)
        return
    
    if args.mode == 'single':
        generator.generate_vehicle_event(args.scenario)
        
    elif args.mode == 'suite':
        generator.generate_plate_test_suite()
        
    elif args.mode == 'custom':
        if not all([args.plate, args.make, args.model, args.color]):
            print("Error: Custom mode requires --plate, --make, --model, and --color")
            return
        generator.generate_specific_plate_test(
            args.plate, args.make, args.model, args.color
        )

if __name__ == "__main__":
    main()

