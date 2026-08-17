import os

import pandas as pd
import psycopg2
import streamlit as st
from dotenv import load_dotenv


# ============================================================
# CONFIGURATION
# ============================================================

load_dotenv()

st.set_page_config(
    page_title="DriveIQ",
    page_icon="🚗",
    layout="wide"
)


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


# ============================================================
# VEHICLE FUNCTIONS
# ============================================================

def get_vehicles():
    conn = get_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT
                vehicle_id,
                vehicle_name,
                fuel_type
            FROM vehicles
            ORDER BY vehicle_id;
        """)

        return cur.fetchall()

    finally:
        cur.close()
        conn.close()


def add_vehicle(vehicle_name, fuel_type):
    conn = get_connection()
    cur = conn.cursor()

    try:
        # Check for duplicate vehicle name
        cur.execute("""
            SELECT vehicle_id
            FROM vehicles
            WHERE LOWER(vehicle_name) = LOWER(%s);
        """, (vehicle_name.strip(),))

        existing = cur.fetchone()

        if existing:
            return False, "Vehicle already exists."

        # Insert vehicle
        cur.execute("""
            INSERT INTO vehicles (
                vehicle_name,
                fuel_type
            )
            VALUES (%s, %s)
            RETURNING vehicle_id;
        """, (
            vehicle_name.strip(),
            fuel_type
        ))

        vehicle_id = cur.fetchone()[0]

        conn.commit()

        return True, vehicle_id

    except Exception as e:
        conn.rollback()
        return False, str(e)

    finally:
        cur.close()
        conn.close()


# ============================================================
# ODOMETER
# ============================================================

def get_max_odometer(vehicle_id):
    conn = get_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT MAX(odometer_km)
            FROM fuel_logs
            WHERE vehicle_id = %s;
        """, (vehicle_id,))

        result = cur.fetchone()

        if result and result[0] is not None:
            return int(result[0])

        return None

    finally:
        cur.close()
        conn.close()


# ============================================================
# DUPLICATE CHECK
# ============================================================

def entry_exists(vehicle_id, fill_date, odometer_km):
    conn = get_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT fuel_log_id
            FROM fuel_logs
            WHERE vehicle_id = %s
              AND fill_date = %s
              AND odometer_km = %s
            LIMIT 1;
        """, (
            vehicle_id,
            fill_date,
            odometer_km
        ))

        return cur.fetchone() is not None

    finally:
        cur.close()
        conn.close()


# ============================================================
# ADD FUEL ENTRY
# ============================================================

def add_fuel_entry(
    vehicle_id,
    fill_date,
    odometer_km,
    litres_filled,
    amount_spent,
    full_tank,
    driving_environment,
    traffic_condition
):
    cost_per_litre = round(
        amount_spent / litres_filled,
        2
    )

    conn = get_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
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
            VALUES (
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s
            )
            RETURNING fuel_log_id;
        """, (
            vehicle_id,
            fill_date,
            odometer_km,
            litres_filled,
            amount_spent,
            cost_per_litre,
            full_tank,
            driving_environment,
            traffic_condition
        ))

        fuel_log_id = cur.fetchone()[0]

        conn.commit()

        return True, fuel_log_id, cost_per_litre

    except psycopg2.errors.UniqueViolation:
        conn.rollback()

        return False, "duplicate", cost_per_litre

    except Exception as e:
        conn.rollback()

        return False, str(e), cost_per_litre

    finally:
        cur.close()
        conn.close()


# ============================================================
# RECENT FUEL ENTRIES
# ============================================================

