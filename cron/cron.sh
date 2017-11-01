#!/bin/sh

while true; do

  sudo /root/mrminer/cron/status.sh
  sudo /root/mrminer/cron/command.sh
  sleep 10

done
