#!/bin/bash

source "/root/mrminer/lib/settings.txt"
source "/root/mrminer/lib/functions.sh"

while true; do

    cd $DIR

    if [ $FOLDER != "null" ]; then
        $FOLDER $COMMAND
        echo "Problem..."
        sleep 5
    else
        echo "Restart miner for download the config"
        sleep 5
    fi

done

