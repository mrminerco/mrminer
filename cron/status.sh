#!/bin/bash
source "/root/mrminer/lib/functions.sh"
# Get Stats
STATS=$(sudo /root/mrminer/tool/stats.sh)

# Send Stats
sleep 1
curl -k -d api="$API" -d email="$EMAIL" -d stats="$STATS" $URL/stats
