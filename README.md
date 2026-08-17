# 🚗 DriveIQ

### Vehicle Fuel Tracking & Analytics Platform

DriveIQ is a personal vehicle fuel-tracking and analytics platform built to record, manage, analyze, and visualize real-world fuel consumption data.

The project combines a **PostgreSQL database**, a **Streamlit data-entry application**, and a **Power BI analytics dashboard** to create a complete end-to-end data workflow.

Instead of manually maintaining spreadsheets, DriveIQ provides a structured database for fuel records, a user-friendly interface for adding new entries, and an interactive dashboard for analyzing vehicle performance and fuel expenses.

---

## 📌 Project Overview

DriveIQ was designed around a simple real-world problem:

> How can fuel records for multiple family vehicles be stored, maintained, and analyzed without continuously managing Excel files?

The solution follows a complete data pipeline:

```text
                    ┌──────────────────────┐
                    │   Streamlit App      │
                    │                      │
                    │  Add Fuel Entry      │
                    │  Add Vehicle         │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │     PostgreSQL       │
                    │                      │
                    │      vehicles        │
                    │      fuel_logs       │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │      Power BI        │
                    │                      │
                    │ Interactive Dashboard│
                    │ Analytics & KPIs     │
                    └──────────────────────┘
```

For bulk historical data, DriveIQ also supports:

```text
Excel
   ↓
CSV
   ↓
fuel_logs_import
   ↓
Validation / Transformation
   ↓
fuel_logs
   ↓
Power BI
```

---

# 🚘 Vehicles

The current dataset contains three family-owned vehicles:

| Vehicle | Fuel Type |
|---|---|
| Hyundai Eon | Petrol |
| Hyundai Venue | Petrol |
| Mahindra XUV 3XO | Diesel |

The application is not limited to these vehicles.

New vehicles can be added directly from the Streamlit application using:

> `➕ Add New Vehicle`

The vehicle's fuel type is stored in the vehicle master table and is automatically associated with future fuel entries.

---

# ✨ Features

## ⛽ Fuel Entry Management

Users can add new fuel records directly through the Streamlit application.

The form includes:

- Date
- Vehicle
- Odometer Reading
- Litres Filled
- Amount Spent
- Full Tank
- Driving Environment
- Traffic Condition

The following values are handled automatically:

- Fuel Type
- Cost per Litre
- Vehicle ID
- Fuel Log ID

---

## 🚗 Vehicle Management

New vehicles can be added from the application.

Example:

```text
Vehicle Name: Hyundai Creta
Fuel Type: Diesel
```

The application automatically inserts the vehicle into the PostgreSQL `vehicles` table.

Duplicate vehicle names are checked before insertion.

---

## 📏 Odometer Validation

DriveIQ retrieves the **maximum recorded odometer reading** for the selected vehicle.

Example:

```text
Mahindra XUV 3XO

Last Odometer Reading
56,754 km
```

The user cannot enter an odometer reading lower than the vehicle's recorded maximum.

This prevents incorrect mileage calculations caused by accidental odometer entries.

---

## 💰 Automatic Fuel Price Calculation

Cost per litre is calculated automatically:

```text
Cost/Litre = Amount Spent ÷ Litres Filled
```

Example:

```text
₹2,760 ÷ 30.00 L = ₹92.00/L
```

The application displays the value to two decimal places.

---

## 🛡️ Duplicate Protection

DriveIQ uses two levels of duplicate protection.

### Application-level check

Before inserting a record, the application checks whether the combination already exists:

```text
Vehicle
+
Date
+
Odometer
```

If it already exists:

```text
⚠️ This fuel entry already exists.
```

### PostgreSQL-level protection

A unique index is also maintained in PostgreSQL:

```sql
CREATE UNIQUE INDEX ux_fuel_logs_duplicate
ON fuel_logs (
    vehicle_id,
    fill_date,
    odometer_km
);
```

This provides a second layer of protection against accidental duplicate records.

---

# 📊 Power BI Dashboard

The PostgreSQL database is connected to Power BI for analytics and visualization.

