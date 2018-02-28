#!/bin/bash

source "/root/mrminer/lib/functions.sh"
updateconfig

if [ "$DRIVER" == "AMD" ]; then

    GPU_COUNT=$(ls -1 /sys/class/drm/card*/device/hwmon/hwmon*/pwm1 | wc -l)
    IFS=',' read -r -a Cores <<< "$CORE"
    IFS=',' read -r -a Mems <<< "$MEMORY"

    # Fix rest of values
    [ -n "$Cores" ] &&
    for (( x=${#Cores[@]}; x < $GPU_COUNT; ++x )); do
    	Cores[$x]=${Cores[$x-1]}
    done
    [ -n "$Mems" ] &&
    for (( x=${#Mems[@]}; x < $GPU_COUNT; ++x )); do
    	Mems[$x]=${Mems[$x-1]}
    done

    # Overclock Loop
    i=0
    CARDS=$(ls -d1 /sys/class/drm/card*/device/pp_table | grep -Poi "(\d+)" | xargs)
    for ID in $CARDS; do

      parameters=''
      cp /var/tmp/pp_tables/gpu$ID/pp_table /sys/class/drm/card$ID/device/pp_table && sleep 0.2
      echo manual > /sys/class/drm/card$ID/device/power_dpm_force_performance_level
      MEMSTATE=$(/root/mrminer/tool/ohgodatool -i $ID --show-mem | grep -o -P "Memory state [0-9]" | grep -o "[[:digit:]]" | tail -n 1)

      if [ -n "${Cores[$i]}" ] && [ "${Cores[$i]}" -ge "300" ] && [ "${Cores[$i]}" -le "1600" ]; then
          parameters+=" --core-state $POWER --core-clock ${Cores[$i]}"
      fi
      if [ -n "${Mems[$i]}" ] && [ "${Mems[$i]}" -ge "300" ] && [ "${Mems[$i]}" -le "3000" ]; then
          parameters+=" --mem-state $MEMSTATE --mem-clock ${Mems[$i]}"
      fi
      if [ "$VOLT" -ge "800" ] && [ "$VOLT" -le "1300" ]; then
          parameters+=" --volt-state $POWER --vddc-table-set $VOLT"
      fi

      [ -n "$parameters" ] && sudo /root/mrminer/tool/ohgodatool -i $ID $parameters
      [ -n "$POWER" ] && echo $POWER > /sys/class/drm/card$ID/device/pp_dpm_sclk
      [ -n "$MEMSTATE" ] && echo $MEMSTATE > /sys/class/drm/card$ID/device/pp_dpm_mclk

      i=$[i + 1]

    done

elif [ "$DRIVER" == "NVIDIA" ]; then

  IFS=',' read -r -a CoreArray <<< "$CORE"
  IFS=',' read -r -a MemArray <<< "$MEMORY"

  sudo xinit /root/mrminer/tool/overclock_nvidia.sh $CoreArray $MemArray $POWER -- :0 -once -config /etc/X11/xorg.conf &

fi
