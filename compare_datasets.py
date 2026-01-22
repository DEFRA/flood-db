#!/usr/bin/env python3
"""
Compare DEV vs PRE database data and CSV
"""

from datetime import datetime, timedelta
import csv

def load_db_data(filepath):
    data = []
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            timestamp = datetime.fromisoformat(row['value_timestamp'])
            value = float(row['value'])
            data.append({'timestamp': timestamp, 'value': value})
    return data

def load_csv_data(filepath):
    data = []
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            timestamp = datetime.fromisoformat(row['Timestamp (UTC)'].replace('Z', '+00:00'))
            value = float(row['Rainfall (mm)'])
            data.append({'timestamp': timestamp, 'value': value})
    return data

# Load all datasets
csv_data = load_csv_data('/home/geordiefoo83/Projects/Flood/flood-db/rainfall_data.csv')
dev_data = load_db_data('/home/geordiefoo83/Projects/Flood/flood-db/data-dev.csv')
pre_data = load_db_data('/home/geordiefoo83/Projects/Flood/flood-db/data-pre.csv')

print("=" * 80)
print("DATASET COMPARISON")
print("=" * 80)
print(f"CSV data:  {len(csv_data)} readings, latest: {csv_data[-1]['timestamp']}, value: {csv_data[-1]['value']}")
print(f"DEV data:  {len(dev_data)} readings, latest: {dev_data[0]['timestamp']}, value: {dev_data[0]['value']}")
print(f"PRE data:  {len(pre_data)} readings, latest: {pre_data[0]['timestamp']}, value: {pre_data[0]['value']}")
print()

# Find the difference
print("=" * 80)
print("KEY FINDING: Database has EXTRA reading not in CSV!")
print("=" * 80)
print(f"Database latest: {dev_data[0]['timestamp']} = {dev_data[0]['value']} mm")
print(f"CSV latest:      {csv_data[-1]['timestamp']} = {csv_data[-1]['value']} mm")
print()
print("⚠️  The database has a reading at 09:45 (0.4mm) that's NOT in your CSV!")
print()

# Calculate using database's latest timestamp (09:45)
latest_db = dev_data[0]['timestamp']
print("=" * 80)
print(f"CALCULATIONS USING DATABASE LATEST TIMESTAMP: {latest_db}")
print("=" * 80)

one_hr = latest_db - timedelta(hours=1)
six_hr = latest_db - timedelta(hours=6)
day = latest_db - timedelta(days=1)

print(f"\n1 HOUR window: > {one_hr}")
one_hr_readings = [d for d in dev_data if d['timestamp'] > one_hr]
for r in one_hr_readings:
    print(f"  {r['timestamp']}: {r['value']} mm")
print(f"Total: {sum(d['value'] for d in one_hr_readings)} mm")

print(f"\n6 HOUR window: > {six_hr}")
six_hr_readings = [d for d in dev_data if d['timestamp'] > six_hr]
print(f"Readings: {len(six_hr_readings)}")
print(f"Total: {sum(d['value'] for d in six_hr_readings)} mm")

print(f"\n24 HOUR window: > {day}")
day_readings = [d for d in dev_data if d['timestamp'] > day]
print(f"Readings: {len(day_readings)}")
print(f"Total: {sum(d['value'] for d in day_readings)} mm")

# Now check if there are any differences in the values between DEV and PRE
print("\n" + "=" * 80)
print("CHECKING FOR DIFFERENCES BETWEEN DEV AND PRE")
print("=" * 80)

if len(dev_data) != len(pre_data):
    print(f"⚠️  Different number of readings: DEV={len(dev_data)}, PRE={len(pre_data)}")
else:
    print(f"✓ Same number of readings: {len(dev_data)}")

# Check if values match
differences = []
for i in range(min(len(dev_data), len(pre_data))):
    if dev_data[i]['value'] != pre_data[i]['value'] or dev_data[i]['timestamp'] != pre_data[i]['timestamp']:
        differences.append((i, dev_data[i], pre_data[i]))

if differences:
    print(f"⚠️  Found {len(differences)} differences in values/timestamps")
    for idx, dev, pre in differences[:10]:  # Show first 10
        print(f"  Row {idx}: DEV={dev} vs PRE={pre}")
else:
    print("✓ All timestamps and values match between DEV and PRE")