The dashboard contains multiple pages designed around different aspects of vehicle fuel usage.

## Dashboard Areas

The dashboard includes analysis such as:

- Total fuel expenditure
- Total fuel consumed
- Average fuel price
- Petrol average fuel price
- Diesel average fuel price
- Vehicle-level fuel analysis
- Fuel consumption trends
- Driving environment analysis
- Traffic condition analysis
- Fuel cost comparisons
- Vehicle performance analysis
- Scatter plot analysis
- Bar charts
- KPI cards
- Other interactive visualizations

The dashboard also supports filtering and comparison across vehicles.

---

# 🗄️ Database Design

DriveIQ uses PostgreSQL as the primary database.

## `vehicles`

Stores vehicle master information.

| Column | Description |
|---|---|
| `vehicle_id` | Unique vehicle identifier |
| `vehicle_name` | Vehicle name |
| `fuel_type` | Petrol / Diesel |

Example:

```text
vehicle_id | vehicle_name        | fuel_type
-----------+---------------------+----------
1          | Hyundai Eon         | Petrol
2          | Hyundai Venue       | Petrol
3          | Mahindra XUV 3XO    | Diesel
```

---

## `fuel_logs`

Stores individual fuel transactions.

| Column | Description |
|---|---|
| `fuel_log_id` | Unique fuel transaction ID |
| `vehicle_id` | Foreign key to `vehicles` |
| `fill_date` | Fuel fill date |
| `odometer_km` | Vehicle odometer reading |
| `litres_filled` | Quantity of fuel |
| `amount_spent` | Fuel cost |
| `cost_per_litre` | Calculated fuel price |
| `full_tank` | Whether the tank was filled completely |
| `driving_environment` | City / Highway / Mixed |
| `traffic_condition` | Light / Moderate / Heavy |

---

## `fuel_logs_import`

A staging table used for bulk CSV imports.

It allows raw CSV data to be imported before being transformed and inserted into the production `fuel_logs` table.

This separates raw imported data from the production database and reduces the risk of corrupting existing records.

---

# 📥 Bulk Data Import

DriveIQ supports bulk historical data imports using Excel/CSV.

Recommended workflow:

```text
Excel
  ↓
Save as CSV
  ↓
Import into fuel_logs_import
  ↓
Validate data
  ↓
Transform values
  ↓
Insert into fuel_logs
  ↓
Power BI Refresh
```

This is useful when importing hundreds or thousands of historical records.

For normal day-to-day fuel entries, the Streamlit application should be used instead.

---

# 🧑‍💻 Streamlit Application

The Streamlit application provides a user-friendly interface for interacting with the PostgreSQL database.

## Main Application Workflow

```text
Select Vehicle
      ↓
Fuel Type Automatically Identified
      ↓
Maximum Odometer Retrieved
      ↓
Enter Current Fuel Information
      ↓
Validate Input
      ↓
Check Duplicate
      ↓
Insert into PostgreSQL
      ↓
Show Success Message
      ↓
Display Recent Entries
```

---

# 🛠️ Technology Stack

- **Python**
- **Streamlit**
- **PostgreSQL**
- **psycopg2**
- **python-dotenv**
- **Pandas**
- **Microsoft Power BI**
- **Excel / CSV**
- **Git / GitHub**

---

# 📂 Project Structure

```text
DriveIQ/
│
├── app.py
├── requirements.txt
├── README.md
├── .gitignore
│
└── .env
```

> `.env` is used locally and should never be committed to GitHub.

---

# ⚙️ Installation

## 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/DriveIQ.git
```

Navigate into the project:

```bash
cd DriveIQ
```

## 2. Create a Virtual Environment

### Windows

```bash
python -m venv venv
venv\Scriptsctivate
```

### macOS / Linux

```bash
python3 -m venv venv
source venv/bin/activate
```

## 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

# 🔐 Database Configuration

Create a `.env` file in the project directory:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=postgres
DB_PASSWORD=your_password
```

Replace the values with your local PostgreSQL configuration.

