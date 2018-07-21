#!/bin/bash

sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git checkout -- .

if sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git remote update; then

  Local=$(sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git rev-list --max-count=1 master)
  Origin=$(sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git rev-list --max-count=1 origin/master)

  if [ "$Local" != "$Origin" ]; then
      sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git checkout -- .
      sleep 0.5
      sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git pull origin master
      sync
      rsync -aqrz --no-perms --no-owner  /root/mrminer/root/etc/crontab /etc/crontab
      rsync -aqrz --no-perms --no-owner  /root/mrminer/root/etc/rc.local /etc/rc.local
      sync
      sudo chmod -R +x /root/mrminer
  fi
fi
