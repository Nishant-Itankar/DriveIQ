-- ============================================================
-- DriveIQ - Analysis Queries
-- ============================================================
-- Purpose:
--   Analytical SQL queries used for validation, reporting,
--   and Power BI preparation.
-- ============================================================


-- ============================================================
-- 1. TOTAL FUEL RECORDS
-- ============================================================

SELECT
    COUNT(*) AS total_records
FROM fuel_logs;


-- ============================================================
-- 2. DATE RANGE
-- ============================================================

SELECT
    MIN(fill_date) AS first_fuel_date,
    MAX(fill_date) AS latest_fuel_date
FROM fuel_logs;


-- ============================================================
-- 3. TOTAL FUEL CONSUMED
-- ============================================================

SELECT
    ROUND(SUM(litres_filled), 2) AS total_litres
FROM fuel_logs;


-- ============================================================
-- 4. TOTAL FUEL EXPENDITURE
-- ============================================================

SELECT
    ROUND(SUM(amount_spent), 2) AS total_fuel_cost
FROM fuel_logs;


-- ============================================================
-- 5. AVERAGE FUEL PRICE
-- ============================================================

SELECT
    ROUND(
        AVG(cost_per_litre),
        2
    ) AS average_fuel_price
FROM fuel_logs;


-- ============================================================
-- 6. AVERAGE PETROL PRICE
-- ============================================================

SELECT
    ROUND(
        AVG(f.cost_per_litre),
        2
    ) AS average_petrol_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
WHERE v.fuel_type = 'Petrol';


-- ============================================================
-- 7. AVERAGE DIESEL PRICE
-- ============================================================

SELECT
    ROUND(
        AVG(f.cost_per_litre),
        2
    ) AS average_diesel_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
WHERE v.fuel_type = 'Diesel';


-- ============================================================
-- 8. FUEL SUMMARY BY VEHICLE
-- ============================================================

SELECT
    v.vehicle_name,
    v.fuel_type,
    COUNT(f.fuel_log_id) AS fuel_entries,
    ROUND(SUM(f.litres_filled), 2) AS total_litres,
    ROUND(SUM(f.amount_spent), 2) AS total_spent,
    ROUND(AVG(f.cost_per_litre), 2) AS avg_fuel_price
FROM vehicles v
LEFT JOIN fuel_logs f
    ON v.vehicle_id = f.vehicle_id
GROUP BY
    v.vehicle_id,
    v.vehicle_name,
    v.fuel_type
ORDER BY total_spent DESC;


-- ============================================================
-- 9. MAXIMUM ODOMETER BY VEHICLE
-- ============================================================

SELECT
    v.vehicle_name,
    MAX(f.odometer_km) AS max_odometer_km
FROM vehicles v
JOIN fuel_logs f
    ON v.vehicle_id = f.vehicle_id
GROUP BY
    v.vehicle_id,
    v.vehicle_name
ORDER BY
    v.vehicle_id;


-- ============================================================
-- 10. LATEST FUEL ENTRY BY VEHICLE
-- ============================================================

SELECT DISTINCT ON (v.vehicle_id)
    v.vehicle_name,
    f.fill_date,
    f.odometer_km,
    f.litres_filled,
    f.amount_spent,
    f.cost_per_litre
FROM vehicles v
JOIN fuel_logs f
    ON v.vehicle_id = f.vehicle_id
ORDER BY
    v.vehicle_id,
    f.fill_date DESC,
    f.fuel_log_id DESC;


-- ============================================================
-- 11. MONTHLY FUEL EXPENDITURE
-- ============================================================

SELECT
    DATE_TRUNC('month', fill_date)::DATE AS month,
    ROUND(SUM(amount_spent), 2) AS monthly_spent
FROM fuel_logs
GROUP BY
    DATE_TRUNC('month', fill_date)
ORDER BY month;


-- ============================================================
-- 12. MONTHLY FUEL CONSUMPTION
-- ============================================================

SELECT
    DATE_TRUNC('month', fill_date)::DATE AS month,
    ROUND(SUM(litres_filled), 2) AS monthly_litres
FROM fuel_logs
GROUP BY
    DATE_TRUNC('month', fill_date)
ORDER BY month;


-- ============================================================
-- 13. FUEL EXPENDITURE BY FUEL TYPE
-- ============================================================

SELECT
    v.fuel_type,
    ROUND(SUM(f.amount_spent), 2) AS total_spent,
    ROUND(SUM(f.litres_filled), 2) AS total_litres,
    ROUND(AVG(f.cost_per_litre), 2) AS average_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
GROUP BY
    v.fuel_type
ORDER BY total_spent DESC;


-- ============================================================
-- 14. FUEL USAGE BY DRIVING ENVIRONMENT
-- ============================================================

SELECT
    driving_environment,
    COUNT(*) AS fuel_entries,
    ROUND(SUM(litres_filled), 2) AS total_litres,
    ROUND(SUM(amount_spent), 2) AS total_spent,
    ROUND(AVG(cost_per_litre), 2) AS avg_price
FROM fuel_logs
GROUP BY
    driving_environment
ORDER BY total_spent DESC;


