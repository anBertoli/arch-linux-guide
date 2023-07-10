#!/bin/bash
set -e

source ./print.sh

declare -a VAR_NAMES=(
  WIFI_DEVICE
  WIFI_SSID
  WIFI_PASSPHRASE
  DISK_DEV_FILE
  DISK_PART_EFI_DEV_FILE
  DISK_PART_SWAP_DEV_FILE
  DISK_PART_ROOT_DEV_FILE
  BOOTLOADER_ID
  USER_NAME
  USER_PASSWORD
)

function read_in_vars() {
  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    while true; do
      case "$VAR_NAME" in
        WIFI_DEVICE):
          iwctl device list
          read -r -p "Insert ${VAR_NAME}: " VAR_VAL
          ;;
        WIFI_SSID)
          iwctl station "$WIFI_DEVICE" scan
          iwctl station "$WIFI_DEVICE" get-networks
          read -r -p "Insert ${VAR_NAME}: " VAR_VAL
          ;;
        DISK_DEV_FILE)
          lsblk
          read -r -p "Insert ${VAR_NAME}: " VAR_VAL
          ;;
        DISK_PART_EFI_DEV_FILE | DISK_PART_SWAP_DEV_FILE | DISK_PART_ROOT_DEV_FILE)
          break;;
        *)
          read -r -p "Insert ${VAR_NAME}: " VAR_VAL;;
      esac

      if [ -z "$VAR_VAL" ]
      then
            echo "Empty value, please insert value:"
            continue
      else
            eval "${VAR_NAME}=${VAR_VAL}"
            break
      fi
    done
  done

#  DISK_DEV_FILE="/dev/nvme0n1"
  if [[ "${DISK_DEV_FILE}" =~ ^/dev/nvme ]]; then
      DISK_PART_EFI_DEV_FILE="${DISK_DEV_FILE}p1"
      DISK_PART_SWAP_DEV_FILE="${DISK_DEV_FILE}p2"
      DISK_PART_ROOT_DEV_FILE="${DISK_DEV_FILE}p3"
  else
      echo "Unknown disk type ('${DISK_DEV_FILE}'). Aborting."
      exit 1
  fi
}

function check_vars {
  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    if [ -z "${!VAR_NAME}" ]
    then
          echo "Missing ${VAR_NAME} value. Aborting."
          exit 1
    fi
  done
  echo -e "All values set.\n"
}

function check_conf_file {
  if [ -f "./config.gen.sh" ]; then
    print_text "Config file present (./config.gen.sh)"
  else
    print_text "Config file not present (./config.gen.sh).
Consider regenerating them by executing ${BOLD_INTENSE_GREEN}./00_config_init.sh${BOLD_INTENSE_WHITE}"
    exit 1
  fi
}

function print_vars() {
  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    echo -e "${VAR_NAME}=${!VAR_NAME}"
  done
}

function write_vars() {
  echo "#!/bin/bash
set -e  "  > "$1"

#  echo "
#WIFI_DEVICE=wlan0
#WIFI_SSID=TISCALI-Andrea
#WIFI_PASSPHRASE=DK3U7B43CY
#DISK_DEV_FILE=/dev/nvme0n1
#DISK_PART_EFI_DEV_FILE=/dev/nvme0n1p1
#DISK_PART_SWAP_DEV_FILE=/dev/nvme0n1p2
#DISK_PART_ROOT_DEV_FILE=/dev/nvme0n1p3
#BOOTLOADER_ID=arch-linux-boot
#USER_NAME=andrea-arch
#USER_PASSWORD=AndreaArch
#  " >> "$1"

  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    echo "${VAR_NAME}=\"${!VAR_NAME}\"" >> "$1"
  done
  chmod 0777 "$1"
}
