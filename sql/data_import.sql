-- ============================================================
-- DriveIQ - Data Import & ETL
-- ============================================================
-- Workflow:
--
-- CSV
--   ↓
-- fuel_logs_import
--   ↓
-- Validation
--   ↓
-- Transformation
--   ↓
-- fuel_logs
-- ============================================================


-- ============================================================
-- 1. CLEAR STAGING TABLE
-- ============================================================
-- Use this before loading a fresh CSV file.
-- ============================================================

TRUNCATE TABLE fuel_logs_import;


-- ============================================================
-- 2. LOAD CSV
-- ============================================================
-- Run the COPY command from psql.
--
-- Adjust the file path to your local CSV file.
--
-- Example:
--
-- \copy fuel_logs_import (
--     fill_date,
--     vehicle_name,
--     fuel_type,
--     vehicle_id,
--     odometer_km,
--     litres_filled,
--     amount_spent,
--     cost_per_litre,
--     full_tank,
--     driving_environment,
--     traffic_condition
-- )
-- FROM 'D:/Streamlit/data/fuel_data.csv'
-- WITH (
--     FORMAT CSV,
--     HEADER TRUE,
--     QUOTE '"',
--     ESCAPE '"'
-- );


-- ============================================================
-- 3. CHECK IMPORTED RECORD COUNT
-- ============================================================

SELECT COUNT(*) AS imported_records
FROM fuel_logs_import;


-- ============================================================
-- 4. CHECK IMPORT DATE RANGE
-- ============================================================

SELECT
    COUNT(*) AS records,
    MIN(fill_date) AS first_date,
    MAX(fill_date) AS latest_date
FROM fuel_logs_import;


-- ============================================================
-- 5. CHECK VEHICLES IN STAGING TABLE
-- ============================================================

SELECT
    vehicle_name,
    fuel_type,
    COUNT(*) AS records
FROM fuel_logs_import
GROUP BY
    vehicle_name,
    fuel_type
ORDER BY
    vehicle_name;


-- ============================================================
-- 6. CHECK FOR INVALID FUEL TYPES
-- ============================================================

SELECT *
FROM fuel_logs_import
WHERE fuel_type NOT IN ('Petrol', 'Diesel')
   OR fuel_type IS NULL;


-- ============================================================
-- 7. CHECK FOR INVALID LITRES
-- ============================================================

SELECT *
FROM fuel_logs_import
WHERE litres_filled IS NULL
   OR litres_filled <= 0;


-- ============================================================
-- 8. CHECK FOR INVALID AMOUNTS
-- ============================================================

SELECT *
FROM fuel_logs_import
WHERE amount_spent IS NULL
   OR amount_spent <= 0;


-- ============================================================
-- 9. CHECK FUEL PRICE CALCULATION
-- ============================================================

SELECT
    vehicle_name,
    litres_filled,
    amount_spent,
    cost_per_litre,
    ROUND(
        amount_spent / NULLIF(litres_filled, 0),
        2
    ) AS calculated_cost_per_litre
FROM fuel_logs_import
WHERE ABS(
    cost_per_litre -
    ROUND(
        amount_spent / NULLIF(litres_filled, 0),
        2
    )
) > 0.01;


-- ============================================================
-- 10. CHECK DUPLICATES IN STAGING DATA
-- ============================================================

SELECT
    vehicle_name,
    fill_date,
    odometer_km,
    COUNT(*) AS duplicate_count
FROM fuel_logs_import
GROUP BY
    vehicle_name,
    fill_date,
    odometer_km
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 11. VERIFY VEHICLE MAPPING
-- ============================================================

SELECT
    i.vehicle_name,
    i.vehicle_id,
    v.vehicle_id AS matched_vehicle_id,
    v.fuel_type AS master_fuel_type
FROM fuel_logs_import i
LEFT JOIN vehicles v
    ON i.vehicle_id = v.vehicle_id
ORDER BY i.vehicle_name;


-- ============================================================
-- 12. INSERT VALID DATA INTO PRODUCTION TABLE
-- ============================================================

INSERT INTO fuel_logs (
    vehicle_id,
    fill_date,
    odometer_km,
    litres_filled,
    amount_spent,
    cost_per_litre,
    full_tank,
    driving_environment,
    traffic_condition
)
SELECT
    vehicle_id,
    fill_date,
    odometer_km,
    litres_filled,
    amount_spent,
    ROUND(
        amount_spent / NULLIF(litres_filled, 0),
        2
    ),
    full_tank,
    driving_environment,
    traffic_condition
FROM fuel_logs_import
WHERE vehicle_id IS NOT NULL
  AND fill_date IS NOT NULL
  AND odometer_km IS NOT NULL
  AND litres_filled > 0
  AND amount_spent > 0
ON CONFLICT (
    vehicle_id,
    fill_date,
    odometer_km
)
DO NOTHING;


-- ============================================================
-- 13. VERIFY PRODUCTION RECORD COUNT
-- ============================================================

SELECT COUNT(*) AS production_records
FROM fuel_logs;


-- ============================================================
-- 14. VERIFY LATEST PRODUCTION DATA
-- ============================================================

SELECT
    f.fuel_log_id,
    v.vehicle_name,
    f.fill_date,
    f.odometer_km,
    f.litres_filled,
    f.amount_spent,
    f.cost_per_litre
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
ORDER BY f.fuel_log_id DESC
LIMIT 20;