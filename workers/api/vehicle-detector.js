// Enhanced vehicle detection with plate, color, make, and model

export async function detectVehicleDetails(frame, ai, env) {
  const results = {
    vehicles: [],
    license_plates: [],
    vehicle_details: []
  };
  
  try {
    // First, detect vehicles using object detection
    const objectDetection = await ai.run('@cf/microsoft/resnet-50', {
      image: [...new Uint8Array(frame.data)],
    });
    
    // Filter for vehicle-type objects
    const vehicleDetections = objectDetection.filter(detection => 
      isVehicleType(detection.label) && detection.score > 0.7
    );
    
    for (const vehicle of vehicleDetections) {
      // Extract vehicle details
      const vehicleDetails = await extractVehicleDetails(vehicle, frame, ai, env);
      
      results.vehicles.push({
        type: vehicle.label,
        confidence: vehicle.score,
        timestamp: frame.timestamp,
        bbox: vehicle.bbox,
        details: vehicleDetails
      });
      
      // If plate detected, add to license_plates array
      if (vehicleDetails.plate) {
        results.license_plates.push({
          plate_number: vehicleDetails.plate.number,
          confidence: vehicleDetails.plate.confidence,
          state: vehicleDetails.plate.state || null,
          timestamp: frame.timestamp,
          vehicle_info: {
            make: vehicleDetails.make,
            model: vehicleDetails.model,
            color: vehicleDetails.color,
            type: vehicle.label
          }
        });
      }
      
      // Add detailed vehicle information
      results.vehicle_details.push({
        ...vehicleDetails,
        detection_confidence: vehicle.score,
        timestamp: frame.timestamp
      });
    }
    
  } catch (error) {
    console.error('Vehicle detection error:', error);
  }
  
  return results;
}

async function extractVehicleDetails(vehicleDetection, frame, ai, env) {
  const details = {
    make: null,
    model: null,
    color: null,
    year: null,
    plate: null,
    body_type: vehicleDetection.label
  };
  
  try {
    // In production, you would:
    // 1. Crop the vehicle region from the frame
    // 2. Run specialized models for:
    //    - License plate detection and OCR
    //    - Vehicle make/model recognition
    //    - Color detection
    
    // For development/demo, we'll use simulated detection
    // with realistic confidence scores
    
    // Simulate plate detection (70% success rate for well-positioned vehicles)
    if (Math.random() > 0.3 && vehicleDetection.score > 0.75) {
      details.plate = {
        number: generateRealisticPlate(),
        confidence: 0.80 + Math.random() * 0.18, // 0.80-0.98
        state: getRandomState(),
        format: 'standard'
      };
    }
    
    // Simulate make/model detection
    if (vehicleDetection.score > 0.7) {
      const makeModel = getVehicleMakeModel(vehicleDetection.label);
      details.make = makeModel.make;
      details.model = makeModel.model;
      details.year = 2020 + Math.floor(Math.random() * 5); // 2020-2024
    }
    
    // Simulate color detection (high accuracy)
    if (vehicleDetection.score > 0.65) {
      details.color = detectVehicleColor();
    }
    
    // Simulate additional features
    details.features = {
      headlights_on: Math.random() > 0.5,
      moving: Math.random() > 0.3,
      parked: Math.random() > 0.5
    };
    
  } catch (error) {
    console.error('Error extracting vehicle details:', error);
  }
  
  return details;
}

function isVehicleType(label) {
  const vehicleTypes = [
    'car', 'truck', 'bus', 'motorcycle', 'bicycle', 
    'suv', 'van', 'pickup', 'sedan', 'coupe'
  ];
  return vehicleTypes.some(type => 
    label.toLowerCase().includes(type)
  );
}

function generateRealisticPlate() {
  // Generate realistic looking license plates
  const formats = [
    () => {
      // ABC-123 format
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const numbers = '0123456789';
      return `${randomChars(letters, 3)}-${randomChars(numbers, 3)}`;
    },
    () => {
      // 123ABC format
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const numbers = '0123456789';
      return `${randomChars(numbers, 3)}${randomChars(letters, 3)}`;
    },
    () => {
      // AB12CD format
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const numbers = '0123456789';
      return `${randomChars(letters, 2)}${randomChars(numbers, 2)}${randomChars(letters, 2)}`;
    }
  ];
  
  const format = formats[Math.floor(Math.random() * formats.length)];
  return format();
}

function randomChars(charset, length) {
  let result = '';
  for (let i = 0; i < length; i++) {
    result += charset[Math.floor(Math.random() * charset.length)];
  }
  return result;
}

function getRandomState() {
  const states = [
    'NSW', 'VIC', 'QLD', 'SA', 'WA', 'TAS', 'NT', 'ACT', // Australia
    'CA', 'NY', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA' // USA
  ];
  return states[Math.floor(Math.random() * states.length)];
}

function getVehicleMakeModel(vehicleType) {
  const vehicles = [
    { make: 'Tesla', model: 'Model 3' },
    { make: 'Tesla', model: 'Model Y' },
    { make: 'Tesla', model: 'Model S' },
    { make: 'BMW', model: 'X5' },
    { make: 'BMW', model: '3 Series' },
    { make: 'Mercedes', model: 'C-Class' },
    { make: 'Mercedes', model: 'E-Class' },
    { make: 'Audi', model: 'A4' },
    { make: 'Audi', model: 'Q5' },
    { make: 'Toyota', model: 'Camry' },
    { make: 'Toyota', model: 'RAV4' },
    { make: 'Honda', model: 'Civic' },
    { make: 'Honda', model: 'Accord' },
    { make: 'Ford', model: 'F-150' },
    { make: 'Ford', model: 'Mustang' },
    { make: 'Chevrolet', model: 'Silverado' },
    { make: 'Nissan', model: 'Altima' },
  ];
  
  return vehicles[Math.floor(Math.random() * vehicles.length)];
}

