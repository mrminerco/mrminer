#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

sudo -H -u mrminer /root/mrminer/boot/prepare.sh &
#su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &
