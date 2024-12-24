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

# Prompt for confirmation to proceed
read -p "This script will delete your Mailcow TLS assets. If you use Let's Encrypt running this script will make your account hit the rate limit soon or later. Do you want to proceed? (y/Yes/Y or n/No/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^(y|Y|yes|Yes)$ ]]; then
    echo "You cancelled the operation. Bye!"
    exit 0
fi

read -p "Enter the path where Mailcow is installed (default: /opt/mailcow-dockerized): " USER_MAILCOW_PATH
MAILCOW_PATH=${USER_MAILCOW_PATH:-/opt/mailcow-dockerized}

if [ ! -d "$MAILCOW_PATH" ]; then
    log_info "Mailcow installation directory does not exist: $MAILCOW_PATH"
    exit 1
else
    log_info "Changing directory to Mailcow installation: $MAILCOW_PATH"
    cd "$MAILCOW_PATH"
fi

CONFIG_FILE="mailcow.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

source "$CONFIG_FILE"

log_info "Stopping Mailcow..."
docker compose down

log_info "Removing TLS assets..."
rm -rf data/assets/ssl

mkdir data/assets/ssl

log_info "Creating a Self-signed Certificate..."
openssl req -x509 -newkey rsa:4096 -keyout data/assets/ssl-example/key.pem -out data/assets/ssl-example/cert.pem -days 365 -subj "/C=DE/ST=NRW/L=Willich/O=mailcow/OU=mailcow/CN=${MAILCOW_HOSTNAME}" -sha256 -nodes

cp -n -d data/assets/ssl-example/*.pem data/assets/ssl/

log_info "Starting Mailcow..."
docker compose up -d

echo "=============================================================================================================="
echo "Process Completed. Previous TLSA records are now invalid."
