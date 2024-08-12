#!/bin/bash

# Set a trap to handle exit status
trap 'ret=$?; if [ $ret -ne 0 ]; then printf "failed\n\n" >&2; fi; exit $ret' EXIT

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log information with formatting
log_info() {
    printf "\n\e[0;35m%s\e[0m\n\n" "$1"
}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root..."
    exit 1
fi

log_info "Updating the system..."
sudo apt update && apt upgrade -y

log_info "Installing required packages..."
apt install -y git curl

if ! command -v docker &> /dev/null; then
    log_info "Installing Docker..."
    sudo apt install -y docker.io
    systemctl start docker
    systemctl enable docker
else
    log_info "Docker is already installed."
fi

log_info "Installing Docker Compose..."
LATEST=$(curl -Ls -w %{url_effective} -o /dev/null https://github.com/docker/compose/releases/latest)
LATEST=${LATEST##*/}
curl -L "https://github.com/docker/compose/releases/download/$LATEST/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_info "Setting umask..."
umask 0022

log_info "Cloning Mailcow repository..."
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized.git
cd mailcow-dockerized

log_info "Starting Mailcow..."
docker-compose pull
docker-compose up -d

echo "=============================================================================================================="
echo "Mailcow installation completed. Access it at https://<MAILCOW_HOSTNAME> with default credentials admin:moohoo."
