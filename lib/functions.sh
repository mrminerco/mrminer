#!/bin/bash

# Basic Config
function settings()
{
	DRIVER_AMD=$(lsmod | grep amdgpu | wc -l)
	DRIVER_NVIDIA=$(lsmod | grep nvidia | wc -l)

	if [ $DRIVER_AMD -gt 0 ]; then
		DRIVER=AMD
	elif [ $DRIVER_NVIDIA -gt 0 ]; then
		DRIVER=NVIDIA
	fi
	VERSION=0.51
	URL="https://mrminer.co/api"
	MAC=$(sudo ifconfig | grep -ioE '([a-z0-9]{2}:){5}..' | sed 's/://g' | sha256sum)
	SERIAL=$(sudo dmidecode -s system-uuid | sed 's/-//g' | sha256sum)
	API=$(echo $MAC.$SERIAL | sha256sum | awk '{print substr($0,16,32);exit}')
	EMAIL=$(sudo cat /mnt/usb/config.txt | grep EMAIL | head -n1 | cut -d = -f 2 | cut -d ' ' -f 1 | tr '[:upper:]' '[:lower:]' | tr -d '\r')
}
settings

# Boot Start
function boot()
{
	sudo timedatectl set-timezone UTC
	sudo rm -rf /home/mrminer/.cache/sessions/*
	sudo rm -rf /etc/udev/rules.d/70-persistent-net.rules
	sudo rm -rf /etc/X11/xorg.conf
	backup_oc_table
	backup_miner
	settings
#	enable_wol
}

# Update Config
function updateconfig()
{
	CONFIG=$(sudo cat /home/mrminer/config.json)
	MINER=$(echo $CONFIG | jq -r .miner)
	FOLDER=$(echo $CONFIG | jq -r .path)
	COMMAND=$(echo $CONFIG | jq -r .config)
	CORE=$(echo $CONFIG | jq -r .core)
	MEMORY=$(echo $CONFIG | jq -r .memory)
	POWER=$(echo $CONFIG | jq -r .power)
	VOLT=$(echo $CONFIG | jq -r .volt)
	TEMP=$(echo $CONFIG | jq -r .temp)
	FAN=$(echo $CONFIG | jq -r .fan)
	CONFIGNAME=$(echo $CONFIG | jq -r .configname)
	DIR=$(dirname $FOLDER)
}
updateconfig

# Internet Test
function connection_test()
{
	if nc -zw3 -i2 google.com 80; then
        return 0
	else
        return 1
	fi
}

# Update Check
function update_check()
{
	sudo /root/mrminer/cron/update.sh > /dev/null 2>&1 &
	return 0
}

# Update
function update()
{
	sudo /root/mrminer/cron/update.sh > /dev/null 2>&1 &
	return 0
}

# Register
function register()
{
	REGISTER=`sudo curl -k -s -d api="$API" -d email="$EMAIL" -d version="$VERSION" $URL/register`
	STATUS=`echo "$REGISTER" | jq -r .status`

	if [ -n "$STATUS" ]
	then
		if [ "$STATUS" == "ok" ]; then
			return 0
		else
			return 1
		fi
	fi
}

# Config Download
function getConfig()
{
	GETCONFIG=`sudo curl -k -s -d api="$API" -d email="$EMAIL" $URL/getconfig`
	STATUS=`echo "$GETCONFIG" | jq -r .status`

	if [ "$STATUS" == "ok" ]; then
	    echo "$GETCONFIG" | sudo tee /home/mrminer/config.json > /dev/null 2>&1
	    sync
			updateconfig
	    return 0
	else
	    return 1
	fi
}
# Overclock
function overclock()
{
    sudo /root/mrminer/tool/overclock.sh > /dev/null 2>&1 &
    return 0
}

# Fan Speed
function fanspeed()
{

	return 0
}

# Miner Backup
function backup_miner()
{
	sudo rm -Rf /root/miner
	sudo rm -Rf /var/tmp/miner/
	sudo cp -Rp /root/mrminer/miners /var/tmp/miner/
	sleep 0.5
	sudo ln -s /var/tmp/miner /root/miner
	return 0
}

# Backup OC Table
function backup_oc_table()
{
	if [ "$DRIVER" == "AMD" ]; then

		sudo rm -rf /var/tmp/pp_tables && sleep 0.5 && sync && sudo mkdir /var/tmp/pp_tables
		x=0
		while [ $x -le 14 ]; do
		    if [ -e "/sys/class/drm/card$x/device/pp_table" ]
		    then
		        sudo mkdir /var/tmp/pp_tables/gpu$x
		        sudo cp /sys/class/drm/card$x/device/pp_table /var/tmp/pp_tables/gpu$x/pp_table
				sync
		    fi
		    x=$[x + 1]
		done

	fi
}

# Text Color
function text()
{
  local color=${1}
  shift
  local text="${@}"
  case ${color} in
    red    ) tput setaf 1 ; tput bold ;;
    green  ) tput setaf 2 ; tput bold ;;
    yellow ) tput setaf 3 ; tput bold ;;
    blue   ) tput setaf 4 ; tput bold ;;
    purple ) tput setaf 5 ; tput bold ;;
		cyan 	 ) tput setaf 6 ; tput bold ;;
		white  ) tput setaf 7 ; tput bold ;;
  esac
  echo -en "${text}"
  tput sgr0
}

# Logo
function logo()
{
	sudo cat /root/mrminer/lib/logo.sh
}
# Hardware Status
function get_hardware()
{
	sudo /root/mrminer/cron/hardware_status.sh > /dev/null 2>&1 &
}
# Enable WOL
function enable_wol()
{
	sudo ethtool -s eth0 wol g > /dev/null 2>&1 &
}

# Wallet
function wallet()
{
	WALLET=$(cat /home/mrminer/config.json | jq -r .config)
	sudo curl -k -s -d api="$API" -d email="$EMAIL" -d wallet="$WALLET" $URL/sendwallet
}
