#!/bin/bash
# DEBUG VARIANT: Simulation of status and charge via arguments

# ARGS: $1=EVENT, $2=MOCK_STATUS, $3=MOCK_CHARGE
EVENT="$1"
MOCK_STATUS="$2"
MOCK_CHARGE="$3"

UPS="eaton_lan"
THRESHOLD=50
INTERVAL=5
LOGFILE="/var/state/ups/nut_debug.log"
RUNDIR="/var/state/ups"
PIDFILE="$RUNDIR/ups_battery_monitor.pid"

log() {
    local msg="$(date +"%Y-%m-%d %H:%M:%S") [debug] $1: $2"
    echo "$msg" >> "$LOGFILE"
    echo "$msg"  # Display on screen as requested
}

#!/bin/bash
# DEBUG VARIANT: Simulation of status and charge via arguments

# ARGS: $1=EVENT, $2=MOCK_STATUS, $3=MOCK_CHARGE
EVENT="$1"
MOCK_STATUS="$2"
MOCK_CHARGE="$3"

UPS="eaton_lan"
THRESHOLD=50
INTERVAL=5
LOGFILE="/var/state/ups/nut_debug.log"
RUNDIR="/var/state/ups"
PIDFILE="$RUNDIR/ups_battery_monitor.pid"

log() {
    local msg="$(date +"%Y-%m-%d %H:%M:%S") [debug] $1: $2"
    echo "$msg" >> "$LOGFILE"
    echo "$msg"
}

if [ "$EVENT" = "ONBATT" ]; then
    # PRE-START CHECK: Look for existing PID file
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        log "INFO" "Monitor already running (pid=$(cat "$PIDFILE"))"
        exit 0
    fi

    (
        # RECORD PID: Using BASHPID inside subshell
        echo $BASHPID > "$PIDFILE"
        log "INFO" "Monitoring loop started (pid=$BASHPID)"
        
        while true; do
            STATUS="$MOCK_STATUS"
            CHARGE="$MOCK_CHARGE"
            
            log "DEBUG" "Check: Status=$STATUS, Charge=$CHARGE%"

            if [[ "$STATUS" == *"OL"* ]]; then
                log "INFO" "UPS back online, exiting loop"
                break
            fi

            if [[ "$STATUS" == *"OB"* ]]; then
                if [ -n "$CHARGE" ] && [ "$CHARGE" -le "$THRESHOLD" ]; then
                    log "CRITICAL" "Battery $CHARGE% <= $THRESHOLD%. Shutdown triggered."
                    break
                fi
            fi
            sleep "$INTERVAL"
        done
        rm -f "$PIDFILE"
    ) &
    
    log "INFO" "Background process spawned. Check $PIDFILE"
fi

if [ "$EVENT" = "ONLINE" ]; then
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        kill "$PID" 2>/dev/null && log "INFO" "Stopped monitor loop (pid=$PID)"
        rm -f "$PIDFILE"
    else
        log "WARN" "No PID file found"
    fi
fi
