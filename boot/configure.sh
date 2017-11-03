#!/bin/bash
source "/root/mrminer/lib/functions.sh"

# Starting
text green "############################################################################\n"

logo

text green "############################################################################\n\n"

text yellow "Configuration \n\n"

########################################################
# Task 1: Connection
function task1()
{
	printf "[   ] Connection Test \r"
	sleep 0.1
	if connection_test; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Connection Test"
	else
		printf "[ %s ] Connection Testing... Failed! \n\n" $(text red "FAIL")
		echo -ne '\n'
	fi
}
########################################################
# Task 2: Update
function task2()
{
	printf "[   ] Update Check \r"
	sleep 0.1
	if update_check; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Update Check"
	else
		printf "[ %s ] %s \n\n" $(text red "FAIL") "Update Check"
	fi
}
########################################################
# Task 3: Register
function task3()
{
	printf "[   ] Server Registration \r"
	sleep 0.1
	if register; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Server Registration"
	else
		printf "[ %s ] Registering... Failed! \n\n" $(text red "FAIL")
	fi
}

########################################################
# Task 4: Config
function task4()
{
	printf "[   ] Config Download \r"
	sleep 0.1
	if config; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Config Download"
	else
		printf "[ %s ] Config Downloading... Failed! \n\n" $(text red "FAIL")
	fi
}

########################################################
# Task 5: Overclock
function task5()
{
	printf "[   ] GPU Overclock. \r"
	sleep 0.1
	if overclock; then
		printf "[ %s ] %s \n\n" $(text green "OK") "GPU Overclock"
	else
		printf "[ %s ] GPU Overclocking... Failed! \n\n" $(text red "FAIL")
	fi
}
########################################################
# Task 6: Fan Speed
function task6()
{
	printf "[   ] Fan Speed \r"
	sleep 0.1
	if fanspeed; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Fan Speed"

		sudo /root/mrminer/tool/fanspeed.sh &

	else
		printf "[ %s ] Fan Speed Setting... Failed! \n\n" $(text red "FAIL")
	fi
}
########################################################
# Task 7: Miner Configure

function task7()
{
	printf "[   ] Miner Configuration \r"
	sleep 0.1
	if backup_miner; then
		printf "[ %s ] %s \n\n" $(text green "OK") "Miner Configuration"
	else
		printf "[ %s ] Miner Configuring... Failed! \n\n" $(text red "FAIL")
	fi
}

####################### OUTPUT

task1
sleep 0.5
task2
sleep 0.5
task3
sleep 0.5
task4
sleep 0.5
task5
sleep 0.5
task6

printf "Manage your rig by logging into %s with your e-mail: %s\n\n" $(text yellow "mrminer.co") $(text yellow "$EMAIL")

text green "############################################################################\n\n"

text yellow "Miner Settings \n\n"
updateconfig
sleep 1

printf "%-15s : %s \n" "Core Mhz" $(text yellow "$CORE")
printf "%-15s : %s \n" "Memory Mhz" $(text yellow "$MEMORY")
printf "%-15s : %s \n" "Power Stage" $(text yellow "$POWER")
printf "%-15s : %s%s \n" "Volt Stage" $(text yellow "$VOLT") $(text yellow "V")
printf "%-15s : %s \n" "Target Temp" $(text yellow "$TEMP°C")
printf "%-15s : %s \n\n" "Min Fan Speed" $(text yellow "%$FAN")

text green "############################################################################\n\n"

hardware

echo $CONFIGNAME
echo $COMMAND

while true; do

    cd $DIR

    if [ "$FOLDER" != "null" ]; then
        $FOLDER $COMMAND
        echo "Exiting... "
        sleep 5
    else
        echo "Restart miner for download the config"
        sleep 5
    fi

done

echo "Configure Bash File Failed"
sleep 99999999999
