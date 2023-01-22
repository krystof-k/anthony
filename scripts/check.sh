#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"

check_smartmontools_version() {
  major_version=$(smartctl --version | head -1 | awk '{print $2}' | awk -F. '{ print $1 }')
  if [[ $major_version < 7 ]]; then
    echo '`smartmontools` min. version 7 is required, please update.'
    exit 1
  fi
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if ! command -v smartctl &> /dev/null; then
  echo '`smartctl` command not found'

  read -r -p $'Do you want to install `smartmontools`? [Y/n]\n' smartmontools
  if [[ "$smartmontools" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    apt install smartmontools
  else
    exit 1
  fi

  check_smartmontools_version
else
  check_smartmontools_version
fi

if ! command -v jq &> /dev/null; then
  echo '`jq` command not found'

  read -r -p $'Do you want to install `jq`? [Y/n]\n' jq
  if [[ "$jq" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    apt install jq
  else
    exit 1
  fi
fi

if ! command -v fio &> /dev/null; then
  echo '`fio` command not found'

  read -r -p $'Do you want to install `fio`? [Y/n]\n' fio
  if [[ "$fio" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    apt install fio
  else
    exit 1
  fi
fi
