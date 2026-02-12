#!/usr/bin/env python3
"""Submit IPUMS USA extract for prohibition/elite analysis."""
import os
import sys
import time
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))

from ipumspy import IpumsApiClient, MicrodataExtract, Sample, Variable

API_KEY = os.environ.get("IPUMS_API_KEY")
if not API_KEY:
    print("ERROR: IPUMS_API_KEY not set")
    sys.exit(1)

client = IpumsApiClient(API_KEY)

# 1% samples for 1870, 1880, 1900, 1910, 1920
# Note: 1890 census destroyed by fire
samples = [
    Sample("us1870c"),
    Sample("us1880a"),
    Sample("us1900l"),
    Sample("us1910m"),
    Sample("us1920a"),
]

variables = [
    Variable("YEAR"), Variable("STATEFIP"), Variable("COUNTYICP"),
    Variable("AGE"), Variable("SEX"), Variable("RACE"),
    Variable("BPL"),
    Variable("MBPL"),
    Variable("FBPL"),
    Variable("OCC1950"),
    Variable("OCCSCORE"),
    Variable("IND1950"),
    Variable("RELATE"),
    Variable("SERIAL"),
    Variable("LIT"),
    Variable("URBAN"),
    Variable("FARM"),
]

print(f"Submitting IPUMS USA extract:")
print(f"  Samples: {[s.id for s in samples]}")
print(f"  Variables: {len(variables)}")

extract = MicrodataExtract(
    collection="usa",
    samples=samples,
    variables=variables,
    data_format="csv",
)

extract_id = client.submit_extract(extract)
print(f"  Extract ID: {extract_id}")

# Save extract info
info = {
    "extract_id": str(extract_id),
    "samples": [s.id for s in samples],
    "variables": [v.name for v in variables],
    "submitted_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
}
data_dir = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(data_dir, exist_ok=True)
with open(os.path.join(data_dir, "ipums_extract_info.json"), "w") as f:
    json.dump(info, f, indent=2)

print(f"\nExtract submitted. Polling for completion...")
print(f"(Historical extracts may take 30-60 minutes)")

poll_interval = 120  # 2 minutes
max_wait = 7200      # 2 hours

elapsed = 0
while elapsed < max_wait:
    status = client.extract_status(extract_id)
    print(f"  [{time.strftime('%H:%M')}] Status: {status}")

    if status == "completed":
        print("Extract ready! Downloading...")
        client.download_extract(extract_id, data_dir)
        print(f"Downloaded to {data_dir}")
        break
    elif status == "failed":
        print(f"Extract {extract_id} FAILED")
        sys.exit(1)

    time.sleep(poll_interval)
    elapsed += poll_interval
else:
    print(f"Timed out after {max_wait}s. Check IPUMS website for extract {extract_id}.")
    sys.exit(1)

print("Done!")
