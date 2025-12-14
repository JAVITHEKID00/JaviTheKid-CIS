import requests, sys, json

if len(sys.argv) < 2:
    print("Usage: instagram_lookup.py <username>")
    sys.exit()

username = sys.argv[1]

url = f"https://www.instagram.com/{username}/?__a=1&__d=dis"

headers = {
    "User-Agent": "Mozilla/5.0"
}

r = requests.get(url, headers=headers)

if r.status_code != 200:
    print("[-] Instagram API Error")
    sys.exit()

data = r.json()

user_data = data.get("graphql", {}).get("user", {})

output = {
    "full_name": user_data.get("full_name", ""),
    "username": username,
    "bio": user_data.get("biography", ""),
    "followers": user_data.get("edge_followed_by", {}).get("count", ""),
    "following": user_data.get("edge_follow", {}).get("count", ""),
    "posts": user_data.get("edge_owner_to_timeline_media", {}).get("count", ""),
    "is_private": user_data.get("is_private", ""),
    "profile_pic": user_data.get("profile_pic_url_hd", "")
}

print(json.dumps(output, indent=4))