### Important

Never commit `.env` to GitHub.

The `.gitignore` file should contain:

```text
.env
.venv/
venv/
__pycache__/
*.pyc
.streamlit/secrets.toml
```

---

# ▶️ Running the Application

Start Streamlit:

```bash
streamlit run app.py
```

The application will open in your browser.

Typical local address:

```text
http://localhost:8501
```

---

# 🧪 Validation

DriveIQ performs several checks before inserting a fuel record.

### Odometer

The new odometer must be greater than the maximum recorded value for the selected vehicle.

### Litres

```text
Litres > 0
```

### Amount

```text
Amount > 0
```

### Duplicate

The combination of:

```text
Vehicle + Date + Odometer
```

must be unique.

### Fuel Price

Calculated automatically:

```text
Amount ÷ Litres
```

---

# 🔄 Data Flow

## Normal Daily Usage

```text
User
 │
 ▼
Streamlit
 │
 ▼
Validation
 │
 ▼
PostgreSQL
 │
 ▼
Power BI
```

## Bulk Historical Import

```text
Excel
 │
 ▼
CSV
 │
 ▼
fuel_logs_import
 │
 ▼
Transformation
 │
 ▼
fuel_logs
 │
 ▼
Power BI
```

---

# 📈 Analytics Examples

DriveIQ can be used to answer questions such as:

### Vehicle

- Which vehicle consumes the most fuel?
- Which vehicle costs the most to operate?
- How much has been spent on each vehicle?
- How much fuel has each vehicle consumed?

### Fuel Price

- What is the average petrol price?
- What is the average diesel price?
- How has fuel price changed over time?

### Driving Conditions

- How does city driving compare with highway driving?
- Does heavy traffic result in higher fuel usage?
- Which driving environment is associated with higher costs?

### Vehicle Performance

- How does fuel consumption differ between vehicles?
- What is the relationship between distance travelled and fuel usage?
- How does fuel cost vary with driving conditions?

---

# 🎯 Project Goals

The main goals of DriveIQ are:

1. Replace manual fuel-record management.
2. Store structured vehicle data in PostgreSQL.
3. Provide a simple interface for adding new records.
4. Prevent duplicate and invalid entries.
5. Support bulk historical data imports.
6. Create meaningful Power BI analytics.
7. Build a realistic end-to-end data project.

---

# 🔮 Future Improvements

Potential future enhancements include:

- User authentication
- Multi-user support
- Cloud PostgreSQL database
- Cloud deployment of Streamlit
- Automatic Power BI refresh
- Fuel station tracking
- Payment method tracking
- Maintenance tracking
- Insurance and service reminders
- Vehicle expense tracking
- Monthly expense reports
- Fuel efficiency prediction
- Automated anomaly detection
- Mobile-friendly interface
- Export reports to Excel/PDF
- API-based fuel price integration

---

# 📌 Current Status

| Component | Status |
|---|---|
| PostgreSQL Database | ✅ Complete |
| Vehicle Master | ✅ Complete |
| Fuel Logs | ✅ Complete |
| Bulk CSV Import | ✅ Complete |
| Streamlit Entry App | ✅ Complete |
| Add Vehicle | ✅ Complete |
| Odometer Validation | ✅ Complete |
| Duplicate Protection | ✅ Complete |
| Power BI Dashboard | ✅ Complete |
| GitHub Repository | 🚧 In Progress |

---

# 👨‍💻 Author

**Nishant Itankar**

Built as an end-to-end data analytics and application project using:

**Python + Streamlit + PostgreSQL + Power BI**

---

# ⭐ Project Highlights

DriveIQ demonstrates an end-to-end workflow rather than just a dashboard:

```text
Data Collection
      ↓
Data Validation
      ↓
Database Storage
      ↓
Data Transformation
      ↓
Analytics
      ↓
Visualization
```

The project combines:

**Data Analytics + SQL + Python + Database Design + Streamlit + Power BI**

into a single real-world application.

---

## 🚗 DriveIQ

> Track it. Store it. Analyze it.
