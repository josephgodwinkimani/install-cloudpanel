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

OUTPUT_FILE="recently_installed_packages.txt"

# > "$OUTPUT_FILE"

log_info "Listing recently installed packages..."
zgrep -h 'install ' /var/log/dpkg.log* | sort -r >> "$OUTPUT_FILE"  || {
    echo "Failed to gather recently installed packages."
    exit 1
}

log_info "Recently installed packages saved to $OUTPUT_FILE"

echo "==========================================================="
echo "Process Complete. Check recently_installed_packages.txt"
echo "==========================================================="
