#!/bin/bash
mkdir -p /root/OSINT_Logs

read -p "Enter username: " USER

echo "Select platform:"
echo "[1] TikTok"
echo "[2] Instagram"
echo "[3] Twitter/X"
echo "[4] Facebook"
read -p "> " OPT

case $OPT in

1)
    python3 /root/CIA_Transforms/social/tiktok_lookup.py "$USER"
;;

2)
    python3 /root/CIA_Transforms/social/instagram_lookup.py "$USER"
;;

3)
    python3 /root/CIA_Transforms/social/twitter_lookup.py "$USER"
;;

4)
    python3 /root/CIA_Transforms/social/facebook_lookup.py "$USER"
;;

*)
    echo "Invalid option"
;;

esac
