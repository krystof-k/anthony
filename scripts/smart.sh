#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

drives=$@
number_of_drives=$#
drives_to_test=($drives)

test() {
  echo "Testing \`$1\` drive health:"
  smartctl -t long $1
}

echo "This will start long S.M.A.R.T. test on the drives ($number_of_drives total: \`$drives\`)!"
read -p $'Do you want to continue? [Y/n]\n' continue
if [[ "$continue" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  iteration=1
  for drive in $drives; do
    drive_name=$(stripped_drive_path $drive)
    coproc_name=smart_${drive_name}
    eval coproc $coproc_name "{ test $drive; }"
    if [[ "$iteration" == 1 ]] && [[ $number_of_drives > 1 ]]; then
      echo 'Feel free to ignore the following warning(s):'
    fi
    ((iteration++))
  done
  if [[ $number_of_drives > 1 ]]; then
    echo
  fi

  iteration=1
  while [[ ${#drives_to_test[@]} > 0 ]]; do
    for drive in $drives; do
      drive_name=$(stripped_drive_path $drive)
      coproc_name=smart_${drive_name}

      while read -r -d $'\r' -u ${!coproc_name[0]} line &> /dev/null; do
        echo "Waiting for \`$drive\` test to start"
      done

      expected_total_duration=$(drive_test_expected_duration $drive)
      tput el # Clear line
      echo "Testing \`$drive\` drive (expected total duration ${expected_total_duration} min):"

      # Print the current progress
      if drive_test_status $drive ]; then
        remaining_percent=$(drive_test_remaining_percent $drive)
        tput el # Clear line
        echo "${remaining_percent}% remaining"
      else
        # Don't update progress for finished drives
        if ! echo ${drives_to_test[@]} | grep -qw $drive; then
          tput cud 1
        fi

        for i in ${!drives_to_test[@]}; do
          if [ "${drives_to_test[$i]}" == "$drive" ]; then
            # Remove finished drive from the list
            unset drives_to_test[$i]

            # Save S.M.A.R.T. data
            drive_folder_path=$(drive_folder_path $drive)
            prepare_drive_folder $drive
            smart_file_name=$(date +'%Y_%m_%d_%H_%M')_smart
            smartctl --json=o -a $drive > $drive_folder_path/${smart_file_name}.json
            smartctl -a $drive > $drive_folder_path/${smart_file_name}.txt

            tput el # Clear line
            number_of_tested_drives=$(($number_of_drives - ${#drives_to_test[@]}))
            if drive_test_result $drive; then
              passed=passed
            else
              passed=failed
            fi
            echo "$number_of_tested_drives/$number_of_drives done and ${passed}!"
          fi
        done
      fi
    done

    # Move two lines up for each drive
    if [[ ${#drives_to_test[@]} > 0 ]]; then
      tput cuu $(($number_of_drives * 2))
    fi

    ((iteration++))
  done

  echo "All drives ($number_of_drives) health tested."
else
  echo 'Not testing health of any drives & exiting…'
  exit
fi
