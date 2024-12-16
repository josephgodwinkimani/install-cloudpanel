#!/bin/bash

# Ensure the script is run as root or has sufficient permissions
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sufficient permissions..."
    exit 1
fi

# Use ps with options to display detailed process information
log_info "Listing all running processes with detailed information..."
ps aux

# Explanation of the columns:
# USER: The user who owns the process
# PID: The process ID
# %CPU: The percentage of CPU used by the process
# %MEM: The percentage of memory used by the process
# VSZ: The virtual memory size of the process in kilobytes
# RSS: The resident set size (non-swapped physical memory used) in kilobytes
# TTY: The terminal associated with the process (or ? if not associated)
# STAT: The status of the process (e.g., R for running, S for sleeping)
# START: The time the process started
# TIME: The total CPU time used by the process
# COMMAND: The command line of the process

log_info() {
    printf "\n\e[0;35m $1\e[0m\n\n"
}

echo "==========================================================="
echo "Process List:"
echo "==========================================================="
ps aux | awk '{
    printf "%-8s %-6s %-5s %-5s %-7s %-7s %-4s %-5s %-10s %-10s %s\n",
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
}' | head -1
ps aux | awk '{
    printf "%-8s %-6d %-5.1f %-5.1f %-7d %-7d %-4s %-5s %-10s %-10s %s\n",
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
}'

echo "==========================================================="
echo "Process List Complete."
echo "==========================================================="
