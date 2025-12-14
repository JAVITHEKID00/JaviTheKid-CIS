import json, sys
from datetime import datetime

if len(sys.argv) < 2:
    print("Usage: activity_profiler.py <json_file>")
    sys.exit()

file = sys.argv[1]
data = json.load(open(file))

hours = {}

for post in data:
    ts = post["timestamp"]
    hour = datetime.fromtimestamp(ts).hour
    hours[hour] = hours.get(hour, 0) + 1

sorted_hours = sorted(hours.items(), key=lambda x: x[1], reverse=True)

print("\nMost active hours:")
for h, c in sorted_hours:
    print(f"Hour {h}: {c} posts")

