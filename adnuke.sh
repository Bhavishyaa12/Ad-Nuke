#!/system/bin/sh
# This script is written in POSIX shell 
# Author: Bhavishya
# Date created: 12/12/2025
# Date modified: 26/05/2026
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
    printf '%s\n' "$1" >&2
    exit 1
}

#Check if command available or not and then download the hosts file
download() {
    command -v wget >/dev/null 2>&1 || { echo "Installing wget..."; pkg update -y >/dev/null 2>&1 && pkg install wget -y >/dev/null 2>&1 || die "wget install failed"; }
    wget -qO "$1" "$2" || die "Download failed: $2"
}

require_root() {
    #Check if root available or not 
    su -c "[ -f '$HOSTS' ]" || \ 
    die 'Enable Magisk Systemless Hosts first (Magisk app --> Settings)'
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
    #if nothing is specified echo error in red text
    tput setaf 1 ; echo "Error no flag specified"
    echo "Use -h for help"
    tput sgr0
    exit 0
else
    #Say hello to the user just for an interactive script
    tput setaf 4 ; printf "Hii " ; printf '%s%s\n' \
    "$(printf '%s' "$USER" | cut -c1 | tr '[:lower:]' '[:upper:]')" \
    "$(printf '%s' "$USER" | cut -c2-)" 

    sleep 1

    echo "Initalizing the script to block ads....." ; tput sgr0

    sleep 1 
fi

#Backup first
if [ ! -f "$BACKUP" ]; then
    mkdir -p "$(dirname "$BACKUP")"
    su -c "cp '$HOSTS' '$BACKUP'" || die "Backup failed"
    echo "Backup created"
fi


#Restore hosts file if the user specified -r flag
if [ "$restore" = true ]; then
    #Check if backup file is there or not exit with error code 1
    [ -f "$BACKUP" ] || die "Backup not found" 
    su -c "cp '$BACKUP' '$HOSTS'"
    echo "Hosts file restored"
    exit 0
fi

#
su -c "cp '$BACKUP' '$TMP'" || die "Temp copy failed"

#Block only ads if the user selected -b in the script option
if [ "$block_ads" = true ]; then
    echo "Blocking ads..."
    download "$DIR/hosts" "$ADS_URL"
    cat "$DIR/hosts" >> "$TMP" 2>&1 
fi

#Block porn websites if the user has selected -p option
if [ "$block_porn" = true ]; then
    echo "Blocking porn websites..."
    #Download hosts list of porn webstie
    download "$DIR/porn_hosts" "$PORN_URL"
    #Append in the temparory file hosts which is created in /sdcard/Download/
    cat "$DIR/porn_hosts" >> "$TMP" 2>&1
    sleep .5
fi

#Copy the temporary hosts file into the systemless magisk host file and if it fails exit with error(code 1)
su -c "cp '$TMP' '$HOSTS'" || die "Failed to copy hosts file" 
#Remove the temporary hosts file created
rm -f "$TMP"

#Give a confirmation to the user
echo "Hosts files updated successfully"
echo "No reboot required"
echo "Enjoy!!!"
