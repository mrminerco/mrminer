#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &
