#!/bin/bash

LAN_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

WAN_IP=$(curl ifconfig.me)

UPTIME=$(uptime -s)

KERNEL_VERSION=$(uname -r)

# MRMINER_VERSION=$(cat /home/mrminer/version)

DRIVER_AMD=$(lsmod | grep amd | wc -l)
DRIVER_NVIDIA=$(lsmod | grep nvidia | wc -l)

if [ $DRIVER_AMD -gt 0 ]; then
	DRIVER=AMD
	DRIVER_VERSION=$(sudo dpkg-query --showformat='${Version}' --show amdgpu-pro-core)
elif [ $DRIVER_NVIDIA -gt 0 ]; then
	DRIVER=NVIDIA
	DRIVER_VERSION=$(sudo dpkg-query --showformat='${Version}' --show nvidia-390)
fi


MOBO_BRAND=$(sudo dmidecode -s baseboard-manufacturer)
MOBO_MODEL=$(sudo dmidecode -s baseboard-product-name)

CPU=$(sudo dmidecode -s processor-version)

RAM_SIZE=$(sudo dmidecode -t memory | grep "Size:" | grep -v "No" | cut -b 8-)
RAM_TYPE=$(sudo dmidecode -t memory | grep "DDR" | cut -b 8-)

HDD=$(sudo lshw -C disk -short | tail -n +3 | head -n 1 | awk '{$1=$2=$3=""}1' | cut -d\  -f4-)

SLOT=$(sudo dmidecode -t slot | grep "Designation:" | cut -b 15- | awk '{printf("%s ", $NF)}')


if [ "$DRIVER" == "AMD" ]; then

	GPUS=$(/root/mrminer/tool/amdmeminfo -s -o -q | tr '\n' ',' | sed 's/.$//')
	GPU_COUNT=$(ls -1 /sys/class/drm/card*/device/hwmon/hwmon*/pwm1 | wc -l)

elif [ "$DRIVER" == "NVIDIA" ]; then

	GPUS=$(nvidia-smi -L | tr '\n' ',')
	GPU_COUNT=$(nvidia-smi -L | wc -l)

fi

HARDWARE={}

HARDWARE=`echo "$HARDWARE" | jq ".lan_ip=\"$LAN_IP\""`
HARDWARE=`echo "$HARDWARE" | jq ".uptime=\"$UPTIME\""`
HARDWARE=`echo "$HARDWARE" | jq ".kernel_version=\"$KERNEL_VERSION\""`
HARDWARE=`echo "$HARDWARE" | jq ".driver_version=\"$DRIVER_VERSION\""`
HARDWARE=`echo "$HARDWARE" | jq ".mobo=\"$MOBO_BRAND $MOBO_MODEL\""`
HARDWARE=`echo "$HARDWARE" | jq ".cpu=\"$CPU\""`
HARDWARE=`echo "$HARDWARE" | jq ".ram=\"$RAM_SIZE $RAM_TYPE\""`
HARDWARE=`echo "$HARDWARE" | jq ".hdd=\"$HDD\""`
HARDWARE=`echo "$HARDWARE" | jq ".slot=\"$SLOT\""`
HARDWARE=`echo "$HARDWARE" | jq ".gpus=\"$GPUS\""`
HARDWARE=`echo "$HARDWARE" | jq ".gpu_count=\"$GPU_COUNT\""`

echo $HARDWARE
