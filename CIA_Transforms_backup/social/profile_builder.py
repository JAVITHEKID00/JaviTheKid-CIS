import json, sys

if len(sys.argv) < 4:
    print("Usage: profile_builder.py <username> <tiktok.json> <instagram.json> <twitter.json>")
    sys.exit()

username = sys.argv[1]
files = sys.argv[2:]

profile = {"username": username, "sources": {}}

for f in files:
    src = f.split("_")[0].upper()
    try:
        profile["sources"][src] = json.load(open(f))
    except:
        profile["sources"][src] = "No data"

out = f"/root/OSINT_Logs/PROFILE_{username}.json"
json.dump(profile, open(out, "w"), indent=4)

print(f"[+] Profile saved at {out}")
