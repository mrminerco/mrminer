#!/bin/bash

cd /root/mrminer

if git remote update; then

  local=$(git rev-list --max-count=1 master)
  origin=$(git rev-list --max-count=1 origin/master)

  if [ "$local" != "$origin" ]; then
      git pull origin master
      sync
  fi

fi
