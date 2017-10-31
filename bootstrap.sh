#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

su mrminer -c 'sudo /root/mrminer/boot/prepare.sh' &
