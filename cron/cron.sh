#!/bin/sh

while true; do

  sleep 4.5
  sudo /root/mrminer/cron/status.sh
  sleep 5.5
  sudo /root/mrminer/cron/command.sh

done
