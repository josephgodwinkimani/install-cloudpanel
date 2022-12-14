#!/bin/bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

while true; do

read -p "The assumption is you have configured the email domain in your email server. Do you want to proceed? (y/n) " yn

case $yn in 
	[yY] ) echo ok, we will proceed;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac

done

log_info "Getting started ..."

echo "What is the MX Record for mailserver? (e.g. mail.mydomain.com) "
read MAILDOMAIN
echo "Who is the mysql Root user? (e.g root) "
read ROOT
echo "What is the Password to your mysql Root user? (e.g password) "
read ROOTPASSWORD
echo "What is the client domain you want to create a mailbox for? (e.g myclient.com) "
read CLIENTDOMAIN
ID=$(mysql --user="$ROOT" --password="$ROOTPASSWORD" --silent --skip-column-names --execute="SELECT id FROM mailserver.virtual_domains WHERE name=$CLIENTDOMAIN");

log_info "Creating new mailbox ..."

echo "Create an email address with domain you chose previously ? (e.g johndoe will result in johndoe@mail.com) "
read EMAIL
echo "Create an email password for $EMAIL?"
read EMAILPASSWORD
sudo doveadm pw -Dv -s SHA512-CRYPT -p $EMAILPASSWORD
echo "Copy the hash here, ignoring the first 14 characters of {SHA512-CRYPT}? (e.g $6$hvEwQ...) "
read EMAILPASSWORDHASH
mysql --user="$ROOT" --password="$ROOTPASSWORD" --execute="INSERT INTO mailserver.virtual_users (domain_id, password , email) VALUES ('$ID', '$EMAILPASSWORDHASH', '$EMAIL'); SELECT * FROM mailserver.virtual_users;"

echo "Server: (Both incoming and outgoing) $MAILDOMAIN"
echo "IMAP: Set the port to 993 and the SSL/Security settings to SSL/TLS or equivalent."
echo "POP3: Set the port to 995 and require SSL."
echo "SMTP: Set the port to 587 and the SSL/Security settings to STARTTLS or equivalent."
echo "==================================================================================="
echo "Created Email Account with username: $EMAIL"
echo "Created Email Account with password: $EMAILPASSWORD"
