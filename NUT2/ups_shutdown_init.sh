#!/bin/bash
# Script: ups_shutdown_init.sh
# Purpose: Initiates the graceful shutdown of ESXi hosts

LOGFILE="/var/state/ups/nut_main.log"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# --- Configuration Section ---

# 1. Array of ESXi host IP addresses / FQDN
ESXI_HOSTS=("10.3.47.2")

# 2. Array of datastore names (FIXED: removed extra quote)
DATASTORES=("Datastore-AN-01-01")

# SSH credentials
ESXI_USER="root"
ESXI_PASS="a1502EMC2805" 

# Standard path to the script on the datastore
SCRIPT_NAME="AutoOFF.sh"

# --- Logging Function ---
log() {
    local level="$1"
    local message="$2"
    echo "$DATE [ups_shutdown_init.sh] $level: $message" >> "$LOGFILE"
}

# --- Validation Section ---
if [ ${#ESXI_HOSTS[@]} -ne ${#DATASTORES[@]} ]; then
    log "ERROR" "Array size mismatch! ESXI_HOSTS has ${#ESXI_HOSTS[@]} elements, DATASTORES has ${#DATASTORES[@]}."
    exit 1
fi

# --- Main Logic ---
log "CRITICAL" "Starting graceful shutdown sequence for ESXi hosts."

for i in "${!ESXI_HOSTS[@]}"; do
    host="${ESXI_HOSTS[$i]}"
    datastore="${DATASTORES[$i]}"

    # FIXED: Added 'sh' call before the absolute path as required by ESXi
    SSH_COMMAND="sh -o StrictHostKeyChecking=no /vmfs/volumes/${datastore}/${SCRIPT_NAME}"

    log "CRITICAL" "Executing remote script on $host via command: $SSH_COMMAND"

    # Execute remote command using sshpass
    sshpass -p "$ESXI_PASS" ssh -o StrictHostKeyChecking=no "$ESXI_USER"@"$host" "$SSH_COMMAND" >> "$LOGFILE" 2>&1

    if [ $? -eq 0 ]; then
        log "CRITICAL" "Successfully started shutdown on $host."
    else
        log "ERROR" "Failed to execute shutdown script on $host. Check $LOGFILE for details."
    fi
done

log "CRITICAL" "ESXi shutdown sequence finished."
exit 0
