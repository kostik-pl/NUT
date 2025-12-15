#!/bin/sh
vim-cmd hostsvc/autostartmanager/autostop
sleep 60
poweroff
