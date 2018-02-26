#!/bin/sh

while true; do
  sleep 4
  sudo /root/mrminer/cron/status.sh
  sleep 4
  sudo /root/mrminer/cron/command.sh
done
