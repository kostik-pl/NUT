#!/bin/bash
# UPS battery monitor loop with PID management

UPS="eaton_lan"
THRESHOLD=50
INTERVAL=60
EVENT="$1"
LOGFILE="/var/log/nut_main.log"

# Standard directory for PID (ensure nobody:nobody has rights here)
RUNDIR="/var/run/nut"
PIDFILE="$RUNDIR/ups_monitor.pid"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") [monitor] $1: $2" >> "$LOGFILE"
}

if [ "$EVENT" = "ONBATT" ]; then
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        log "INFO" "Monitor already running (pid=$(cat "$PIDFILE"))"
        exit 0
    fi

    (
        echo $$ > "$PIDFILE"
        log "INFO" "Monitoring loop started (pid=$$)"
        while true; do
            STATUS=$(/usr/local/ups/bin/upsc "$UPS" ups.status 2>/dev/null)
            # Use cut to handle cases like "30.0"
            CHARGE=$(/usr/local/ups/bin/upsc "$UPS" battery.charge 2>/dev/null | cut -d. -f1)

            if [[ "$STATUS" == *"OL"* ]]; then
                log "INFO" "UPS back online, exiting loop"
                break
            fi

            if [[ "$STATUS" == *"OB"* ]]; then
                if [ -n "$CHARGE" ] && [ "$CHARGE" -le "$THRESHOLD" ]; then
                    log "CRITICAL" "Battery $CHARGE% <= $THRESHOLD%. Initiating shutdown."
                    /usr/local/ups/etc/ups_shutdown_init.sh
                    break
                fi
            fi
            sleep "$INTERVAL"
        done
        rm -f "$PIDFILE"
    ) &
fi

if [ "$EVENT" = "ONLINE" ]; then
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        kill "$PID" 2>/dev/null && log "INFO" "Stopped monitor loop (pid=$PID)"
        rm -f "$PIDFILE"
    fi
fi

if [ "$EVENT" = "LOWBATT" ]; then
    log "CRITICAL" "LOWBATT signal received. Emergency shutdown."
    /usr/local/ups/etc/ups_shutdown_init.sh
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null && rm -f "$PIDFILE"
fi
