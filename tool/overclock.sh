#!/bin/bash

source "/root/mrminer/lib/functions.sh"
updateconfig


if [ "$DRIVER" == "AMD" ]; then

    IFS=',' read -r -a CoreArray <<< "$CORE"
    IFS=',' read -r -a MemArray <<< "$MEMORY"

    x=0;
    while [ $x -le 14 ]; do
        if [ -e "/sys/class/drm/card$x/device/pp_table" ]; then

            cp /var/tmp/pp_tables/gpu$x/pp_table /sys/class/drm/card$x/device/pp_table
            sleep 0.2
            echo manual > /sys/class/drm/card$x/device/power_dpm_force_performance_level
            mem_states=`cat /sys/class/drm/card$x/device/pp_dpm_mclk | wc -l`
            MEMSTATE=$(($mem_states-1))

            if [ ! -z "${CoreArray[$x]}" ] && [ ! -z "${MemArray[$x]}" ]; then
                sudo /root/mrminer/tool/ohgodatool -i $x --core-state $POWER --mem-state $MEMSTATE --core-clock ${CoreArray[$x]} --mem-clock ${MemArray[$x]} --volt-state $POWER --vddc-table-set $VOLT
            else
                sudo /root/mrminer/tool/ohgodatool -i $x --core-state $POWER --mem-state $MEMSTATE --core-clock $CORE --mem-clock $MEMORY --volt-state $POWER --vddc-table-set $VOLT
            fi

            sleep 0.2
            echo $POWER > /sys/class/drm/card$x/device/pp_dpm_sclk
            echo $MEMSTATE > /sys/class/drm/card$x/device/pp_dpm_mclk

        fi
        x=$[x + 1]
    done

elif [ "$DRIVER" == "NVIDIA" ]; then

  IFS=',' read -r -a CoreArray <<< "$CORE"
  IFS=',' read -r -a MemArray <<< "$MEMORY"

  sudo xinit /root/mrminer/tool/overclock_nvidia.sh $CoreArray $MemArray $POWER -- :0 -once -config /etc/X11/xorg.conf &

fi
