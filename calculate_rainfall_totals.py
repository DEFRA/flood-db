#!/usr/bin/env python3
"""
Calculate rainfall totals for 1 hour, 6 hours, and 24 hours
using the same logic as rainfall_stations_mview.sql
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

# Find the latest timestamp (mimics the SQL logic)
latest_timestamp = max(data, key=lambda x: x['timestamp'])['timestamp']

print(f"Latest timestamp: {latest_timestamp.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"Total readings: {len(data)}")
print()

# Calculate 1 hour total
# SQL: WHERE dedup.value_timestamp > (latest.latest_timestamp - '01:00:00'::interval)
one_hour_cutoff = latest_timestamp - timedelta(hours=1)
one_hour_data = [d for d in data if d['timestamp'] > one_hour_cutoff]
one_hour_total = sum(d['value'] for d in one_hour_data)

print(f"=== 1 HOUR TOTAL ===")
print(f"Time window: > {one_hour_cutoff.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"Readings included: {len(one_hour_data)}")
print(f"Total rainfall: {one_hour_total} mm")
print()

# Calculate 6 hour total
# SQL: WHERE dedup.value_timestamp > (latest.latest_timestamp - '06:00:00'::interval)
six_hour_cutoff = latest_timestamp - timedelta(hours=6)
six_hour_data = [d for d in data if d['timestamp'] > six_hour_cutoff]
six_hour_total = sum(d['value'] for d in six_hour_data)

print(f"=== 6 HOUR TOTAL ===")
print(f"Time window: > {six_hour_cutoff.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"Readings included: {len(six_hour_data)}")
print(f"Total rainfall: {six_hour_total} mm")
print()

# Calculate 24 hour total
# SQL: WHERE dedup.value_timestamp > (latest.latest_timestamp - '1 day'::interval)
day_cutoff = latest_timestamp - timedelta(days=1)
day_data = [d for d in data if d['timestamp'] > day_cutoff]
day_total = sum(d['value'] for d in day_data)

print(f"=== 24 HOUR TOTAL ===")
print(f"Time window: > {day_cutoff.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"Readings included: {len(day_data)}")
print(f"Total rainfall: {day_total} mm")
print()

# Show the most recent readings for context
print("=== Recent readings (last 5) ===")
for d in sorted(data, key=lambda x: x['timestamp'])[-5:]:
    print(f"{d['timestamp'].strftime('%Y-%m-%d %H:%M:%S')} UTC: {d['value']} mm")
