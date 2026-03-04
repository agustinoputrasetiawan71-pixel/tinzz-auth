#!/data/data/com.termux/files/usr/bin/bash

# ============================================
#        TINZZxXITERS SYSTEM TOOL - FUTURISTIC
# ============================================

# --- COLORS ---
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
W='\033[1;37m'
C='\033[1;36m'
N='\033[0m'

# --- ROOT CHECK ---
if [ "$(id -u)" -ne 0 ]; then
    SCRIPT_PATH=$(realpath "$0")
    su -c "PATH=$PATH:/data/data/com.termux/files/usr/bin \"$SCRIPT_PATH\""
    exit
fi

# --- PATH MODULE ---
SRC="/data/user/0/com.termux/files/home/.syscache/sys.cache.swb"
DEST="/data/adb/modules/performance_module"
TEMP_ZIP="/data/user/0/com.termux/files/home/.syscache/module.zip"

# ============================================
# GITHUB CONFIG UNTUK LOGIN KEY
# ============================================
USERNAME_GITHUB="agustinoputrasetiawan71-pixel"
REPO_NAME="tinzz-auth"
BRANCH="main"

STATUS_URL="https://raw.githubusercontent.com/$USERNAME_GITHUB/$REPO_NAME/$BRANCH/status.txt"
USERS_URL="https://raw.githubusercontent.com/$USERNAME_GITHUB/$REPO_NAME/$BRANCH/users.txt"

# ============================================
# CEK STATUS SERVER
# ============================================
STATUS=$(curl -s --max-time 10 "$STATUS_URL" | tr -d '\r\n ')
if [[ "$STATUS" != "ON" ]]; then
    echo -e "${R}================================${N}"
    echo -e "${R}   SYSTEM UNDER MAINTENANCE     ${N}"
    echo -e "${R}================================${N}"
    exit 1
fi

# ============================================
# LOGIN USERNAME + KEY
# ============================================
echo -e "${C}========== LOGIN ==========${N}"
read -p "Username : " INPUT_USER
read -p "Key      : " INPUT_KEY

USER_DATA=$(curl -s "$USERS_URL")
MATCH=$(echo "$USER_DATA" | grep "^$INPUT_USER:")

if [[ -z "$MATCH" ]]; then
    echo -e "${R}LOGIN GAGAL: USERNAME TIDAK TERDAFTAR${N}"
    exit 1
fi

# Ambil hash dari GitHub
HASH_KEY=$(echo "$MATCH" | cut -d ':' -f2)
DURATION=$(echo "$MATCH" | cut -d ':' -f3)

# Hash input key
INPUT_HASH=$(echo -n "$INPUT_KEY" | sha256sum | awk '{print $1}')

if [[ "$INPUT_HASH" != "$HASH_KEY" ]]; then
    echo -e "${R}LOGIN GAGAL: KEY SALAH${N}"
    exit 1
fi

# ============================================
# CEK EXPIRED
# ============================================
DATA_DIR="$HOME/.tinzz_data"
mkdir -p "$DATA_DIR"

USER_FILE="$DATA_DIR/$INPUT_USER.start"

if [[ "$DURATION" != "unlimited" ]]; then
    # Jika belum pernah login, simpan timestamp sekarang
    if [[ ! -f "$USER_FILE" ]]; then
        date +%s > "$USER_FILE"
    fi

    START_TIME=$(cat "$USER_FILE")
    NOW=$(date +%s)

    EXPIRE_TS=$((START_TIME + DURATION*86400))

    if (( NOW > EXPIRE_TS )); then
        echo -e "${R}KEY SUDAH EXPIRED${N}"
        exit 1
    fi
fi

