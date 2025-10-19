-- Tesla Camera AI Database Schema

-- Events table (camera recordings)
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  stream_id TEXT UNIQUE NOT NULL,
  camera TEXT NOT NULL, -- front, back, left-repeater, right-repeater, etc.
  event_type TEXT NOT NULL, -- sentry, dashcam, track
  timestamp DATETIME NOT NULL,
  duration INTEGER, -- seconds
  file_hash TEXT,
  device_id TEXT,
  location_lat REAL,
  location_lng REAL,
  status TEXT DEFAULT 'pending', -- pending, processing, completed, failed
  error TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_camera ON events(camera);

-- Object detections table
CREATE TABLE IF NOT EXISTS detections (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  object_type TEXT NOT NULL, -- person, vehicle, animal, etc.
  confidence REAL NOT NULL,
  timestamp INTEGER, -- seconds into video
  bbox TEXT, -- JSON: {x, y, width, height}
  metadata TEXT, -- JSON: additional data like license plate
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE INDEX idx_detections_event ON detections(event_id);
CREATE INDEX idx_detections_type ON detections(object_type);
CREATE INDEX idx_detections_confidence ON detections(confidence);

-- AI analysis results
CREATE TABLE IF NOT EXISTS ai_analysis (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  total_objects INTEGER DEFAULT 0,
  total_people INTEGER DEFAULT 0,
  total_vehicles INTEGER DEFAULT 0,
  license_plates_detected INTEGER DEFAULT 0,
  motion_detected BOOLEAN DEFAULT FALSE,
  anomaly_score REAL DEFAULT 0,
  analysis_duration_ms INTEGER,
  analysis_timestamp DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE INDEX idx_ai_analysis_event ON ai_analysis(event_id);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  type TEXT NOT NULL, -- person_detected, vehicle_detected, motion, etc.
  severity TEXT NOT NULL, -- low, medium, high
  message TEXT NOT NULL,
  details TEXT, -- JSON
  status TEXT DEFAULT 'active', -- active, acknowledged, dismissed, auto_dismissed
  acknowledged_by TEXT,
  acknowledged_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE INDEX idx_alerts_event ON alerts(event_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_created ON alerts(created_at);

-- License plates table
CREATE TABLE IF NOT EXISTS license_plates (
  id TEXT PRIMARY KEY,
  plate_number TEXT NOT NULL,
  first_seen DATETIME NOT NULL,
  last_seen DATETIME NOT NULL,
  total_sightings INTEGER DEFAULT 1,
  is_known BOOLEAN DEFAULT FALSE,
  owner_name TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_plates_number ON license_plates(plate_number);
CREATE INDEX idx_plates_known ON license_plates(is_known);

-- Plate sightings table
CREATE TABLE IF NOT EXISTS plate_sightings (
  id TEXT PRIMARY KEY,
  plate_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  detection_id TEXT NOT NULL,
  confidence REAL NOT NULL,
  timestamp DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (plate_id) REFERENCES license_plates(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (detection_id) REFERENCES detections(id) ON DELETE CASCADE
);

CREATE INDEX idx_sightings_plate ON plate_sightings(plate_id);
CREATE INDEX idx_sightings_event ON plate_sightings(event_id);

-- Known faces table (for future face recognition)
CREATE TABLE IF NOT EXISTS known_faces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  relationship TEXT, -- owner, family, friend, delivery, etc.
  encoding TEXT, -- Face encoding vector
  photo_url TEXT,
  is_authorized BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Face sightings table
CREATE TABLE IF NOT EXISTS face_sightings (
  id TEXT PRIMARY KEY,
  face_id TEXT,
  event_id TEXT NOT NULL,
  detection_id TEXT NOT NULL,
  confidence REAL NOT NULL,
  is_unknown BOOLEAN DEFAULT FALSE,
  timestamp DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (face_id) REFERENCES known_faces(id) ON DELETE SET NULL,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (detection_id) REFERENCES detections(id) ON DELETE CASCADE
);

-- Device status table
CREATE TABLE IF NOT EXISTS device_status (
  device_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  last_seen DATETIME NOT NULL,
  storage_used_percent REAL,
  storage_free_gb REAL,
  upload_queue_size INTEGER,
  version TEXT,
  ip_address TEXT,
  is_online BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  channel TEXT NOT NULL, -- email, sms, push
  email TEXT,
  phone TEXT,
  device_token TEXT,
  alert_types TEXT, -- JSON array of alert types
  min_severity TEXT DEFAULT 'medium',
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  enabled BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notif_user ON notification_preferences(user_id);
CREATE INDEX idx_notif_enabled ON notification_preferences(enabled);

-- Analytics summary table (for dashboard)
CREATE TABLE IF NOT EXISTS daily_analytics (
  date DATE PRIMARY KEY,
  total_events INTEGER DEFAULT 0,
  sentry_events INTEGER DEFAULT 0,
  dashcam_events INTEGER DEFAULT 0,
  track_events INTEGER DEFAULT 0,
  total_alerts INTEGER DEFAULT 0,
  high_alerts INTEGER DEFAULT 0,
  people_detected INTEGER DEFAULT 0,
  vehicles_detected INTEGER DEFAULT 0,
  plates_detected INTEGER DEFAULT 0,
  storage_used_gb REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Geofence zones (for location-based alerts)
CREATE TABLE IF NOT EXISTS geofence_zones (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  center_lat REAL NOT NULL,
  center_lng REAL NOT NULL,
  radius_meters INTEGER NOT NULL,
  alert_on_entry BOOLEAN DEFAULT TRUE,
  alert_on_exit BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create triggers for updated_at
CREATE TRIGGER update_events_timestamp 
AFTER UPDATE ON events 
BEGIN
  UPDATE events SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_plates_timestamp 
AFTER UPDATE ON license_plates 
BEGIN
  UPDATE license_plates SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_faces_timestamp 
AFTER UPDATE ON known_faces 
BEGIN
  UPDATE known_faces SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_device_timestamp 
AFTER UPDATE ON device_status 
BEGIN
  UPDATE device_status SET updated_at = CURRENT_TIMESTAMP WHERE device_id = NEW.device_id;
END;

CREATE TRIGGER update_notif_timestamp 
AFTER UPDATE ON notification_preferences 
BEGIN
  UPDATE notification_preferences SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_geofence_timestamp 
AFTER UPDATE ON geofence_zones 
BEGIN
  UPDATE geofence_zones SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
