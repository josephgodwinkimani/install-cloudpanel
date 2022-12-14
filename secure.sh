#!/usr/bin/env bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

echo "You can enable Basic Auth as additional layer of security in front of CloudPanel if you don't have a static IP to close port 8443."

log_info "Set username ..."
echo "What username would you prefer? (e.g john.doe) "
read USERNAME

log_info "Set password ..."
echo "What password would you prefer? (e.g. j71WG@Qz7y3Lg9953!sh3LXDE0) "
read PASSWORD

log_info "Enable Basic Auth ..."
clpctl cloudpanel:enable:basic-auth --userName=$USERNAME --password='$PASSWORD'
echo "Your username is $USERNAME and your password is $PASSWORD"
