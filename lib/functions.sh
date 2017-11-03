#!/bin/bash

# Functions
function boot()
{
	sudo rm -rf /home/mrminer/.cache/sessions/*
	sudo rm -rf /etc/udev/rules.d/70-persistent-net.rules
	backup_oc_table
	backup_miner
	config
}

# Basic Config
function config()
{
	VERSION=0.51
	URL="https://mrminer.co/api"
	MAC=$(sudo ifconfig | grep eth0 | awk '{print $NF}' | sed 's/://g' | sha256sum)
	SERIAL=$(sudo dmidecode -s system-uuid | sed 's/-//g' | sha256sum)
	API=$(echo $MAC.$SERIAL | sha256sum | awk '{print substr($0,16,32);exit}')
	EMAIL=$(sudo cat /mnt/usb/config.txt | grep EMAIL | head -n1 | cut -d = -f 2 | cut -d ' ' -f 1 | tr '[:upper:]' '[:lower:]' | tr -d '\r')
}

config
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
	#sudo /root/mrminer/tool/update.sh > /dev/null 2>&1 &
	return 0
}

# Update
function update()
{
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
function config()
{
	GETCONFIG=`sudo curl -k -s -d api="$API" -d email="$EMAIL" $URL/getconfig`
	STATUS=`echo "$GETCONFIG" | jq -r .status`

	if [ "$STATUS" == "ok" ]; then
	    echo "$GETCONFIG" | sudo tee /home/mrminer/config.json > /dev/null 2>&1
	    sync
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
	x=0
	while [ $x -le 14 ]; do
	    if [ -e "/sys/class/drm/card$x/device/pp_table" ]
	    then
	        mkdir /var/tmp/pp_tables
	        mkdir /var/tmp/pp_tables/gpu$x
	        cp /sys/class/drm/card$x/device/pp_table /var/tmp/pp_tables/gpu$x/pp_table
	    fi
	    x=$[x + 1]
	done
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
    grey   ) tput setaf 5 ; tput bold ;;
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
function hardware()
{
	sudo /root/mrminer/cron/hardware_status.sh > /dev/null 2>&1 &
}
