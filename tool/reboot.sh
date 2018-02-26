#!/bin/bash
source "/root/mrminer/lib/functions.sh"

curl -k -d api="$API" -d email="$EMAIL" $URL/watchdog

sleep 3

sudo echo 1 > /proc/sys/kernel/sysrq
sudo echo b > /proc/sysrq-trigger

## reboot log --> api'ye gönderilecek
