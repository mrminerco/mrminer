#!/bin/bash
source "/root/mrminer/lib/functions.sh"

# Get Stats
HARDWARE=$(sudo /root/mrminer/tool/hardware.sh)

# Send Stats
sleep 1
curl -k -d api="$API" -d email="$EMAIL" -d hardware="$HARDWARE" $URL/hardware
