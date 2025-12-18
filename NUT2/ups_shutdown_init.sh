#!/bin/bash
# Script: ups_shutdown_init.sh
# Purpose: Initiates the graceful shutdown of ESXi hosts using parallel arrays for configuration.

LOGFILE="/var/state/ups/nut_main.log"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# --- Configuration Section (PARAMETRIZED) ---

# 1. Array of ESXi host IP addresses / FQDN
ESXI_HOSTS=("10.3.47.2")

# 2. Array of datastore names corresponding to hosts
# MUST HAVE THE SAME NUMBER OF ELEMENTS AS ESXI_HOSTS!
DATASTORES=("Datastore-AN-01-01"")

# SSH credentials
ESXI_USER="root"
# CRITICAL: Replace sshpass with SSH keys at the earliest opportunity!
ESXI_PASS="password_for_esxi" 

# Standard path to the script on the datastore
SCRIPT_NAME="Scripts/AutoOFF.sh"

# --- Logging Function ---
log() {
    local level="$1"
    local message="$2"
    echo "$DATE [ups_shutdown_init.sh] $level: $message" >> "$LOGFILE"
}

# --- Validation Function ---

if [ ${#ESXI_HOSTS[@]} -ne ${#DATASTORES[@]} ]; then
    log "ERROR" "Array size mismatch! ESXI_HOSTS has ${#ESXI_HOSTS[@]} elements, DATASTORES has ${#DATASTORES[@]}."
    exit 1
fi

# --- Main Logic ---

log "CRITICAL" "Starting graceful shutdown sequence for ESXi hosts."

for i in "${!ESXI_HOSTS[@]}"; do

    host="${ESXI_HOSTS[$i]}"
    datastore="${DATASTORES[$i]}"

    # Create the full path
    SSH_COMMAND="/vmfs/volumes/${datastore}/${SCRIPT_NAME}"

    # 1. Preparation of command and logging
    log "CRITICAL" "Executing remote script on $host at path: $SSH_COMMAND"

    # 2. Execute remote script
    # Redirect stderr and stdout of the sshpass command to the log
    sshpass -p "$ESXI_PASS" ssh -o StrictHostKeyChecking=no "$ESXI_USER"@"$host" "$SSH_COMMAND" 2>&1 >> "$LOGFILE"

    if [ $? -eq 0 ]; then
        log "CRITICAL" "Successfully started shutdown on $host."
    else
        # $? - exit code of the previous command
        log "ERROR" "Failed to execute shutdown script on $host. SSH code: $?."
        log "ERROR" "Check $LOGFILE for SSH output details."
    fi
done

log "CRITICAL" "ESXi shutdown sequence finished."
exit 0
