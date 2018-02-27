#!/bin/bash
source "/root/mrminer/lib/functions.sh"

STATS='{}'

## MINER HASHRATE
if [ "$MINER" == "claymoreeth" ]; then
	CLAYMORE=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | nc localhost 3333`
	HASH=`echo "$CLAYMORE" | jq -r .result[2] | cut -d ';' -f 1`
	GPU_HASH=`echo "$CLAYMORE" | jq -r .result[3]`
	HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[4] | cut -d ';' -f 1`
	GPU_HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[5]`
	HASH_UNIT="MH"

elif [ "$MINER" == "claymorezec" ]; then
	CLAYMORE=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | nc localhost 3333`
	HASH=`echo "$CLAYMORE" | jq -r .result[2] | cut -d ';' -f 1`
	GPU_HASH=`echo "$CLAYMORE" | jq -r .result[3]`
	HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[4] | cut -d ';' -f 1`
	GPU_HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[5]`
	HASH_UNIT="H"

elif [ "$MINER" == "claymorexmr" ]; then
	CLAYMORE=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | nc localhost 3333`
	HASH=`echo "$CLAYMORE" | jq -r .result[2] | cut -d ';' -f 1`
	GPU_HASH=`echo "$CLAYMORE" | jq -r .result[3]`
	HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[4] | cut -d ';' -f 1`
	GPU_HASH_DUAL=`echo "$CLAYMORE" | jq -r .result[5]`
	HASH_UNIT="H"

elif [ "$MINER" == "optiminer" ]; then
	OPTIMINER=$(curl -k -s localhost:3333)
	HASH=$(echo "$OPTIMINER" | jq '.solution_rate | .Total | .["5s"]')
	GPU_HASH=$(echo "$OPTIMINER" | jq '.solution_rate | .[] | ."5s"' | sed '$d' | tr '\n' ';' | sed 's/.$//')
	HASH_DUAL=""
	GPU_HASH_DUAL=""
	HASH_UNIT="H"

