#!/bin/bash
# FILE: /usr/local/ups/etc/ups_online_init.sh
# Purpose: Resets the system state after power returns (ONLINE).

# --- CONFIGURATION (MUST MATCH upssched.conf) ---
LOCK_FILE="/var/log/upslock"
# ---

# 1. Stop UPS shutdown command (for safety, if one was sent to the device)
/usr/local/ups/bin/upscmd -u monuser -p monitorpass eaton_lan shutdown.stop

# 2. Remove the shutdown lock file to allow future shutdowns
if [ -f "$LOCK_FILE" ]; then
    rm "$LOCK_FILE"
fi
