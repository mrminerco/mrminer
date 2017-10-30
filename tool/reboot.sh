#!/bin/bash

sudo echo 1 > /proc/sys/kernel/sysrq
sudo echo b > /proc/sysrq-trigger

## reboot log --> api'ye gönderilecek