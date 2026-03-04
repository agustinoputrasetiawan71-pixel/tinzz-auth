#!/data/data/com.termux/files/usr/bin/bash

# ===== COLORS =====
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
C='\033[1;36m'
N='\033[0m'

# ===== CONFIG =====
USERNAME_GITHUB="agustinoputrasetiawan71-pixel"
REPO_NAME="tinzz-auth"

STATUS_URL="https://raw.githubusercontent.com/$USERNAME_GITHUB/$REPO_NAME/main/status.txt"
USER_URL="https://raw.githubusercontent.com/$USERNAME_GITHUB/$REPO_NAME/main/users.txt"

clear
echo -e "${Y}Connecting to server...${N}"
sleep 1

# ===== CEK STATUS =====
STATUS=$(curl -s --max-time 10 "$STATUS_URL" | tr -d '[:space:]')

if [[ "$STATUS" != "ON" ]]; then
    clear
    echo -e "${R}================================${N}"
    echo -e "${R}   SYSTEM UNDER MAINTENANCE     ${N}"
    echo -e "${R}================================${N}"
    exit 1
fi

# ===== LOGIN =====
echo ""
read -p "Username : " USER
read -p "Key      : " KEY
echo ""

LINE=$(curl -s "$USER_URL" | grep "^$USER:$KEY:")

if [[ -z "$LINE" ]]; then
    echo -e "${R}INVALID USERNAME OR KEY${N}"
    exit 1
fi

DURASI=$(echo "$LINE" | cut -d ':' -f3)

TMP_FILE="$HOME/.tinzz_users/$USER.date"
mkdir -p "$HOME/.tinzz_users"

if [[ "$DURASI" != "unlimited" ]]; then

    if [ ! -f "$TMP_FILE" ]; then
        date +%Y-%m-%d > "$TMP_FILE"
    fi

    START_DATE=$(cat "$TMP_FILE")
    END_DATE=$(date -d "$START_DATE + $DURASI" +%Y-%m-%d)
    TODAY=$(date +%Y-%m-%d)

    if [[ "$TODAY" > "$END_DATE" ]]; then
        echo -e "${R}KEY EXPIRED on $END_DATE${N}"
        exit 1
    fi

    echo -e "${G}LOGIN SUCCESS${N}"
    echo -e "${C}Valid until $END_DATE${N}"

else
    echo -e "${G}LOGIN SUCCESS - UNLIMITED KEY${N}"
fi

# ===== SCRIPT UTAMA DISINI =====
echo ""
echo -e "${Y}Welcome to TINZZ SYSTEM${N}"