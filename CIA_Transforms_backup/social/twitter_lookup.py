import requests, sys, json

if len(sys.argv) < 2:
    print("Usage: twitter_lookup.py <username>")
    sys.exit()

username = sys.argv[1]

url = f"https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names={username}"

r = requests.get(url)

if r.status_code != 200:
    print("[-] Twitter API Error")
    sys.exit()

data = r.json()[0]

output = {
    "username": username,
    "name": data.get("name", ""),
    "followers": data.get("followers_count", ""),
    "following": data.get("friends_count", ""),
    "verified": data.get("verified", ""),
    "profile_image": data.get("profile_image_url", "")
}

print(json.dumps(output, indent=4))
