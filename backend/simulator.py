import time
import pandas as pd
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db

# 1. Initialize Firebase Admin SDK (Ensure your databaseURL is exact)
# (If already initialized earlier in your script, keep your existing initialization block)
if not firebase_admin._apps:
    cred = credentials.Certificate("C:\\Users\\harin\\Desktop\\sem2\\el\\backend\\serviceAccountKey.json")
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://food-freshness-78e13-default-rtdb.asia-southeast1.firebasedatabase.app'
    })

# 2. Reference the active Firebase Node matching your schema
fruit_status_ref = db.reference('/Fruit_Status')

# 3. Load dataset safely
try:
    # Change filename to match your exact dataset file (e.g., dataset.csv)
    df = pd.read_csv("historical_data.csv") 
except Exception as e:
    print(f"Error loading dataset file: {e}")
    exit()

# Clean up column headers by stripping out any hidden accidental trailing spaces
df.columns = df.columns.str.strip()

print("Detected data columns:", list(df.columns))
print("Starting real-world historical timeline streaming to Firebase...")

# 4. Intelligent Dynamic Column Fallback Mapping
# This scans your CSV headers to find your status key even if named differently!
def get_column_fallback(df, target_name, fallbacks):
    if target_name in df.columns:
        return target_name
    for fallback in fallbacks:
        if fallback in df.columns:
            return fallback
    raise KeyError(f"Could not locate a column for '{target_name}'. Please verify your CSV headers match.")

try:
    state_col = get_column_fallback(df, 'ground_truth', ['Freshness', 'status', 'Status', 'state', 'State', 'current_status'])
    weight_col = get_column_fallback(df, 'weight_g', ['weight', 'Weight', 'Weight(g)', 'weight_grams'])
    mq135_col = get_column_fallback(df, 'mq135_ppm', ['mq135', 'MQ135', 'co2', 'CO2'])
    mq3_col = get_column_fallback(df, 'mq3_ppm', ['mq3', 'MQ3', 'ethanol', 'Ethanol'])
    temp_col = get_column_fallback(df, 'temperature_c', ['temperature', 'Temperature', 'temp', 'Temp'])
    humid_col = get_column_fallback(df, 'humidity_pct', ['humidity', 'Humidity', 'humid'])
except KeyError as e:
    print(f"\nConfiguration Error: {e}")
    exit()

# 5. Main streaming loop simulation
for index, row in df.iterrows():
    try:
        # Build payload mapping dynamically from matched headers
        telemetry_packet = {
            "current_state": str(row[state_col]).strip().lower(),
            "weight_g": float(row[weight_col]),
            "mq135_ppm": float(row[mq135_col]),
            "mq3_ppm": float(row[mq3_col]),
            "temperature_c": float(row[temp_col]),
            "humidity_pct": float(row[humid_col])
        }
        
        # Stream live packet updates to Firebase Realtime Database path
        fruit_status_ref.update(telemetry_packet)
        print(f"[{index + 1}/{len(df)}] Pushed telemetry matrix packet successfully -> {telemetry_packet['current_state']}")
        
    except Exception as inner_error:
        print(f"Error packing telemetry row index {index}: {inner_error}")
        
    # Interval pacing delay (seconds) between sequential sensor transmissions
    time.sleep(2.0)