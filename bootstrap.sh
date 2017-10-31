#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

sudo -u mrminer -s sh -c '/root/mrminer/boot/prepare.sh' &
#sudo -u mrminer /root/mrminer/boot/prepare.sh &