# ============================================
# FUNSI TAMPIL STATUS SISTEM
# ============================================
check_status() {
    STATUS_TEXT="AMAN"
    STATUS_COLOR=$G
    MESSAGE=""

    SELINUX=$(/system/bin/getenforce 2>/dev/null)
    [ "$SELINUX" != "Enforcing" ] && STATUS_TEXT="TIDAK AMAN" && STATUS_COLOR=$R && MESSAGE="${MESSAGE}\n• SELinux tidak Enforcing"

    ROOT_SU="/system/xbin/su"
    [ -f "$ROOT_SU" ] && STATUS_TEXT="TIDAK AMAN" && STATUS_COLOR=$R && MESSAGE="${MESSAGE}\n• Root terdeteksi"

    IPT=$(iptables -S OUTPUT 2>/dev/null | grep -c "DROP")
    [ -z "$IPT" ] && IPT=0
    [ "$IPT" -le 0 ] && STATUS_TEXT="TIDAK AMAN" && STATUS_COLOR=$R && MESSAGE="${MESSAGE}\n• Sistem jaringan belum sepenuhnya terkunci"

    HOST_FILE="/system/etc/hosts"
    NORMAL_SIZE=1360
    if [ -f "$HOST_FILE" ]; then
        SIZE=$(stat -c%s "$HOST_FILE" 2>/dev/null)
        [ "$SIZE" -ne "$NORMAL_SIZE" ] && STATUS_TEXT="TIDAK AMAN" && STATUS_COLOR=$R && MESSAGE="${MESSAGE}\n• Ada yang aneh, hubungi developer"
    fi

    # Google
    GOOGLE_MSG=""
    if pm list packages -d | grep -q "com.google.android.gms"; then
        [ "$STATUS_TEXT" = "AMAN" ] && STATUS_TEXT="RISK" && STATUS_COLOR=$Y
        GOOGLE_MSG="• Silahkan google dulu"
        MESSAGE="${MESSAGE}\n${GOOGLE_MSG}"
    fi

    # Module check
    if [ ! -d "$DEST" ]; then
        STATUS_TEXT="TIDAK AMAN"
        STATUS_COLOR=$R
        MESSAGE="${MESSAGE}\n• WAJIB PASANG MODULE"
    fi

    # --- TAMPIL
    echo -e "${C}========================================${N}"
    echo -e "STATUS       : ${STATUS_COLOR}${STATUS_TEXT}${N}"
    echo -e "----------------------------------------"
    IFS=$'\n'
    for line in $MESSAGE; do
        [[ "$line" == *"google"* ]] && echo -e "${Y}$line${N}" || echo -e "${R}$line${N}"
    done
    echo -e "${C}========================================${N}"
}

# ============================================
# MENU UTAMA
# ============================================
while true; do
    check_status
    echo -e "${W}1. GOOGLE Toggle"
    echo -e "2. PERFORMANCE MODULE Toggle"
    echo -e "3. REFRESH STATUS"
    echo -e "4. EXIT${N}"
    read -p "Select Option >> " OPT

    case $OPT in
        1) 
            GMS="com.google.android.gms"
            if pm list packages -d | grep -q "$GMS"; then
                pm enable $GMS >/dev/null 2>&1
                echo -e "${R}Proteksi OFF${N}"
            else
                pm disable $GMS >/dev/null 2>&1
                echo -e "${G}Proteksi ON${N}"
            fi
            ;;
        2)
            if [ -d "$DEST" ]; then
                echo -e "${R}Menonaktifkan module...${N}"
                rm -rf "$DEST"
                read -p "Tekan Enter untuk reboot..." < /dev/tty
                reboot
            else
                if [ ! -f "$SRC" ]; then
                    echo -e "${R}Module tidak ditemukan!${N}"
                    sleep 2
                    continue
                fi
                mv "$SRC" "$TEMP_ZIP"
                mkdir -p "$DEST"
                unzip -q "$TEMP_ZIP" -d "$DEST"
                chmod -R 755 "$DEST"
                chown -R 0:0 "$DEST"
                mv "$TEMP_ZIP" "$SRC"
                echo -e "${G}Module ON${N}"
                read -p "Tekan Enter untuk reboot..." < /dev/tty
                reboot
            fi
            ;;
        3) 
            echo -e "Refreshing status..."
            sleep 1
            ;;
        4) 
            echo -e "Exiting..."
            exit 0
            ;;
        *) sleep 1 ;;
    esac
done