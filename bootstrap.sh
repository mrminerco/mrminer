#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

su miner -c 'bash /root/mrminer/boot/prepare.sh' &
