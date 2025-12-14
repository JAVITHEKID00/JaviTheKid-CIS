import requests, sys, json

if len(sys.argv) < 2:
    print("Usage: tiktok_lookup.py <username>")
    sys.exit()

user = sys.argv[1]
url = f"https://www.tiktok.com/api/user/detail/?uniqueId={user}"

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

r = requests.get(url, headers=headers)

if r.status_code != 200:
    print("[-] TikTok API Error")
    sys.exit()

data = r.json()

output = {
    "username": user,
    "nickname": data.get("userInfo", {}).get("user", {}).get("nickname", ""),
    "avatar": data.get("userInfo", {}).get("user", {}).get("avatarLarger", ""),
    "followers": data.get("userInfo", {}).get("stats", {}).get("followerCount", ""),
    "following": data.get("userInfo", {}).get("stats", {}).get("followingCount", ""),
    "likes": data.get("userInfo", {}).get("stats", {}).get("heartCount", ""),
    "bio": data.get("userInfo", {}).get("user", {}).get("signature", "")
}

print(json.dumps(output, indent=4))
