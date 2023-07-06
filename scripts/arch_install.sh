
######################## Boot from installation medium ########################

# check we have booted in UEFI mode
if [ -z "$(ls -A /sys/firmware/efi/efivars)" ]; then
    echo "Empty /sys/firmware/efi/efivars"
    exit 1
fi

# set keyboard layout
ls /usr/share/kbd/keymaps/**/*.map.gz | grep it
loadkeys <layout> 

# connect to internet using non-interactive CLI,
# then ping to check everything works correctly
DEVICE="<device>"
SSID="<ssid>"

iwctl device list
iwctl station $DEVICE scan
iwctl station $DEVICE get-networks
iwctl station $DEVICE connect $SSID
ping -i 10 8.8.8.8

# sync the machine clock using the NTP time protocol
timedatectl set-ntp true


######################## Disk partitioning ########################

DEV_FILE="/dev/nvme01"

# list paritions than delete all of them
sgdisk -p "$DEV_FILE"
sgdisk -d 1
sgdisk -d 2
sgdisk -d 3
sgdisk -d 4

# start = 0, means next starting point 
sgdisk -n 1:0:+1G -t 1:ef00 -g "$DEV_FILE" # EFI

### INSTALL WINDOWS HERE IF YOU WANT TO DUAL BOOT

sgdisk -n 1:0:+10G -t 1:8200 -g "$DEV_FILE" # SWAP
sgdisk -n 1:0:0 -t 1:8300 -g "$DEV_FILE" # ROOT

# check results
sgdisk -p "$DEV_FILE"

