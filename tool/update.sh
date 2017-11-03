#!/bin/bash


if sudo sh -c 'git remote update'; then

  local=$(sudo sh -c 'cd /root/mrminer && sudo git rev-list --max-count=1 master')
  origin=$(sudo sh -c 'cd /root/mrminer && sudo git rev-list --max-count=1 origin/master')

  if [ "$local" != "$origin" ]; then
      sudo sh -c 'cd /root/mrminer && sudo git pull origin master'
      sync
  fi
fi
