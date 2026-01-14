#!/system/bin/sh
# This script is written in POSIX shell 
# Description: Systemless ad & porn blocking via hosts file

HOSTS="/data/adb/modules/hosts/system/etc/hosts"
DIR="/sdcard/Download"
BACKUP="$DIR/Backup/hosts"
TMP="$DIR/hosts"
NULL=/dev/null

block_ads=false
block_porn=false
restore=false

ADS_URL="https://raw.githubusercontent.com/Bhavishyaa12/Ad-Nuke/main/hosts"
PORN_URL="https://raw.githubusercontent.com/Bhavishyaa12/Ad-Nuke/main/porn_hosts"


die() {
    exit 1
}

#Check if command available or not and then download the hosts file
download() {
    command -v wget >/dev/null 2>&1 || { echo "Installing wget..."; pkg update -y >/dev/null 2>&1 && pkg install wget -y >/dev/null 2>&1 || die "wget install failed"; }
    wget -qO "$1" "$2" || die "Download failed: $2"
}

require_root() {
    su -c "[ -f '$HOSTS' ] || die 'Enable Magisk Systemless Hosts first (Magisk app --> Settings)'"
}

#Check if dir available
mkdir -p "$DIR" || die "Cannot create $DIR"
require_root

while getopts "bprh" opt; do
    case "$opt" in
        b) block_ads=true ;;
        p) block_porn=true ;;
        r) restore=true ;;
        h)
            echo "Usage: $0 [-b] [-p] [-r]"
            echo " -b  Block ads"
            echo " -p  Block porn sites"
            echo " -r  Restore original hosts"
            exit 0 ;;
        *) die "Invalid option. Use -h"
	   exit 0  ;;
    esac
done

if [ "$block_ads" = false ] && [ "$block_porn" = false ] && [ "$restore" = false ]; then
    echo "Error no flag specified"
    echo "Use -h for help"
    exit 0
fi

#Backup first
if [ ! -f "$BACKUP" ]; then
    mkdir -p "$(dirname "$BACKUP")"
    su -c "cp '$HOSTS' '$BACKUP'" || die "Backup failed"
    echo "Backup created"
fi


#Restore hosts file

if [ "$restore" = true ]; then
    [ -f "$BACKUP" ] || die "Backup not found"
    su -c "cp '$BACKUP' '$HOSTS'"
    echo "Hosts file restored"
    exit 0
fi


su -c "cp '$BACKUP' '$TMP'" || die "Temp copy failed"

if [ "$block_ads" = true ]; then
    echo "Blocking ads..."
    download "$DIR/hosts" "$ADS_URL"
    cat "$DIR/hosts" >> "$TMP" 2>&1 #Supress the error
fi

if [ "$block_porn" = true ]; then
    echo "Blocking porn websites..."
    download "$DIR/porn_hosts" "$PORN_URL"
    cat "$DIR/porn_hosts" >> "$TMP"
fi

su -c "cp '$TMP' '$HOSTS'" || die "Failed to apply hosts"
rm -f "$TMP"

echo "Hosts files updated successfully"
echo "No reboot required"
echo "Enjoy!!!"