-- ============================================================
-- 15. FUEL USAGE BY TRAFFIC CONDITION
-- ============================================================

SELECT
    traffic_condition,
    COUNT(*) AS fuel_entries,
    ROUND(SUM(litres_filled), 2) AS total_litres,
    ROUND(SUM(amount_spent), 2) AS total_spent,
    ROUND(AVG(cost_per_litre), 2) AS avg_price
FROM fuel_logs
GROUP BY
    traffic_condition
ORDER BY total_spent DESC;


-- ============================================================
-- 16. FULL TANK VS NON-FULL TANK
-- ============================================================

SELECT
    full_tank,
    COUNT(*) AS fuel_entries,
    ROUND(SUM(litres_filled), 2) AS total_litres,
    ROUND(SUM(amount_spent), 2) AS total_spent,
    ROUND(AVG(cost_per_litre), 2) AS avg_price
FROM fuel_logs
GROUP BY
    full_tank
ORDER BY
    full_tank DESC;


-- ============================================================
-- 17. VEHICLE + ENVIRONMENT ANALYSIS
-- ============================================================

SELECT
    v.vehicle_name,
    f.driving_environment,
    COUNT(*) AS entries,
    ROUND(SUM(f.litres_filled), 2) AS litres,
    ROUND(SUM(f.amount_spent), 2) AS spent,
    ROUND(AVG(f.cost_per_litre), 2) AS avg_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
GROUP BY
    v.vehicle_id,
    v.vehicle_name,
    f.driving_environment
ORDER BY
    v.vehicle_name,
    spent DESC;


-- ============================================================
-- 18. VEHICLE + TRAFFIC ANALYSIS
-- ============================================================

SELECT
    v.vehicle_name,
    f.traffic_condition,
    COUNT(*) AS entries,
    ROUND(SUM(f.litres_filled), 2) AS litres,
    ROUND(SUM(f.amount_spent), 2) AS spent,
    ROUND(AVG(f.cost_per_litre), 2) AS avg_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
GROUP BY
    v.vehicle_id,
    v.vehicle_name,
    f.traffic_condition
ORDER BY
    v.vehicle_name,
    spent DESC;


-- ============================================================
-- 19. FUEL PRICE TREND
-- ============================================================

SELECT
    fill_date,
    v.vehicle_name,
    v.fuel_type,
    ROUND(f.cost_per_litre, 2) AS fuel_price
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
ORDER BY
    fill_date,
    v.vehicle_name;


-- ============================================================
-- 20. HIGHEST FUEL PRICE RECORDS
-- ============================================================

SELECT
    f.fill_date,
    v.vehicle_name,
    v.fuel_type,
    f.cost_per_litre,
    f.litres_filled,
    f.amount_spent
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
ORDER BY
    f.cost_per_litre DESC
LIMIT 10;


-- ============================================================
-- 21. HIGHEST FUEL EXPENSE RECORDS
-- ============================================================

SELECT
    f.fill_date,
    v.vehicle_name,
    f.litres_filled,
    f.amount_spent,
    f.cost_per_litre
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
ORDER BY
    f.amount_spent DESC
LIMIT 10;


-- ============================================================
-- 22. VEHICLE RECORD COUNTS
-- ============================================================

SELECT
    v.vehicle_name,
    COUNT(f.fuel_log_id) AS total_records
FROM vehicles v
LEFT JOIN fuel_logs f
    ON v.vehicle_id = f.vehicle_id
GROUP BY
    v.vehicle_id,
    v.vehicle_name
ORDER BY
    total_records DESC;


-- ============================================================
-- 23. RECENT FUEL ENTRIES
-- ============================================================

SELECT
    f.fuel_log_id,
    v.vehicle_name,
    v.fuel_type,
    f.fill_date,
    f.odometer_km,
    f.litres_filled,
    f.amount_spent,
    f.cost_per_litre,
    f.full_tank,
    f.driving_environment,
    f.traffic_condition
FROM fuel_logs f
JOIN vehicles v
    ON f.vehicle_id = v.vehicle_id
ORDER BY
    f.fuel_log_id DESC
LIMIT 20;


-- ============================================================
-- 24. CHECK FOR DUPLICATE RECORDS
-- ============================================================

SELECT
    vehicle_id,
    fill_date,
    odometer_km,
    COUNT(*) AS duplicate_count
FROM fuel_logs
GROUP BY
    vehicle_id,
    fill_date,
    odometer_km
HAVING COUNT(*) > 1;


-- ============================================================
-- 25. DATA QUALITY CHECK
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE vehicle_id IS NULL
    ) AS missing_vehicle,

    COUNT(*) FILTER (
        WHERE fill_date IS NULL
    ) AS missing_date,

    COUNT(*) FILTER (
        WHERE odometer_km IS NULL
    ) AS missing_odometer,

    COUNT(*) FILTER (
        WHERE litres_filled <= 0
    ) AS invalid_litres,

    COUNT(*) FILTER (
        WHERE amount_spent <= 0
    ) AS invalid_amount,

    COUNT(*) FILTER (
        WHERE cost_per_litre <= 0
    ) AS invalid_fuel_price

FROM fuel_logs;