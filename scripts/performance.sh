#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

drives=$@
number_of_drives=$#
drives_to_test=($drives)

file_size_in_bytes=$(numfmt --from=iec $PERFORMANCE_FILE_SIZE)
small_file_size_in_bytes=$(numfmt --from=iec $PERFORMANCE_SMALL_FILE_SIZE)
small_files_count=$(($file_size_in_bytes / $small_file_size_in_bytes / 4))

test_write() {
  file_size_in_bytes=$(numfmt --from=iec $2)
  total_size=$(numfmt --to=iec $(($file_size_in_bytes * $3)))
  echo "Writing $total_size as $2 file $3 times:"
  dd if=/dev/zero bs=$2 count=$3 of=$1 oflag=dsync 2>&1
}

test_read() {
  # Flush cache
  sync && echo 3 > /proc/sys/vm/drop_caches

  file_size_in_bytes=$(numfmt --from=iec $2)
  total_size=$(numfmt --to=iec $(($file_size_in_bytes * $3)))
  echo "Reading $total_size as $2 file $3 times:"
  dd if=$1 bs=$2 count=$3 of=/dev/null oflag=dsync 2>&1
}

echo "This will wipe the drives ($number_of_drives total: \`$drives\`)!"
read -p $'Do you want to continue? [Y/n]\n' continue
if [[ "$continue" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  read -p $'Really? [Y/n]\r\n' really
  if [[ "$really" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    iteration=1
    for drive in $drives; do
      echo "Testing \`$drive\` drive performance"

      large_write=$(test_write $drive $PERFORMANCE_FILE_SIZE 1)
      echo "$large_write"
      large_write_speed=$(extract_speed_from_dd "$large_write")

      small_write=$(test_write $drive $PERFORMANCE_SMALL_FILE_SIZE $small_files_count)
      echo "$small_write"
      small_write_speed=$(extract_speed_from_dd "$small_write")

      tiny_write=$(test_write $drive $(drive_block_size $drive) 1000)
      echo "$tiny_write"
      tiny_write_speed=$(extract_speed_from_dd "$tiny_write")

      large_read=$(test_read $drive $PERFORMANCE_FILE_SIZE 1)
      echo "$large_read"
      large_read_speed=$(extract_speed_from_dd "$large_read")

      small_read=$(test_read $drive $PERFORMANCE_SMALL_FILE_SIZE $small_files_count)
      echo "$small_read"
      small_read_speed=$(extract_speed_from_dd "$small_read")

      tiny_read=$(test_read $drive $(drive_block_size $drive) 1000)
      echo "$tiny_read"
      tiny_read_speed=$(extract_speed_from_dd "$tiny_read")

      json=$(
        jq \
          --arg large_size "$file_size_in_bytes" \
          --arg small_size "$small_file_size_in_bytes" \
          --arg small_count "$small_files_count" \
          --arg tiny_size "$(drive_block_size $drive)" \
          --arg large_write_speed "$large_write_speed" \
          --arg small_write_speed "$small_write_speed" \
          --arg tiny_write_speed "$tiny_write_speed" \
          --arg large_read_speed "$large_read_speed" \
          --arg small_read_speed "$small_read_speed" \
          --arg tiny_read_speed "$tiny_read_speed" \
          -n '
          {
            "write": [
              { "file_size": $large_size | tonumber, "file_count": 1, "speed": $large_write_speed | tonumber },
              { "file_size": $small_size | tonumber, "file_count": $small_count | tonumber, "speed": $small_write_speed | tonumber },
              { "file_size": $tiny_size | tonumber, "file_count": 1000, "speed": $tiny_write_speed | tonumber }
            ],
            "read": [
              { "file_size": $large_size | tonumber, "file_count": 1, "speed": $large_read_speed | tonumber },
              { "file_size": $small_size | tonumber, "file_count": $small_count | tonumber, "speed": $small_read_speed | tonumber },
              { "file_size": $tiny_size | tonumber, "file_count": 1000, "speed": $tiny_read_speed | tonumber }
            ]
          }
        '
      )

      drive_folder_path=$(drive_folder_path $drive)
      prepare_drive_folder $drive
      performance_file_name=$(date +'%Y_%m_%d_%H_%M')_performance
      echo "$json" > $drive_folder_path/${performance_file_name}.json

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
