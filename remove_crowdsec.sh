#!/bin/bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
    printf "\n\e[0;35m $1\e[0m\n\n"
}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root..."
    exit 1
fi

log_info "Stopping CrowdSec service..."
systemctl stop crowdsec

log_info "Removing CrowdSec files..."
find /etc/crowdsec -maxdepth 1 -mindepth 1 | grep -v "bouncer" | xargs rm -rf || echo "No configuration files found."

rm -f /var/log/crowdsec.log || echo "No log file found."
rm -f /var/log/lapi.log || echo "No LAPI log file found."

rm -f /var/lib/crowdsec.db || echo "No database file found."

rm -rf /usr/local/bin/crowdsec || echo "No binary directory found."
rm -rf /etc/systemd/system/crowdsec.service || echo "No systemd service file found."

if [ -d "/etc/crowdsec/bouncers" ]; then
    echo "Removing bouncers..."
    rm -rf /etc/crowdsec/bouncers || echo "No bouncers found."
fi

echo "============================================"
echo "CrowdSec has been uninstalled successfully."
echo "============================================"