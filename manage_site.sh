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

echo "Manage a CloudPanel Website:"
echo "1. Install Let's Encrypt Certificate"
echo "2. Create Database"
echo "3. Import Database"
echo "4. Export Database"
echo "5. Add Restricted Site User"
echo "6. Reset Any User Password"
echo "7. List vHost Templates"
echo "8. Delete Site (DANGER)"
echo "9. Delete Any User (DANGER)"
read -p "Enter your choice (1-9): " choice

if [ "$choice" == "8" ] || [ "$choice" == "9" ]; then
    log_info "DANGER - You are about to delete something (Ctrl + C to stop)"
fi

read -p "Enter domain name (e.g., domain.com without www): " domain_name

# if [[ -z "$domain_name" ]]; then
#     echo "Domain name cannot be empty..."
#     exit 1
# fi

if [ "$choice" == "1" ]; then
    
    log_info "Installing a Let's Encrypt Certificate for $domain_name site..."
    clpctl lets-encrypt:install:certificate --domainName="$domain_name" || {
        echo "Failed to add Let's Encrypt Certificate for site $domain_name."
        exit 1
    }
    
    echo "============================================"
    echo "SSL certificate installed for $domain_name successfully!"
    
    elif [ "$choice" == "2" ]; then
    
    read -p "Enter database name: " database_name
    read -p "Enter database username: " database_username
    read -sp "Enter database password: " database_password
    echo  ""
    log_info "Adding database for $domain_name site..."
    clpctl db:add --domainName="$domain_name" --databaseName="$database_name" --databaseUserName="$database_username" --databaseUserPassword="$database_password" || {
        echo "Failed to create database $database_name for site $domain_name."
        exit 1
    }
    
    echo "==========================================================="
    echo "Database Name: $database_name"
    echo "Database Username: $database_username"
    echo "Database Password: $database_password"
    echo "==========================================================="
    echo "Database created successfully!"
    
    elif [ "$choice" == "3" ]; then
    
    echo "The assumption is that your database dump exists in the same directory as this running script."
    read -p "Enter database name: " import_dbname
    read -p "Enter database dump name (e.g. dump.sql.gz): " import_dump
    echo
    log_info "Importing database for $domain_name site..."
    clpctl db:import --databaseName="$import_dbname" --file="$import_dump" || {
        echo "Failed to import database $import_dbname for site $domain_name."
        exit 1
    }
    
    echo "==========================================================="
    echo "Database Name: $import_dbname"
    echo "Database Dump File name: $import_dump"
    echo "==========================================================="
    echo "Database imported successfully!"
    
    elif [ "$choice" == "4" ]; then
    
    echo "The database wil be dumped in the same directory as this running script."
    read -p "Enter database name: " export_dbname
    read -p "Enter database dump name (e.g. dump.sql.gz): " export_dump
    echo
    log_info "Exporting database for $domain_name site..."
    clpctl db:export --databaseName="$export_dbname" --file="$export_dump" || {
        echo "Failed to export database $export_dbname for site $domain_name."
        exit 1
    }
    
    echo "==========================================================="
    echo "Database Name: $export_dbname"
    echo "Database Dump File name: $export_dump"
    echo "==========================================================="
    echo "Database exported successfully!"
    
    elif [ "$choice" == "5" ]; then
    
    read -p "Enter first name: " user_firstname
    read -p "Enter last name: " user_lastname
    read -p "Enter email address: " user_email
    read -p "Enter username: " user_name
    read -sp "Enter password: " user_password
    echo
    log_info "Creating a Restricted User for $domain_name site..."
    clpctl user:add --userName=$user_name --email=$user_email --firstName=$user_firstname --lastName=$user_lastname --password=$user_username --role='user' --sites=$domain_name --timezone='UTC' --status='1' || {
        echo "Failed to create a Restricted user for $domain_name site."
        exit 1
    }
    
    echo "==========================================================="
    echo "Restricted User Email: $user_email"
    echo "Restricted User First Name: $user_firstname"
    echo "Restricted User Last Name: $user_lastname"
    echo "Restricted Username: $user_name"
    echo "Restricted User Password: $user_password"
    echo "==========================================================="
    echo "Restricted User created successfully!"
    
    elif [ "$choice" == "6" ]; then
    
    read -p "Enter username: " user_name
    read -sp "Enter password: " user_password
    echo
    log_info "Resetting a User Password..."
    clpctl user:reset:password --userName=$user_name --password='$user_password' || {
        echo "Failed to reset $user_name password."
        exit 1
    }
    
    echo "==========================================================="
    echo "Password for User $user_name reset successfully!"
    
    elif [ "$choice" == "7" ]; then
    
    log_info "List all Vhost Templates that can be used for adding a PHP Site..."
    clpctl vhost-templates:list
    
    elif [ "$choice" == "8" ]; then
    
    log_info "Deleting $domain_name site..."
    clpctl site:delete --domainName="$domain_name" --force || {
        echo "Failed to delete Site $domain_name."
        exit 1
    }
    
    echo "==========================================================="
    echo "Domain site $domain_name deleted successfully!"
    
    elif [ "$choice" == "9" ]; then
    
    read -p "Enter username: " user_name
    echo
    log_info "Deleting a User..."
    clpctl user:delete --userName=$user_name || {
        echo "Failed to delete a User."
        exit 1
    }
    
    echo "==========================================================="
    echo "User $user_name deleted successfully!"
fi