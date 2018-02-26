#!/bin/bash

source "/root/mrminer/lib/functions.sh"
updateconfig

x=0;
while [ $x -le 14 ]; do
    if [ -e "/sys/class/drm/card$x/device/pp_table" ]; then

        cp /var/tmp/pp_tables/gpu$x/pp_table /sys/class/drm/card$x/device/pp_table
        sleep 0.2
        echo manual > /sys/class/drm/card$x/device/power_dpm_force_performance_level
        mem_states=`cat /sys/class/drm/card$x/device/pp_dpm_mclk | wc -l`
        MEMSTATE=$(($mem_states-1))
        sudo /root/mrminer/tool/ohgodatool -i $x --core-state $POWER --mem-state $MEMSTATE --core-clock $CORE --mem-clock $MEMORY --volt-state $POWER --vddc-table-set $VOLT
        sleep 0.2
        echo $POWER > /sys/class/drm/card$x/device/pp_dpm_sclk
        echo $MEMSTATE > /sys/class/drm/card$x/device/pp_dpm_mclk

    fi
    x=$[x + 1]
done
