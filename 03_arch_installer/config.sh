#!/bin/bash
set -e

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
        DISK_DEV_FILE) read -r -p "Insert ${VAR_NAME} (e.g. '/dev/nvme0n1'): " VAR_VAL;;
        DISK_PART_EFI_DEV_FILE | DISK_PART_SWAP_DEV_FILE | DISK_PART_ROOT_DEV_FILE) break;;
        *) read -r -p "Insert ${VAR_NAME}: " VAR_VAL;;
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

function print_vars() {
  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    echo -e "${VAR_NAME}=${!VAR_NAME}"
  done
}

function write_vars() {
  echo "#!/bin/bash
set -e  "  > "$1"
  for VAR_NAME in "${VAR_NAMES[@]}"
  do
    echo "${VAR_NAME}=\"${!VAR_NAME}\"" >> "$1"
  done
  chmod 0777 "$1"
}
