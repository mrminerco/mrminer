#!/bin/bash

source "/root/mrminer/lib/functions.sh"
updateconfig


if [ "$DRIVER" == "AMD" ]; then

    IFS=',' read -r -a CoreArray <<< "$CORE"
    IFS=',' read -r -a MemArray <<< "$MEMORY"

    i=0;
  	GPU_COUNT=$(ls -1 /sys/class/drm/card*/device/hwmon/hwmon*/pwm1 | wc -l)
  	while [ $i -le $GPU_COUNT ]; do
        if [ -e "/sys/class/drm/card$i/device/pp_table" ]; then

            cp /var/tmp/pp_tables/gpu$i/pp_table /sys/class/drm/card$i/device/pp_table
            sleep 0.2
            echo manual > /sys/class/drm/card$i/device/power_dpm_force_performance_level
            mem_states=`cat /sys/class/drm/card$i/device/pp_dpm_mclk | wc -l`
            MEMSTATE=$(($mem_states-1))

            if [ ! -z "${CoreArray[$i]}" ] && [ ! -z "${MemArray[$i]}" ]; then
                sudo /root/mrminer/tool/ohgodatool -i $i --core-state $POWER --mem-state $MEMSTATE --core-clock ${CoreArray[$i]} --mem-clock ${MemArray[$i]} --volt-state $POWER --vddc-table-set $VOLT
            else
                sudo /root/mrminer/tool/ohgodatool -i $i --core-state $POWER --mem-state $MEMSTATE --core-clock $CORE --mem-clock $MEMORY --volt-state $POWER --vddc-table-set $VOLT
            fi

            sleep 0.2
            echo $POWER > /sys/class/drm/card$i/device/pp_dpm_sclk
            echo $MEMSTATE > /sys/class/drm/card$i/device/pp_dpm_mclk

        fi
        i=$[i + 1]
    done

elif [ "$DRIVER" == "NVIDIA" ]; then

  IFS=',' read -r -a CoreArray <<< "$CORE"
  IFS=',' read -r -a MemArray <<< "$MEMORY"

  sudo xinit /root/mrminer/tool/overclock_nvidia.sh $CoreArray $MemArray $POWER -- :0 -once -config /etc/X11/xorg.conf &

fi