def get_recent_entries(limit=10):
    conn = get_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT
                f.fill_date AS "Date",
                v.vehicle_name AS "Vehicle",
                f.odometer_km AS "Odometer (km)",
                f.litres_filled AS "Litres",
                f.amount_spent AS "Amount (₹)",
                f.cost_per_litre AS "₹/L",
                f.full_tank AS "Full Tank",
                f.driving_environment AS "Environment",
                f.traffic_condition AS "Traffic"
            FROM fuel_logs f
            JOIN vehicles v
                ON f.vehicle_id = v.vehicle_id
            ORDER BY f.fuel_log_id DESC
            LIMIT %s;
        """, (limit,))

        rows = cur.fetchall()

        columns = [
            "Date",
            "Vehicle",
            "Odometer (km)",
            "Litres",
            "Amount (₹)",
            "₹/L",
            "Full Tank",
            "Environment",
            "Traffic"
        ]

        return pd.DataFrame(
            rows,
            columns=columns
        )

    finally:
        cur.close()
        conn.close()


# ============================================================
# PAGE HEADER
# ============================================================

st.title("🚗 DriveIQ")
st.caption("Fuel tracking made simple.")

st.divider()


# ============================================================
# LOAD VEHICLES
# ============================================================

try:
    vehicles = get_vehicles()

except Exception as e:
    st.error(
        f"Could not connect to PostgreSQL: {e}"
    )
    st.stop()


vehicle_names = [
    vehicle[1]
    for vehicle in vehicles
]

vehicle_options = (
    vehicle_names +
    ["➕ Add New Vehicle"]
)


# ============================================================
# VEHICLE SELECTION
# ============================================================

st.subheader("⛽ Add Fuel Entry")

selected_vehicle = st.selectbox(
    "Vehicle",
    vehicle_options
)


# ============================================================
# ADD NEW VEHICLE
# ============================================================

if selected_vehicle == "➕ Add New Vehicle":

    st.subheader("🚗 Add New Vehicle")

    col1, col2 = st.columns(2)

    with col1:
        new_vehicle_name = st.text_input(
            "Vehicle Name"
        )

    with col2:
        new_fuel_type = st.selectbox(
            "Fuel Type",
            ["Petrol", "Diesel"]
        )

    if st.button(
        "Add Vehicle",
        type="primary"
    ):

        if not new_vehicle_name.strip():
            st.warning(
                "Please enter a vehicle name."
            )

        else:

            success, result = add_vehicle(
                new_vehicle_name,
                new_fuel_type
            )

            if success:
                st.success(
                    f"✅ {new_vehicle_name} "
                    f"added successfully!"
                )

                st.rerun()

            else:
                st.error(
                    f"❌ {result}"
                )


# ============================================================
# EXISTING VEHICLE — FUEL ENTRY
# ============================================================

else:

    selected_vehicle_data = next(
        vehicle
        for vehicle in vehicles
        if vehicle[1] == selected_vehicle
    )

    vehicle_id = selected_vehicle_data[0]
    fuel_type = selected_vehicle_data[2]

    last_odometer = get_max_odometer(
        vehicle_id
    )


    # --------------------------------------------------------
    # VEHICLE INFORMATION
    # --------------------------------------------------------

    info_col1, info_col2 = st.columns(2)

    with info_col1:
        st.info(
            f"⛽ Fuel Type: **{fuel_type}**"
        )

    with info_col2:

        if last_odometer is not None:

            st.metric(
                "Last Odometer Reading",
                f"{last_odometer:,} km"
            )

        else:

            st.metric(
                "Last Odometer Reading",
                "No previous reading"
            )


    st.divider()


    # --------------------------------------------------------
    # DATE + ODOMETER
    # --------------------------------------------------------

    col1, col2 = st.columns(2)

    with col1:

        fill_date = st.date_input(
            "Date"
        )

    with col2:

        minimum_odometer = (
            last_odometer
            if last_odometer is not None
            else 0
        )

        odometer_km = st.number_input(
            "Current Odometer (km)",
            min_value=int(minimum_odometer),
            step=1
        )


    # --------------------------------------------------------
    # LITRES + AMOUNT
    # --------------------------------------------------------

    col1, col2 = st.columns(2)

    with col1:

        litres_filled = st.number_input(
            "Litres Filled (L)",
            min_value=0.01,
            step=0.01,
            format="%.2f"
        )

    with col2:

        amount_spent = st.number_input(
            "Amount Spent (₹)",
            min_value=0.01,
            step=0.01,
            format="%.2f"
        )


    # --------------------------------------------------------
    # COST PER LITRE
    # --------------------------------------------------------

    cost_per_litre = round(
        amount_spent / litres_filled,
        2
    )

    st.metric(
        "Cost per Litre",
        f"₹{cost_per_litre:.2f}/L"
    )


    # --------------------------------------------------------
    # FULL TANK + ENVIRONMENT
    # --------------------------------------------------------

    col1, col2 = st.columns(2)

    with col1:

        full_tank = st.radio(
            "Full Tank",
            ["Yes", "No"],
            horizontal=True
        )

    with col2:

        driving_environment = st.selectbox(
            "Driving Environment",
            ["City", "Highway", "Mixed"]
        )


    # --------------------------------------------------------
    # TRAFFIC
    # --------------------------------------------------------

    traffic_condition = st.selectbox(
        "Traffic Condition",
        ["Light", "Moderate", "Heavy"]
    )


    st.divider()


    # --------------------------------------------------------
    # ADD FUEL ENTRY BUTTON
    # --------------------------------------------------------

    add_entry = st.button(
        "⛽ Add Fuel Entry",
        type="primary",
        width="stretch"
    )


    # --------------------------------------------------------
    # VALIDATION + INSERT
    # --------------------------------------------------------

    if add_entry:

        if litres_filled <= 0:

            st.error(
                "Litres filled must be greater than 0."
            )

        elif amount_spent <= 0:

            st.error(
                "Amount spent must be greater than 0."
            )

        elif (
            last_odometer is not None
            and odometer_km <= last_odometer
        ):

            st.error(
                f"Odometer must be greater than "
                f"{last_odometer:,} km."
            )

        elif entry_exists(
            vehicle_id,
            fill_date,
            odometer_km
        ):

            st.error(
                "⚠️ This fuel entry already exists."
            )

        else:

            success, result, saved_cost = (
                add_fuel_entry(
                    vehicle_id,
                    fill_date,
                    odometer_km,
                    litres_filled,
                    amount_spent,
                    full_tank == "Yes",
                    driving_environment,
                    traffic_condition
                )
            )

            if success:

                st.success(
                    f"✅ Fuel Entry #{result} "
                    f"added successfully!"
                )

                st.info(
                    f"{selected_vehicle} • "
                    f"{litres_filled:.2f} L • "
                    f"₹{amount_spent:.2f} • "
                    f"₹{saved_cost:.2f}/L"
                )

                st.rerun()

            elif result == "duplicate":

                st.error(
                    "⚠️ This fuel entry already exists."
                )

            else:

                st.error(
                    f"❌ Could not save entry: {result}"
                )


# ============================================================
# RECENT ENTRIES
# ============================================================

st.divider()

st.subheader("📋 Recent Fuel Entries")

try:

    recent_entries = get_recent_entries(10)

    if recent_entries.empty:

        st.info(
            "No fuel entries found."
        )

    else:

        st.dataframe(
            recent_entries,
            width="stretch",
            hide_index=True
        )

except Exception as e:

    st.error(
        f"Could not load recent entries: {e}"
    )