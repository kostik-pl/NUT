#!/bin/bash
# Router script for upssched events
case "$1" in
  onbatt)
    # Forwarding to monitor script with consistent uppercase argument
    /usr/local/ups/etc/ups_battery_monitor.sh ONBATT
    ;;
  online)
    /usr/local/ups/etc/ups_battery_monitor.sh ONLINE
    ;;
  lowbatt)
    /usr/local/ups/etc/ups_battery_monitor.sh LOWBATT
    ;;
  commbad)
    logger "UPS communication lost"
    ;;
  commok)
    logger "UPS communication restored"
    ;;
esac
