#!/usr/bin/env bash

source "$(dirname $0)/variables.sh"
source "$(dirname $0)/utilities.sh"
source "$(dirname $0)/check.sh"

drives=$@
number_of_drives=$#

echo "This will wipe the drives ($number_of_drives total: \`$drives\`)!"
read -p $'Do you want to continue? [Y/n]\n' continue
if [[ "$continue" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  read -p $'Really? [Y/n]\r\n' really
  if [[ "$really" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    yes | bash $(dirname $0)/wipe.sh $drives
    yes | bash $(dirname $0)/smart.sh $drives
    yes | bash $(dirname $0)/performance.sh $drives

    echo "Finished."
  else
    echo 'Not touching any drives & exiting…'
    exit
  fi
else
  echo 'Not touching any drives & exiting…'
  exit
fi
