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
    echo -e "\r\nRunning drive wiping script\r\n"
    yes | bash $(dirname $0)/wipe.sh $drives

    echo -e "\r\n\r\n\r\nRunning S.M.A.R.T. testing script\r\n"
    yes | bash $(dirname $0)/smart.sh $drives

    echo -e "\r\n\r\n\r\nRunning performance testing script\r\n"
    yes | bash $(dirname $0)/performance.sh $drives

    echo -e "\r\n\r\n\r\nFinished"
  else
    echo 'Not touching any drives & exiting…'
    exit
  fi
else
  echo 'Not touching any drives & exiting…'
  exit
fi
