#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

if [ "$DRIVER" == "AMD" ]; then

	su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &

elif [ "$DRIVER" == "NVIDIA" ]; then

	sudo nvidia-xconfig -s -a --force-generate --allow-empty-initial-configuration --cool-bits=31 --registry-dwords="PerfLevelSrc=0x2222" --no-sli --connected-monitor="DFP-0"
	sudo sed -i '/Driver/a \ \ \ \ Option         "Interactive" "False"' /etc/X11/xorg.conf

	sleep 1

	su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &

else

	su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &

fi