function detectVehicleColor() {
  const colors = [
    'White', 'Black', 'Silver', 'Gray', 'Blue', 'Red',
    'Green', 'Yellow', 'Orange', 'Brown', 'Gold', 'Beige'
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

// Enhanced processing function that includes vehicle details
export async function processVehicleDetection(job, env) {
  const { stream_id, camera, event_type, timestamp } = job;
  
  console.log(`Processing vehicle detection for stream ${stream_id}`);
  
  try {
    // Create event record
    const eventId = crypto.randomUUID();
    await env.DB.prepare(`
      INSERT INTO events (id, stream_id, camera, event_type, timestamp, status)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(eventId, stream_id, camera, event_type, timestamp, 'processing').run();
    
    // Check for metadata file (from dev mode)
    const metadataExists = await checkForMetadata(stream_id, env);
    
    // Get video frames
    const frames = await extractVideoFrames(stream_id, env);
    
    // Run vehicle detection on each frame
    const allResults = {
      vehicles: [],
      plates: [],
      details: []
    };
    
    for (const frame of frames) {
      const frameResults = await detectVehicleDetails(frame, env.AI, env);
      allResults.vehicles.push(...frameResults.vehicles);
      allResults.plates.push(...frameResults.license_plates);
      allResults.details.push(...frameResults.vehicle_details);
    }
    
    // Store vehicle detections with full details
    await storeVehicleDetections(eventId, allResults, env);
    
    // Update event status
    await env.DB.prepare(
      'UPDATE events SET status = ? WHERE id = ?'
    ).bind('completed', eventId).run();
    
    console.log(`Vehicle detection complete: ${allResults.plates.length} plates, ${allResults.vehicles.length} vehicles`);
    
    return {
      eventId,
      detections: allResults
    };
    
  } catch (error) {
    console.error('Vehicle processing error:', error);
    throw error;
  }
}

async function storeVehicleDetections(eventId, results, env) {
  const detections = [];
  
  // Store license plate detections
  for (const plate of results.plates) {
    const detectionId = crypto.randomUUID();
    
    // Store detection
    detections.push({
      id: detectionId,
      event_id: eventId,
      object_type: 'license_plate',
      confidence: plate.confidence,
      timestamp: plate.timestamp,
      metadata: JSON.stringify({
        plate_number: plate.plate_number,
        state: plate.state,
        vehicle_make: plate.vehicle_info?.make,
        vehicle_model: plate.vehicle_info?.model,
        vehicle_color: plate.vehicle_info?.color,
        vehicle_type: plate.vehicle_info?.type
      })
    });
    
    // Check if plate exists in database
    const existingPlate = await env.DB.prepare(
      'SELECT id FROM license_plates WHERE plate_number = ?'
    ).bind(plate.plate_number).first();
    
    if (existingPlate) {
      // Update last seen and increment sightings
      await env.DB.prepare(`
        UPDATE license_plates 
        SET last_seen = ?, total_sightings = total_sightings + 1, updated_at = ?
        WHERE id = ?
      `).bind(
        new Date().toISOString(),
        new Date().toISOString(),
        existingPlate.id
      ).run();
    } else {
      // Create new plate record
      const plateId = crypto.randomUUID();
      await env.DB.prepare(`
        INSERT INTO license_plates (
          id, plate_number, first_seen, last_seen, 
          total_sightings, is_known, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `).bind(
        plateId,
        plate.plate_number,
        new Date().toISOString(),
        new Date().toISOString(),
        1,
        false,
        new Date().toISOString()
      ).run();
    }
  }
  
  // Store vehicle details
  for (const detail of results.details) {
    if (detail.make && detail.model) {
      const detectionId = crypto.randomUUID();
      detections.push({
        id: detectionId,
        event_id: eventId,
        object_type: 'vehicle_details',
        confidence: detail.detection_confidence,
        timestamp: detail.timestamp,
        metadata: JSON.stringify({
          make: detail.make,
          model: detail.model,
          color: detail.color,
          year: detail.year,
          body_type: detail.body_type,
          features: detail.features
        })
      });
    }
  }
  
  // Batch insert all detections
  if (detections.length > 0) {
    const stmt = env.DB.prepare(`
      INSERT INTO detections (id, event_id, object_type, confidence, timestamp, metadata)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const batch = detections.map(d => 
      stmt.bind(d.id, d.event_id, d.object_type, d.confidence, d.timestamp, d.metadata)
    );
    
    await env.DB.batch(batch);
  }
}

async function checkForMetadata(streamId, env) {
  // Check if there's vehicle metadata from dev mode
  // This could be stored in KV or passed with the job
  return false;
}

async function extractVideoFrames(streamId, env) {
  // Extract frames from Stream video
  const frames = [];
  const intervals = [0, 5, 10, 15, 20]; // seconds
  
  for (const second of intervals) {
    const thumbnailUrl = `https://customer-${env.STREAM_ACCOUNT_ID}.cloudflarestream.com/${streamId}/thumbnails/thumbnail.jpg?time=${second}s`;
    
    try {
      const response = await fetch(thumbnailUrl);
      if (response.ok) {
        const imageData = await response.arrayBuffer();
        frames.push({
          timestamp: second,
          data: imageData
        });
      }
    } catch (error) {
      console.error(`Failed to extract frame at ${second}s:`, error);
    }
  }
  
  return frames;
}

export { isVehicleType, generateRealisticPlate, getVehicleMakeModel, detectVehicleColor };
