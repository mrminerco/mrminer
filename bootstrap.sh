#!/bin/bash
source "/root/mrminer/lib/functions.sh"

boot

<<<<<<< HEAD
sudo -H -u mrminer /root/mrminer/boot/prepare.sh &
#su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &
=======
su mrminer -c 'bash /root/mrminer/boot/prepare.sh' &
>>>>>>> ef77ff7b40e0f66cf98bbfc466627e5533f1a211
