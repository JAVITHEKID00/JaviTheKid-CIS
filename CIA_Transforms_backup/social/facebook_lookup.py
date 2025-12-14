import requests, sys, json

if len(sys.argv) < 2:
    print("Usage: facebook_lookup.py <username_or_id>")
    sys.exit()

user = sys.argv[1]

url = f"https://graph.facebook.com/{user}?fields=name,picture&type=large"

r = requests.get(url)

if "error" in r.text:
    print("[-] Facebook Public Info Not Available")
    sys.exit()

print(json.dumps(r.json(), indent=4))
