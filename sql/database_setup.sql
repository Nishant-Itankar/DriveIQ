-- ============================================================
-- DriveIQ - Database Setup
-- ============================================================
-- Purpose:
--   Creates the core tables and database constraints required
--   by the DriveIQ fuel tracking application.
-- ============================================================


-- ============================================================
-- 1. VEHICLES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_name VARCHAR(100) NOT NULL,
    fuel_type VARCHAR(20) NOT NULL
        CHECK (fuel_type IN ('Petrol', 'Diesel'))
);


-- ============================================================
-- 2. FUEL LOGS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fuel_logs (
    fuel_log_id SERIAL PRIMARY KEY,

    vehicle_id INTEGER NOT NULL,

    fill_date DATE NOT NULL,

    odometer_km INTEGER NOT NULL
        CHECK (odometer_km >= 0),

    litres_filled NUMERIC(10, 2) NOT NULL
        CHECK (litres_filled > 0),

    amount_spent NUMERIC(12, 2) NOT NULL
        CHECK (amount_spent > 0),

    cost_per_litre NUMERIC(10, 2) NOT NULL
        CHECK (cost_per_litre > 0),

    full_tank BOOLEAN NOT NULL,

    driving_environment VARCHAR(20) NOT NULL
        CHECK (
            driving_environment IN
            ('City', 'Highway', 'Mixed')
        ),

    traffic_condition VARCHAR(20) NOT NULL
        CHECK (
            traffic_condition IN
            ('Light', 'Moderate', 'Heavy')
        ),

    CONSTRAINT fk_fuel_logs_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
);


-- ============================================================
-- 3. STAGING TABLE FOR BULK CSV IMPORT
-- ============================================================

CREATE TABLE IF NOT EXISTS fuel_logs_import (
    fill_date DATE,
    vehicle_name VARCHAR(100),
    fuel_type VARCHAR(20),
    vehicle_id INTEGER,
    odometer_km INTEGER,
    litres_filled NUMERIC(10, 2),
    amount_spent NUMERIC(12, 2),
    cost_per_litre NUMERIC(10, 2),
    full_tank BOOLEAN,
    driving_environment VARCHAR(20),
    traffic_condition VARCHAR(20)
);


-- ============================================================
-- 4. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fuel_logs_vehicle
ON fuel_logs(vehicle_id);


CREATE INDEX IF NOT EXISTS idx_fuel_logs_date
ON fuel_logs(fill_date);


CREATE INDEX IF NOT EXISTS idx_fuel_logs_odometer
ON fuel_logs(vehicle_id, odometer_km);


-- ============================================================
-- 5. DUPLICATE PROTECTION
-- ============================================================
-- One fuel entry is identified by:
-- Vehicle + Date + Odometer
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS ux_fuel_logs_duplicate
ON fuel_logs (
    vehicle_id,
    fill_date,
    odometer_km
);