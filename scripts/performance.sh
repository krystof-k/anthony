#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

if ! command -v fio &> /dev/null; then
  echo '`fio` command not found'

  read -r -p $'Do you want to install `fio`? [Y/n]\n' fio
  if [[ "$fio" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    apt install fio
  else
    exit 1
  fi
fi

drives=$@
number_of_drives=$#
drives_to_test=($drives)

echo "This will wipe the drives ($number_of_drives total: \`$drives\`)!"
read -p $'Do you want to continue? [Y/n]\n' continue
if [[ "$continue" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  read -p $'Really? [Y/n]\r\n' really
  if [[ "$really" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    iteration=1
    for drive in $drives; do
      echo "Testing \`$drive\` drive performance"

      drive_folder_path=$(drive_folder_path $drive)
      prepare_drive_folder $drive
      performance_file_name=$drive_folder_path/$(date +'%Y_%m_%d_%H_%M')_performance.json

      fio --filename=$drive --output-format=json --output=$performance_file_name "$(dirname $0)/performance.ini"

      ((iteration++))
    done

    echo -e "\r\nAll drives ($number_of_drives) preformance tested."
  else
    echo 'Not testing performance of any drives & exiting…'
    exit
  fi
else
  echo 'Not testing performance of any drives & exiting…'
  exit
fi
