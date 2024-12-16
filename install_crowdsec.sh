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

if [ "$(lsb_release -is)" != "Debian" ] && [ "$(lsb_release -is)" != "Ubuntu" ]; then
    echo "This script is intended for Debian or Ubuntu."
    exit 1
fi

log_info "Updating package list..."
sudo apt update

if [ -x "$(command -v crowdsec)" ]; then
    log_info "CrowdSec is already installed. Upgrading it..."
    sudo apt install -y crowdsec || {
        echo "Failed to update crowdsec."
        exit 1
    }
    echo "==========================================================="
    echo "CrowdSec upgrade is complete."
    echo "==========================================================="
    exit 1
fi

log_info "Installing CrowdSec..."
curl -s https://install.crowdsec.net | sudo sh && sudo apt install -y crowdsec  || {
    echo "Failed to install crowdsec."
    exit 1
}

if [ $? -ne 0 ]; then
    echo "CrowdSec installation failed."
    exit 1
fi

log_info "Change API url port in crowdsec config..."
FILE="/etc/crowdsec/config.yaml"
yq e '.listen_uri = "127.0.0.1:8089"' -i "$FILE" || {
    echo "Failed to change API url port in crowdsec config."
    exit 1
}

log_info "Verifying the change to crowdsec config..."
NEW_LISTEN_URI=$(yq e '.listen_uri' "$FILE")

if [ "$NEW_LISTEN_URI" != "127.0.0.1:8089" ]; then
  echo "Verification failed: listen_uri was not updated correctly."
  echo "Expected: 127.0.0.1:8089"
  echo "Actual: $NEW_LISTEN_URI"
  exit 1
else
  echo "Verification successful: listen_uri updated to 127.0.0.1:8089"
fi

log_info "Starting CrowdSec service..."
sudo systemctl start crowdsec  || {
    echo "Failed to start crowdsec."
    exit 1
}

log_info "Enabling CrowdSec to start on boot..."
sudo systemctl enable crowdsec  || {
    echo "Failed to enable crowdsec."
    exit 1
}

read -p "Please enter your enrollment token (e.g., cla2006jp0000mj08148): " enrollment_token

log_info "Enrolling your instance with the provided token..."
sudo cscli console enroll "$enrollment_token" || {
    echo "Failed to enroll your instance with token $enrollment_token."
    exit 1
}

if [ $? -eq 0 ]; then
    echo "Successfully enrolled your CrowdSec instance."
else
    echo "Enrollment failed. Please check your token $enrollment_token and try again."
fi

echo "==========================================================="
echo "CrowdSec setup is complete."
echo "Check the logs: /var/log/crowdsec.log"
echo "==========================================================="