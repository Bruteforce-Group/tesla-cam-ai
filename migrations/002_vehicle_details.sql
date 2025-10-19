-- Enhanced vehicle detection tables

-- Vehicle details table
CREATE TABLE IF NOT EXISTS vehicle_details (
  id TEXT PRIMARY KEY,
  detection_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  make TEXT,
  model TEXT,
  color TEXT,
  year INTEGER,
  body_type TEXT,
  confidence REAL,
  features TEXT, -- JSON: headlights, moving, parked, etc.
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (detection_id) REFERENCES detections(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE INDEX idx_vehicle_details_event ON vehicle_details(event_id);
CREATE INDEX idx_vehicle_details_make ON vehicle_details(make);
CREATE INDEX idx_vehicle_details_model ON vehicle_details(model);
CREATE INDEX idx_vehicle_details_color ON vehicle_details(color);

-- Enhanced license plates with state/region
ALTER TABLE license_plates ADD COLUMN state TEXT;
ALTER TABLE license_plates ADD COLUMN plate_format TEXT; -- standard, vanity, commercial
ALTER TABLE license_plates ADD COLUMN confidence REAL;

-- Known vehicles table (for tracking specific vehicles)
CREATE TABLE IF NOT EXISTS known_vehicles (
  id TEXT PRIMARY KEY,
  plate_number TEXT UNIQUE NOT NULL,
  owner_name TEXT,
  make TEXT,
  model TEXT,
  color TEXT,
  year INTEGER,
  relationship TEXT, -- owner, family, neighbor, delivery, suspicious
  is_authorized BOOLEAN DEFAULT TRUE,
  alert_on_detection BOOLEAN DEFAULT FALSE,
  notes TEXT,
  photo_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_known_vehicles_plate ON known_vehicles(plate_number);
CREATE INDEX idx_known_vehicles_authorized ON known_vehicles(is_authorized);
CREATE INDEX idx_known_vehicles_alert ON known_vehicles(alert_on_detection);

-- Vehicle sighting summary
CREATE TABLE IF NOT EXISTS vehicle_sighting_summary (
  id TEXT PRIMARY KEY,
  plate_number TEXT NOT NULL,
  make TEXT,
  model TEXT,
  color TEXT,
  first_seen DATETIME NOT NULL,
  last_seen DATETIME NOT NULL,
  total_sightings INTEGER DEFAULT 1,
  sentry_sightings INTEGER DEFAULT 0,
  dashcam_sightings INTEGER DEFAULT 0,
  is_frequent_visitor BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vehicle_summary_plate ON vehicle_sighting_summary(plate_number);
CREATE INDEX idx_vehicle_summary_frequent ON vehicle_sighting_summary(is_frequent_visitor);
CREATE INDEX idx_vehicle_summary_last_seen ON vehicle_sighting_summary(last_seen);

-- Vehicle match confidence
CREATE TABLE IF NOT EXISTS vehicle_matches (
  id TEXT PRIMARY KEY,
  plate_sighting_id TEXT NOT NULL,
  known_vehicle_id TEXT,
  match_confidence REAL,
  match_type TEXT, -- plate_exact, plate_partial, visual, historical
  matched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (plate_sighting_id) REFERENCES plate_sightings(id) ON DELETE CASCADE,
  FOREIGN KEY (known_vehicle_id) REFERENCES known_vehicles(id) ON DELETE SET NULL
);

-- Create triggers for vehicle summary updates
CREATE TRIGGER update_vehicle_summary_timestamp 
AFTER UPDATE ON vehicle_sighting_summary 
BEGIN
  UPDATE vehicle_sighting_summary SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_known_vehicles_timestamp 
AFTER UPDATE ON known_vehicles 
BEGIN
  UPDATE known_vehicles SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Mark frequent visitors (vehicles seen 10+ times)
CREATE TRIGGER mark_frequent_visitors
AFTER UPDATE ON vehicle_sighting_summary
BEGIN
  UPDATE vehicle_sighting_summary 
  SET is_frequent_visitor = CASE WHEN NEW.total_sightings >= 10 THEN TRUE ELSE FALSE END
  WHERE id = NEW.id;
END;
