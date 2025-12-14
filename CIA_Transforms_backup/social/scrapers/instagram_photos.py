import requests, sys, os, json

if len(sys.argv) < 2:
    print("Usage: instagram_photos.py <username>")
    sys.exit()

username = sys.argv[1]
url = f"https://www.instagram.com/{username}/?__a=1&__d=dis"
headers = { "User-Agent": "Mozilla/5.0" }

r = requests.get(url, headers=headers)
data = r.json()

posts = data["graphql"]["user"]["edge_owner_to_timeline_media"]["edges"]

folder = f"/root/OSINT_Logs/IG_{username}"
os.makedirs(folder, exist_ok=True)

output = []

for p in posts:
    img = p["node"]["display_url"]
    shortcode = p["node"]["shortcode"]

    img_data = requests.get(img).content
    file_path = f"{folder}/{shortcode}.jpg"

    with open(file_path, "wb") as f:
        f.write(img_data)

    output.append({
        "shortcode": shortcode,
        "file": file_path,
        "likes": p["node"]["edge_liked_by"]["count"],
        "comments": p["node"]["edge_media_to_comment"]["count"]
    })

print(json.dumps(output, indent=4))