elif [ "$MINER" == "ethminer" ]; then
	ETHMINER=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | socat stdio tcp-connect:127.0.0.1:3333`
	HASH=`echo "$ETHMINER" | jq -r .result[2] | cut -d ';' -f 1`
	GPU_HASH=`echo "$ETHMINER" | jq -r .result[3]`
	HASH_DUAL=`echo "$ETHMINER" | jq -r .result[4] | cut -d ';' -f 1`
	GPU_HASH_DUAL=`echo "$ETHMINER" | jq -r .result[5]`
	HASH_UNIT="MH"

elif [ "$MINER" == "ccminer" ]; then
	CCMINER=`echo "summary" | nc localhost 4068`
	CCMINERGPU=`echo "threads" | nc localhost 4068`
	HASH=`echo $CCMINER | grep -o -P ';KHS=(\d+\.\d+)' | cut -c6-`
	GPU_HASH=`echo $CCMINERGPU | tr '|' '\n' | grep -o -P 'KHS=(\d+\.\d+)' | cut -c5- | tr '\n' ';'`
	HASH_DUAL=""
	GPU_HASH_DUAL=""
	HASH_UNIT="KH"
	# HASH=`echo $CCMINER | grep -o -P ';KHS.{0,5}' | cut -c6- | awk '{print $1*1000}'`

elif [ "$MINER" == "ewbf" ]; then
	EWBF=`echo '{"id":1, "method":"getstat"}' | nc localhost 42000`
	HASH=`echo $EWBF | jq '.result | .[] | ."speed_sps"' | awk '{s+=$1} END {print s}'`
	GPU_HASH=`echo $EWBF | jq '.result | .[] | ."speed_sps"' | tr '\n' ';'`
	HASH_DUAL=""
	GPU_HASH_DUAL=""
	HASH_UNIT="H"

elif [ "$MINER" == "zm" ]; then
	ZM=`echo '{"id":1, "method":"getstat"}' | nc localhost 2222`
	HASH=`echo $ZM | jq '.result | .[] | ."sol_ps"' | awk '{s+=$1} END {print s}'`
	GPU_HASH=`echo $ZM | jq '.result | .[] | ."sol_ps"' | tr '\n' ';'`
	HASH_DUAL=""
	GPU_HASH_DUAL=""
	HASH_UNIT="H"


elif [ "$MINER" == "bminer" ]; then
	BMINER=`curl 127.0.0.1:1880/api/status`
	HASH=`echo $BMINER | jq '.miners | .[] | ."solver" | ."solution_rate"' | awk '{s+=$1} END {print s}'`
	GPU_HASH=`echo $BMINER | jq '.miners | .[] | ."solver" | ."solution_rate"' | tr '\n' ';'`
	HASH_DUAL=""
	GPU_HASH_DUAL=""
	HASH_UNIT="H"

fi

STATS=`echo "$STATS" | jq ".total_hash=\"$HASH\""`
STATS=`echo "$STATS" | jq ".total_hash_dual=\"$HASH_DUAL\""`
STATS=`echo "$STATS" | jq ".gpu_hash=\"$GPU_HASH\""`
STATS=`echo "$STATS" | jq ".gpu_hash_dual=\"$GPU_HASH_DUAL\""`
STATS=`echo "$STATS" | jq ".hash_unit=\"$HASH_UNIT\""`

if [ "$DRIVER" == "AMD" ]; then

	## GPU STATS
	x=0;
	while [ $x -le 14 ]; do
	    if [ -e "/sys/class/drm/card$x/device/pp_table" ]; then
	    	STATS=`echo "$STATS" | jq ".core += \"$(cat /sys/class/drm/card$x/device/pp_dpm_sclk  | grep "*" | awk '{print $2}' | tr -d 'Mhz');\""`
	    	STATS=`echo "$STATS" | jq ".mem += \"$(cat /sys/class/drm/card$x/device/pp_dpm_mclk  | grep "*" | awk '{print $2}' | tr -d 'Mhz');\""`
	    	STATS=`echo "$STATS" | jq ".temp += \"$(sudo /root/mrminer/tool/ohgodatool --show-temp -i $x | tr -d 'C');\""`
	    	STATS=`echo "$STATS" | jq ".fan += \"$(sudo /root/mrminer/tool/ohgodatool --show-fanspeed -i $x | tr -d '%');\""`
	      	STATS=`echo "$STATS" | jq ".watt += \"$(cat /sys/kernel/debug/dri/$x/amdgpu_pm_info | grep "average GPU" | cut -b 2-9 | tr -d ' W');\""`
	    fi
	    x=$[x + 1]
	done


elif [ "$DRIVER" == "NVIDIA" ]; then

	## GPU STATS
	x=0;
	GPU_COUNT=$(nvidia-smi -L | wc -l)
	while [ $x -lt $GPU_COUNT ]; do
    	STATS=`echo "$STATS" | jq ".core += \"$(nvidia-smi -i $x --format=noheader,csv --query-gpu=clocks.gr | tr -d ' MHz');\""`
    	STATS=`echo "$STATS" | jq ".mem += \"$(nvidia-smi -i $x --format=noheader,csv --query-gpu=clocks.mem | tr -d ' MHz');\""`
    	STATS=`echo "$STATS" | jq ".temp += \"$(nvidia-smi -i $x --format=noheader,csv --query-gpu=temperature.gpu);\""`
    	STATS=`echo "$STATS" | jq ".fan += \"$(nvidia-smi -i $x --format=noheader,csv --query-gpu=fan.speed | tr -d ' %');\""`
      	STATS=`echo "$STATS" | jq ".watt += \"$(nvidia-smi -i $x --format=noheader,csv --query-gpu=power.draw | tr -d ' W');\""`
	    x=$[x + 1]
	done

fi


echo $STATS
