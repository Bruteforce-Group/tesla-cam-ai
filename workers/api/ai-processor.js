export async function processAIAnalysis(job, env) {
  const ai = env.AI;
  const { stream_id, camera, event_type, timestamp, analysis_types } = job;
  
  console.log(`Processing AI analysis for stream ${stream_id}`);
  
  try {
    // Create event record
    const eventId = crypto.randomUUID();
    await env.DB.prepare(`
      INSERT INTO events (id, stream_id, camera, event_type, timestamp, status)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(eventId, stream_id, camera, event_type, timestamp, 'processing').run();
    
    // Get video frames for analysis
    const frames = await extractVideoFrames(stream_id, env);
    
    // Run different types of analysis
    const results = {
      objects: [],
      license_plates: [],
      motion_events: [],
      anomalies: []
    };
    
    for (const frame of frames) {
      // Object detection
      if (analysis_types.includes('object_detection')) {
        const objects = await detectObjects(frame, ai, env);
        results.objects.push(...objects);
      }
      
      // License plate recognition
      if (analysis_types.includes('license_plate')) {
        const plates = await detectLicensePlates(frame, ai, env);
        results.license_plates.push(...plates);
      }
      
      // Motion detection
      if (analysis_types.includes('motion')) {
        const motion = await detectMotion(frame, frames, ai);
        if (motion) results.motion_events.push(motion);
      }
    }
    
    // Process and store results
    await processResults(eventId, results, env);
    
    // Update event status
    await env.DB.prepare(
      'UPDATE events SET status = ? WHERE id = ?'
    ).bind('completed', eventId).run();
    
    // Send real-time update
    const eventProcessor = env.EVENT_PROCESSOR.get(
      env.EVENT_PROCESSOR.idFromName(eventId)
    );
    await eventProcessor.fetch(new Request('http://internal/complete', {
      method: 'POST',
      body: JSON.stringify({ results })
    }));
    
    // Check for alerts
    await checkForAlerts(eventId, results, env);
    
  } catch (error) {
    console.error('AI processing error:', error);
    
    // Update status to failed
    await env.DB.prepare(
      'UPDATE events SET status = ?, error = ? WHERE stream_id = ?'
    ).bind('failed', error.message, stream_id).run();
  }
}

async function extractVideoFrames(streamId, env) {
  // Get video URL from Stream
  const streamUrl = `https://customer-${env.STREAM_ACCOUNT_ID}.cloudflarestream.com/${streamId}/manifest/video.m3u8`;
  
  // For now, we'll extract frames at specific intervals
  // In production, you'd use a proper video processing service
  const frames = [];
  const intervals = [0, 5, 10, 15, 20]; // seconds
  
  for (const second of intervals) {
    const thumbnailUrl = `https://customer-${env.STREAM_ACCOUNT_ID}.cloudflarestream.com/${streamId}/thumbnails/thumbnail.jpg?time=${second}s`;
    
    const response = await fetch(thumbnailUrl);
    if (response.ok) {
      const imageData = await response.arrayBuffer();
      frames.push({
        timestamp: second,
        data: imageData
      });
    }
  }
  
  return frames;
}

async function detectObjects(frame, ai, env) {
  const objects = [];
  
  try {
    // Use Workers AI for object detection
    const response = await ai.run('@cf/microsoft/resnet-50', {
      image: [...new Uint8Array(frame.data)],
    });
    
    // Process detections
    for (const detection of response) {
      if (detection.score > 0.7) { // Confidence threshold
        objects.push({
          type: detection.label,
          confidence: detection.score,
          timestamp: frame.timestamp,
          bbox: detection.bbox || null
        });
      }
    }
    
    // Additional vehicle-specific detection
    if (objects.some(obj => ['car', 'truck', 'bus'].includes(obj.type.toLowerCase()))) {
      // Run vehicle-specific model for better classification
      const vehicleResponse = await ai.run('@cf/microsoft/resnet-50', {
        image: [...new Uint8Array(frame.data)],
      });
      
      // Merge results
      for (const detection of vehicleResponse) {
        if (detection.score > 0.8 && isVehicleType(detection.label)) {
          objects.push({
            type: `vehicle:${detection.label}`,
            confidence: detection.score,
            timestamp: frame.timestamp,
            bbox: detection.bbox || null
          });
        }
      }
    }
  } catch (error) {
    console.error('Object detection error:', error);
  }
  
  return objects;
}

async function detectLicensePlates(frame, ai, env) {
  const plates = [];
  
  try {
    // First detect vehicles
    const vehicleDetections = await ai.run('@cf/microsoft/resnet-50', {
      image: [...new Uint8Array(frame.data)],
    });
    
    // For each vehicle, try to extract license plate
    for (const vehicle of vehicleDetections) {
      if (isVehicleType(vehicle.label) && vehicle.score > 0.7) {
        // In a real implementation, you would:
        // 1. Crop the vehicle region
        // 2. Run plate detection
        // 3. Run OCR on the plate
        
        // For now, we'll simulate with a placeholder
        if (Math.random() > 0.7) { // Simulate 30% detection rate
          plates.push({
            plate_number: generateMockPlate(),
            confidence: 0.85 + Math.random() * 0.15,
            timestamp: frame.timestamp,
            vehicle_type: vehicle.label
          });
        }
      }
    }
  } catch (error) {
    console.error('License plate detection error:', error);
  }
  
  return plates;
}

async function detectMotion(currentFrame, allFrames, ai) {
  // Simple motion detection by comparing frames
  // In production, use more sophisticated algorithms
  
  const currentIndex = allFrames.findIndex(f => f.timestamp === currentFrame.timestamp);
  if (currentIndex === 0) return null;
  
  const previousFrame = allFrames[currentIndex - 1];
  
  // Compare frames (simplified)
  // In reality, you'd use optical flow or similar techniques
  const motionScore = Math.random(); // Placeholder
  
  if (motionScore > 0.3) {
    return {
      timestamp: currentFrame.timestamp,
      motion_score: motionScore,
      type: motionScore > 0.7 ? 'significant' : 'minor'
    };
  }
  
  return null;
}

async function processResults(eventId, results, env) {
  // Store detections
  const detections = [];
  
  // Process objects
  for (const obj of results.objects) {
    const detectionId = crypto.randomUUID();
    detections.push({
      id: detectionId,
      event_id: eventId,
      object_type: obj.type,
      confidence: obj.confidence,
      timestamp: obj.timestamp,
      bbox: JSON.stringify(obj.bbox)
    });
  }
  
  // Process license plates
  for (const plate of results.license_plates) {
    const detectionId = crypto.randomUUID();
    detections.push({
      id: detectionId,
      event_id: eventId,
      object_type: 'license_plate',
      confidence: plate.confidence,
      timestamp: plate.timestamp,
      metadata: JSON.stringify({
        plate_number: plate.plate_number,
        vehicle_type: plate.vehicle_type
      })
    });
  }
  
  // Batch insert detections
  if (detections.length > 0) {
    const stmt = env.DB.prepare(`
      INSERT INTO detections (id, event_id, object_type, confidence, timestamp, bbox, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    
    const batch = detections.map(d => 
      stmt.bind(d.id, d.event_id, d.object_type, d.confidence, d.timestamp, d.bbox || null, d.metadata || null)
    );
    
    await env.DB.batch(batch);
  }
  
  // Store AI analysis summary
  await env.DB.prepare(`
    INSERT INTO ai_analysis (
      id, event_id, total_objects, total_people, total_vehicles, 
      license_plates_detected, motion_detected, analysis_timestamp
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    crypto.randomUUID(),
    eventId,
    results.objects.length,
    results.objects.filter(o => o.type === 'person').length,
    results.objects.filter(o => isVehicleType(o.type)).length,
    results.license_plates.length,
    results.motion_events.length > 0,
    new Date().toISOString()
  ).run();
}

async function checkForAlerts(eventId, results, env) {
  const alerts = [];
  
  // Check for person detection in Sentry mode
  const event = await env.DB.prepare(
    'SELECT event_type FROM events WHERE id = ?'
  ).bind(eventId).first();
  
  if (event.event_type === 'sentry') {
    const peopleDetected = results.objects.filter(o => o.type === 'person');
    if (peopleDetected.length > 0) {
      alerts.push({
        type: 'person_detected',
        severity: 'high',
        message: `${peopleDetected.length} person(s) detected near vehicle`,
        details: { count: peopleDetected.length }
      });
    }
  }
  
  // Check for unknown vehicles
  const unknownVehicles = results.objects.filter(o => 
    isVehicleType(o.type) && o.confidence > 0.8
  );
  if (unknownVehicles.length > 0) {
    alerts.push({
      type: 'vehicle_detected',
      severity: 'medium',
      message: `${unknownVehicles.length} vehicle(s) detected`,
      details: { count: unknownVehicles.length }
    });
  }
  
  // Check for motion in specific scenarios
  if (results.motion_events.some(m => m.type === 'significant')) {
    alerts.push({
      type: 'significant_motion',
      severity: 'medium',
      message: 'Significant motion detected',
      details: { motion_events: results.motion_events.length }
    });
  }
  
  // Store alerts
  for (const alert of alerts) {
    const alertId = crypto.randomUUID();
    await env.DB.prepare(`
      INSERT INTO alerts (id, event_id, type, severity, message, details, status)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(
      alertId,
      eventId,
      alert.type,
      alert.severity,
      alert.message,
      JSON.stringify(alert.details),
      'active'
    ).run();
    
    // Send to alert manager
    const alertManager = env.ALERT_MANAGER.get(
      env.ALERT_MANAGER.idFromName('global')
    );
    await alertManager.fetch(new Request('http://internal/alert', {
      method: 'POST',
      body: JSON.stringify({ alertId, ...alert, eventId })
    }));
  }
}

// Helper functions
function isVehicleType(label) {
  const vehicleTypes = ['car', 'truck', 'bus', 'motorcycle', 'bicycle', 'suv', 'van'];
  return vehicleTypes.includes(label.toLowerCase());
}

function generateMockPlate() {
  // Generate realistic looking plate for testing
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  return `${letters[Math.floor(Math.random() * 26)]}${letters[Math.floor(Math.random() * 26)]}${letters[Math.floor(Math.random() * 26)]}-${numbers[Math.floor(Math.random() * 10)]}${numbers[Math.floor(Math.random() * 10)]}${numbers[Math.floor(Math.random() * 10)]}`;
}
