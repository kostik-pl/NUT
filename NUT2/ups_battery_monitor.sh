#!/bin/bash
# UPS battery monitor loop with stable PID management

UPS="eaton_lan"
THRESHOLD=50
INTERVAL=60
EVENT="$1"
LOGFILE="/var/state/ups/nut_main.log"
RUNDIR="/var/state/ups"
PIDFILE="$RUNDIR/ups_battery_monitor.pid"

log() {
    local msg="$(date +"%Y-%m-%d %H:%M:%S") [monitor] $1: $2"
    echo "$msg" >> "$LOGFILE"
}

if [ "$EVENT" = "ONBATT" ]; then
    # PRE-START CHECK: Look for existing PID file to prevent duplicates
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        log "INFO" "Monitor already running (pid=$(cat "$PIDFILE"))"
        exit 0
    fi

    (
        # RECORD PID: Using BASHPID inside subshell for accurate tracking
        echo $BASHPID > "$PIDFILE"
        log "INFO" "Monitoring loop started (pid=$BASHPID)"

        while true; do
            # Fetch real data from UPS
            STATUS=$(/usr/local/ups/bin/upsc "$UPS" ups.status 2>/dev/null)
            CHARGE=$(/usr/local/ups/bin/upsc "$UPS" battery.charge 2>/dev/null | cut -d. -f1)

            if [[ "$STATUS" == *"OL"* ]]; then
                log "INFO" "UPS back online, exiting loop"
                break
            fi

            if [[ "$STATUS" == *"OB"* ]]; then
                if [ -n "$CHARGE" ] && [ "$CHARGE" -le "$THRESHOLD" ]; then
                    log "CRITICAL" "Battery $CHARGE% <= $THRESHOLD%. Shutdown triggered."
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
        if kill "$PID" 2>/dev/null; then
            log "INFO" "Stopped monitor loop (pid=$PID)"
        fi
        rm -f "$PIDFILE"
    else
        log "WARN" "No PID file found during ONLINE event"
    fi
fi

if [ "$EVENT" = "LOWBATT" ]; then
    log "CRITICAL" "LOWBATT signal received. Emergency shutdown."
    /usr/local/ups/etc/ups_shutdown_init.sh
    if [ -f "$PIDFILE" ]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    fi
fi
