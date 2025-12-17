#!/bin/bash

# FILE: /usr/local/ups/etc/ups_flag_check.sh
# Purpose: CMDSCRIPT for upssched. Routes command arguments.

case "$1" in
    ONLINE)
        # This is optional, but ensures system reset on power return
        /usr/local/ups/etc/ups_online_init.sh
        ;;
    charge_monitor)
        # Command 3: Called by upssched timer to restart the check cycle
        /usr/local/ups/etc/ups_battery_check.sh
        ;;
    startshutdown)
        # Command 1: Executes ESXi shutdown sequence (Called via AT low_charge)
        /usr/local/ups/etc/ups_shutdown_init.sh
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac
