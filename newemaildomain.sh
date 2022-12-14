#!/bin/bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

log_info "Getting started ..."

echo "What is the MX Record for mailserver? (e.g. mail.mydomain.com) "
read MAILDOMAIN
echo "Who is the mysql Root user? (e.g root) "
read ROOT
echo "What is the Password to your mysql Root user? (e.g password) "
read ROOTPASSWORD


log_info "Adding new email domain ..."

echo "What is the client domain you want to create a mailbox for? (e.g myclient.com) "
read CLIENTDOMAIN
mysql --user="$ROOT" --password="$ROOTPASSWORD" --execute="INSERT INTO mailserver.virtual_domains (name) VALUES ('$CLIENTDOMAIN'); SELECT * FROM mailserver.virtual_domains;"

echo "========================================"
echo "Domain added $CLIENTDOMAIN successfully!"
