#!/bin/bash

# FILE: /usr/local/ups/etc/ups_batt_check.sh
# Purpose: Checks 50% threshold and signals upssched to initiate shutdown or schedule next check.

# --- CONFIGURATION (MUST MATCH upssched.conf) ---
PIPEFN="/var/log/upspipe"
LOCKFN="/var/log/upslock"
CHARGE_THRESHOLD=50
# ---

# Check if lock file exists (correct syntax: check contents of variable)
if [ -f "$LOCKFN" ]; then 
   exit 0
fi

charge=$(/usr/local/ups/bin/upsc eaton_lan battery.charge 2>/dev/null)
status=$(/usr/local/ups/bin/upsc eaton_lan ups.status 2>/dev/null)

if [[ -z "$status" || -z "$charge" ]]; then
    exit 1
fi

if echo "$status" | grep -q 'ONBATT'; then
    if [[ "$charge" -le $CHARGE_THRESHOLD ]]; then
       
       # 1. Set lock file and send signal to upssched (triggers AT low_charge)
       touch "$LOCKFN"
       echo "EXECUTE low_charge" > "$PIPEFN"
    
    elif [[ "$charge" -gt $CHARGE_THRESHOLD ]]; then 
       
       # 2. Schedule next check in 60 seconds
       echo "START-TIMER charge_monitor 60" > "$PIPEFN"
    fi
else
    # Power is back online (OL) or unhandled status - exit
    exit 0
fi
