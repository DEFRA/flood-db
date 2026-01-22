#!/usr/bin/env python3
"""
Diagnose why the database values differ from CSV calculations
"""

from datetime import datetime, timedelta
import csv

# Read CSV data
data = []
with open('/home/geordiefoo83/Projects/Flood/flood-db/rainfall_data.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        timestamp = datetime.fromisoformat(row['Timestamp (UTC)'].replace('Z', '+00:00'))
        value = float(row['Rainfall (mm)'])
        data.append({'timestamp': timestamp, 'value': value})

print("CSV Data Analysis")
print("=" * 80)
print(f"First reading: {data[0]['timestamp']} - {data[0]['value']} mm")
print(f"Last reading:  {data[-1]['timestamp']} - {data[-1]['value']} mm")
print(f"Total readings: {len(data)}")
print()

# Find the latest timestamp
latest_timestamp = max(data, key=lambda x: x['timestamp'])['timestamp']

# Test different potential "latest timestamps" that might match the database results
# If database shows 0.1mm for 1hr, let's find what timestamp would give us that

print("Testing different possible 'latest timestamps' to match database values:")
print("=" * 80)

# Try different potential latest timestamps
test_timestamps = [
    data[-1]['timestamp'],  # 09:30
    data[-2]['timestamp'],  # 09:15
    data[-3]['timestamp'],  # 09:00
    data[-4]['timestamp'],  # 08:45
    data[-5]['timestamp'],  # 08:30
]

for test_ts in test_timestamps:
    one_hr = test_ts - timedelta(hours=1)
    six_hr = test_ts - timedelta(hours=6)
    day = test_ts - timedelta(days=1)
    
    one_hr_data = [d for d in data if d['timestamp'] > one_hr and d['timestamp'] <= test_ts]
    six_hr_data = [d for d in data if d['timestamp'] > six_hr and d['timestamp'] <= test_ts]
    day_data = [d for d in data if d['timestamp'] > day and d['timestamp'] <= test_ts]
    
    one_hr_total = sum(d['value'] for d in one_hr_data)
    six_hr_total = sum(d['value'] for d in six_hr_data)
    day_total = sum(d['value'] for d in day_data)
    
    print(f"\nIf latest_timestamp = {test_ts.strftime('%Y-%m-%d %H:%M:%S')}:")
    print(f"  1 hour:  {one_hr_total:.1f} mm (readings: {len(one_hr_data)})")
    print(f"  6 hours: {six_hr_total:.1f} mm (readings: {len(six_hr_data)})")
    print(f"  24 hours: {day_total:.1f} mm (readings: {len(day_data)})")
    
    # Check if this matches the database values
    if abs(one_hr_total - 0.1) < 0.01 and abs(six_hr_total - 1.8) < 0.01 and abs(day_total - 2.4) < 0.01:
        print("  ⭐ MATCH! This timestamp would produce the database values!")
        print(f"  Details for 1 hour window:")
        for d in one_hr_data:
            print(f"    {d['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}: {d['value']} mm")

print("\n" + "=" * 80)
print("Checking for potential data issues:")
print("=" * 80)

# Check for zero values that might be filtered
zero_count = sum(1 for d in data if d['value'] == 0)
non_zero_count = len(data) - zero_count
print(f"Zero values: {zero_count}")
print(f"Non-zero values: {non_zero_count}")

# Check for duplicates
timestamps = [d['timestamp'] for d in data]
if len(timestamps) != len(set(timestamps)):
    print("⚠️  Duplicate timestamps found!")
else:
    print("✓ No duplicate timestamps")

# Check recent non-zero readings
print("\nRecent non-zero readings:")
non_zero = [d for d in data if d['value'] > 0]
for d in non_zero[-10:]:
    print(f"  {d['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}: {d['value']} mm")
