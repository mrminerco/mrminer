#!/bin/bash

if sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git remote update; then

  Local=$(sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git rev-list --max-count=1 master)
  Origin=$(sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git rev-list --max-count=1 origin/master)

  if [ "$Local" != "$Origin" ]; then
      sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git checkout -- .
      sleep 0.5
      sudo git --work-tree=/root/mrminer --git-dir=/root/mrminer/.git pull origin master
      sync
      #rsync -q --dry-run /root/mrminer/root/ /
      sudo chmod -R +x /root/mrminer
  fi
fi
