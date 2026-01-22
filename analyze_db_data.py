#!/usr/bin/env python3
"""
Deep analysis of database data looking for duplicates and calculation logic
"""

from datetime import datetime, timedelta
from collections import defaultdict
import csv

def load_db_data(filepath):
    data = []
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            timestamp = datetime.fromisoformat(row['value_timestamp'])
            value = float(row['value'])
            parent_id = row['telemetry_value_parent_id']
            data.append({
                'timestamp': timestamp, 
                'value': value,
                'parent_id': parent_id
            })
    return data

# Load database data
dev_data = load_db_data('/home/geordiefoo83/Projects/Flood/flood-db/data-dev.csv')
pre_data = load_db_data('/home/geordiefoo83/Projects/Flood/flood-db/data-pre.csv')

print("=" * 80)
print("CRITICAL: Looking for DUPLICATE TIMESTAMPS in the database")
print("=" * 80)

# Check if there are multiple parent IDs per timestamp
dev_by_ts = defaultdict(list)
pre_by_ts = defaultdict(list)

for d in dev_data:
    dev_by_ts[d['timestamp']].append(d)

for d in pre_data:
    pre_by_ts[d['timestamp']].append(d)

print("\nDEV - Timestamps with multiple parent IDs:")
dev_duplicates = {ts: records for ts, records in dev_by_ts.items() if len(records) > 1}
if dev_duplicates:
    for ts, records in sorted(dev_duplicates.items()):
        print(f"  {ts}: {len(records)} records")
        for r in records:
            print(f"    parent_id={r['parent_id']}, value={r['value']}")
else:
    print("  None found - each timestamp has only ONE parent_id")

print("\nPRE - Timestamps with multiple parent IDs:")
pre_duplicates = {ts: records for ts, records in pre_by_ts.items() if len(records) > 1}
if pre_duplicates:
    for ts, records in sorted(pre_duplicates.items()):
        print(f"  {ts}: {len(records)} records")
        for r in records:
            print(f"    parent_id={r['parent_id']}, value={r['value']}")
else:
    print("  None found - each timestamp has only ONE parent_id")

print("\n" + "=" * 80)
print("Comparing DEV vs PRE data")
print("=" * 80)
print(f"DEV records: {len(dev_data)}")
print(f"PRE records: {len(pre_data)}")

# Check if values/timestamps match
all_match = True
for i in range(min(len(dev_data), len(pre_data))):
    if dev_data[i]['timestamp'] != pre_data[i]['timestamp'] or dev_data[i]['value'] != pre_data[i]['value']:
        print(f"MISMATCH at row {i}:")
        print(f"  DEV: {dev_data[i]}")
        print(f"  PRE: {pre_data[i]}")
        all_match = False
        if i > 10:  # Only show first few
            break

if all_match:
    print("✓ All timestamps and values match between DEV and PRE!")
    print("  (Only parent_ids are different)")

print("\n" + "=" * 80)
print("IMPORTANT: These CSVs are from AFTER deduplication!")
print("=" * 80)
print("The data you exported is ALREADY the result of the query.")
print("It's NOT showing the raw sls_telemetry_value table.")
print()
print("The query you ran:")
print("  FROM sls_telemetry_value_parent p")
print("  JOIN sls_telemetry_value v ON ...")
print()
print("This is showing ONE parent_id per timestamp, but there might be")
print("MULTIPLE parent_ids with the SAME timestamp in the raw tables!")
print()
print("🔍 To see the actual duplicates, you need to query:")
print("   SELECT p.station, p.region, p.telemetry_value_parent_id,")
print("          v.value_timestamp, v.value, p.end_timestamp")
print("   FROM sls_telemetry_value_parent p")
print("   JOIN sls_telemetry_value v ON p.telemetry_value_parent_id = v.telemetry_value_parent_id")
print("   WHERE p.parameter = 'Rainfall'")
print("     AND p.station = '3340'")
print("     AND v.value_timestamp >= '2026-01-20 09:00:00'")
print("   ORDER BY v.value_timestamp DESC, p.end_timestamp DESC;")
print()
print("This will show ALL rows, including duplicates if they exist!")
