#!/bin/bash

cd /root/mrminer

if sudo git remote update; then

  local=$(sudo git rev-list --max-count=1 master)
  origin=$(sudo git rev-list --max-count=1 origin/master)

  if [ "$local" != "$origin" ]; then
      sudo git pull origin master
      sudo sync
  fi

fi
