#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

drives=$@
number_of_drives=$#
drives_to_wipe=($drives)

wipe() {
  echo "Filling \`$1\` drive with zeros:"
  dd if=/dev/zero of=$1 bs=$WIPE_BLOCK_SIZE status=progress 2>&1
}

echo "This will wipe the drives ($number_of_drives total: \`$drives\`)!"
read -p $'Do you want to continue? [Y/n]\n' continue
if [[ "$continue" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  read -p $'Really? [Y/n]\r\n' really
  if [[ "$really" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    iteration=1
    for drive in $drives; do
      drive_name=$(stripped_drive_path $drive)
      coproc_name=dd_${drive_name}
      eval coproc $coproc_name "{ wipe $drive; }"
      if [[ "$iteration" == 1 ]] && [[ $number_of_drives > 1 ]]; then
        echo 'Feel free to ignore the following warning(s):'
      fi
      ((iteration++))
    done
    if [[ $number_of_drives > 1 ]]; then
      echo
    fi

    iteration=1
    while [[ ${#drives_to_wipe[@]} > 0 ]]; do
      for drive in $drives; do
        drive_name=$(stripped_drive_path $drive)
        coproc_name=dd_${drive_name}

        # Move one line below the "Filling drive with zeros" message
        if [[ $iteration > 1 ]]; then
          tput cud 1
        fi

        # Print the current progress
        if read -r -d $'\r' -u ${!coproc_name[0]} line &> /dev/null; then
          tput el # Clear line
          echo -e "$line\r\n"
        else
          # Remove finished drive from the list
          for i in ${!drives_to_wipe[@]}; do
            if [ "${drives_to_wipe[$i]}" == "$drive" ]; then
              unset drives_to_wipe[$i]
            fi
          done
          tput el # Clear line
          number_of_wiped_drives=$(($number_of_drives - ${#drives_to_wipe[@]}))
          echo -e "$number_of_wiped_drives/$number_of_drives done!\r\n"
        fi

        # Move back one line up
        if [[ $iteration > 1 ]]; then
          tput cuu 1
        fi
      done

      # Move two lines up for each drive
      if [[ ${#drives_to_wipe[@]} > 0 ]]; then
        tput cuu $(($number_of_drives * 2))
      fi

      ((iteration++))
    done

    echo "All drives ($number_of_drives) wiped."
  else
    echo 'Not touching any drives & exiting…'
    exit
  fi
else
  echo 'Not touching any drives & exiting…'
  exit
fi
