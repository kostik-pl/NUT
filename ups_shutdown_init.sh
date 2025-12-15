#!/bin/bash
# FILE: /usr/local/ups/etc/ups_shutdown_init.sh
# Purpose: Executes the ESXi host shutdown sequence on multiple hosts (FINAL LOGIC).

# --- CONFIGURATION ---
ESXI_HOSTS=("10.3.47.2") # Add all required host IPs here
ESXI_PATH="/vmfs/volumes/Datastore-AN-01-01/AutoOFF.sh"
ESXI_USER="root"
ESXI_PASS="a1502EMC2805" 
LOG_NUT="/var/log/nut_main.log"
# ---

echo "$(date) - [INITIATOR] Starting shutdown sequence for multiple ESXi hosts." >> "$LOG_NUT"

# Цикл для виконання SSH-команди на кожному хості у масиві
for ESXI_HOST in "${ESXI_HOSTS[@]}"; do
    echo "$(date) - [ACTION] Calling script on host: $ESXI_HOST" >> "$LOG_NUT"
    
    # CRITICAL SECURITY RISK: Use SSH keys instead of sshpass.
    sshpass -p "$ESXI_PASS" ssh -o StrictHostKeyChecking=no "$ESXI_USER"@"$ESXI_HOST" "sh $ESXI_PATH" >/dev/null 2>&1 &
done

echo "$(date) - [INITIATOR] Shutdown commands sent to all ESXi hosts." >> "$LOG_NUT"