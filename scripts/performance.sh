#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

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

    echo "All drives ($number_of_drives) preformance tested."
  else
    echo 'Not testing performance of any drives & exiting…'
    exit
  fi
else
  echo 'Not testing performance of any drives & exiting…'
  exit
fi
