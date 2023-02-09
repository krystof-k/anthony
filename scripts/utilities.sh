#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"

drive_vendor() {
  drive_model_family_raw $1 | awk '{print $1}'
}

drive_model() {
  vendor=$(drive_vendor $1)
  model=$(lsblk $1 --nodeps --output model --noheadings)
  echo $model | sed "s|$vendor ||"
}

drive_model_family() {
  vendor=$(drive_vendor $1)
  model_family_raw=$(drive_model_family_raw $1)
  echo $model_family_raw | sed "s|$vendor ||"
}

drive_model_family_raw() {
  smartctl --json -i $1 | jq -r '.model_family'
}

drive_serial() {
  lsblk $1 --nodeps --output serial --noheadings
}

drive_type() {
  rotational=$(lsblk $1 --nodeps --output rota --noheadings | sed "s| ||g")
  if [[ $rotational == 1 ]]; then
    echo 'HDD'
  else
    echo 'SSD'
  fi
}

drive_size() {
  gigabytes=$(drive_size_in_gigabytes $1)
  terabytes=$(drive_size_in_terabytes $1)

  if (($gigabytes > 1500)) && [ $(($terabytes * 1000)) = $gigabytes ]; then
    echo "$terabytes TB"
  else
    echo "$gigabytes GB"
  fi
}

drive_size_in_gigabytes() {
  bytes=$(lsblk $1 --nodeps --output size --noheadings --bytes)
  gigabytes=$((bytes / 1000 / 1000 / 1000))
  echo $gigabytes
}

drive_size_in_terabytes() {
  gigabytes=$(drive_size_in_gigabytes $1)
  terabytes=$((gigabytes / 1000))
  echo $terabytes
}

drive_block_size() {
  lsblk $1 --nodeps --output phy-sec --noheadings --bytes | sed "s| ||g"
}

stripped_drive_path() {
  echo $1 | awk -F/ '{ print $3 }'
}

drive_test_expected_duration() {
  smartctl --json -a $1 | jq -r '.ata_smart_data.self_test.polling_minutes.extended'
}

drive_test_status() {
  value=$(smartctl --json -a $1 | jq -r '.ata_smart_data.self_test.status.value')
  if ((value >= 241 && value <= 249)); then
    return 0
  else
    return 1
  fi
}

drive_test_remaining_percent() {
  smartctl --json -a $1 | jq -r '.ata_smart_data.self_test.status.remaining_percent'
}

drive_test_result() {
  value=$(smartctl --json -a $1 | jq -r '.ata_smart_data.self_test.status.value')
  passed=$(smartctl --json -a $1 | jq -r '.ata_smart_data.self_test.status.passed')
  if [ $value == 0 ] && [ $passed == 'true' ]; then
    return 0
  else
    return 1
  fi
}

drive_folder_name() {
  type=$(drive_type $1)
  size_number=$(drive_size $1 | awk '{print $1}')
  size_unit=$(drive_size $1 | awk '{print $2}')
  vendor=$(drive_vendor $1)
  model_family=$(drive_model_family $1 | awk '{print $1}')
  serial=$(drive_serial $1)

  path="$type-$size_unit"'_'"$size_number-$vendor-$model_family-$serial"

  echo $path | sed "s|/|-|g" | sed "s|--|-|g"
}

drive_folder_path() {
  echo "$OUTPUT_PATH/"$(drive_folder_name $1)
}

prepare_drive_folder() {
  mkdir -p $(drive_folder_path $1)
}

extract_speed_from_dd() {
  echo ${1^^} \
    | tail -n 1 \
    | awk -F', ' '{ print $4 }' \
    | sed "s| ||g" \
    | sed "s|B/S||g" \
    | numfmt --from=si
}
