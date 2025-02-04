#!/bin/bash

trap 'ret=$?; if [ $ret -ne 0 ]; then printf "failed\n\n" >&2; fi; exit $ret' EXIT

set -e

log_info() {
    printf "\n\e[0;35m%s\e[0m\n\n" "$1"
}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root..."
    exit 1
fi

log_info "Checking requirements..."

if ! command -v rsync &> /dev/null
then
    echo "rsync could not be found. Installing it now..."
    
    sudo apt-get update
    sudo apt-get install -y rsync
    
    if ! command -v rsync &> /dev/null
    then
        echo "Failed to install rsync. Please check your internet connection or package manager."
        exit 1
    fi
fi

rsync_version=$(rsync --version | head -n 1 | cut -d' ' -f3)
echo "Rsync version: $rsync_version"

php_version=$(php -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
echo "PHP version: $php_version"

python_version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Python version: $python_version"

nodejs_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Node.js version: $nodejs_version"

echo "Enter the path of your compressed site backup file (supports '.tar' or '.tar.gz' or '.zip'):"
read file_path

log_info "Uncompressing backup file..."

if [ -f "$file_path" ]; then
    
    temp_dir=$(mktemp -d)
    
    case "$file_path" in
        *.tar.gz|*.tgz)
            tar -xzf "$file_path" -C "$temp_dir"
        ;;
        *.tar)
            tar -xf "$file_path" -C "$temp_dir"
        ;;
        *.zip)
            unzip -d "$temp_dir" "$file_path"
        ;;
        *)
            echo "Unsupported file format. Please provide a .tar.gz, .tar, or .zip file."
            exit 1
        ;;
    esac
    
    echo "Backup file uncompressed successfully!"
else
    echo "Backup file not found: $file_path"
fi

echo "Select website type:"
echo "1. Node.js"
echo "2. Python"
echo "3. PHP"
echo "4. Static HTML site"
read -p "Enter your choice (1-4): " website_type

read -p "Enter domain name (e.g., domain.com without www): " domain_name

read -p "Enter site user name (same as backup): " site_user

read -sp "Enter site user password (atleast 8 characters): " site_password
echo

read -sp "Confirm site user password: " confirm_password
echo

if [ "$website_type" == "1" ]; then
    
    echo "Select Node.js version:"
    echo "1. Node 12 LTS"
    echo "2. Node 14 LTS"
    echo "3. Node 16 LTS"
    echo "4. Node 18 LTS"
    echo "5. Node 20 LTS"
    echo "6. Node 22 LTS"
    read -p "Enter your choice (1-6): " node_version
    
    read -p "Enter site/app port (e.g: 3000): " node_port
    echo
    
    log_info "Creating Node.js site on port $node_port..."
    
    case $node_version in
        1)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=12 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
        2)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=14 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
        3)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=16 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
        4)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=18 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
        5)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=20 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
        6)
            clpctl site:add:nodejs --domainName=$domain_name --nodejsVersion=22 --appPort=$node_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Node.js site for $domain_name."
                exit 1
            }
        ;;
    esac
    
    elif [ "$website_type" == "2" ]; then
    
    echo "Select Python version:"
    echo "1. Python 3.9"
    echo "2. Python 3.10"
    read -p "Enter your choice (1-2): " python_version
    
    read -p "Enter site/app port (e.g: 8091): " python_port
    echo
    
    log_info "Creating python site on port $python_port..."
    
    case $python_version in
        1)
            clpctl site:add:python --domainName=$domain_name --pythonVersion=3.9 --appPort=$python_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Python site for $domain_name."
                exit 1
            }
        ;;
        2)
            clpctl site:add:python --domainName=$domain_name --pythonVersion=3.10 --appPort=$python_port --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create Python site for $domain_name."
                exit 1
            }
        ;;
    esac
    
    elif [ "$website_type" == "3" ]; then
    echo "Select PHP version:"
    echo "1. PHP 7.1"
    echo "2. PHP 7.2"
    echo "3. PHP 7.3"
    echo "4. PHP 7.4"
    echo "5. PHP 8.0"
    echo "6. PHP 8.1"
    echo "7. PHP 8.2"
    echo "8. PHP 8.3"
    read -p "Enter your choice (1-8): " php_v
    
    case $php_v in
        1) PHP_VERSION=7.1 ;;
        2) PHP_VERSION=7.2 ;;
        3) PHP_VERSION=7.3 ;;
        4) PHP_VERSION=7.4 ;;
        5) PHP_VERSION=8.0 ;;
        6) PHP_VERSION=8.1 ;;
        7) PHP_VERSION=8.2 ;;
        8) PHP_VERSION=8.3 ;;
        *) echo "Invalid choice. Please select a number between 1 and 8." && exit 1 ;;
    esac
    
    echo "Select PHP website type:"
    echo "1. WooCommerce"
    echo "2. WordPress"
    echo "3. Laravel"
    echo "4. Drupal"
    echo "5. Joomla 5"
    echo "6. Yii 2"
    echo "7. Magento 2"
    echo "8. Moodle 4"
    echo "9. Mautic 5"
    echo "10. Laminas"
    echo "11. CakePHP"
    echo "12. Nextcloud 29"
    echo "13. TYPO3 13"
    echo "14. FuelPHP"
    echo "15. OroCommerce 5.0"
    echo "16. Symfony"
    echo "17. PrestaShop 1.7"
    echo "18. Generic"
    echo "19. Shopware 6"
    echo "20. WHMCS"
    echo "21. Contao 4"
    echo "22. Neos 8"
    echo "23. Slim 4"
    read -p "Enter your choice (1-23): " php_website_type
    
    case $php_website_type in
        3)
            echo "Select Laravel version:"
            echo "1. Laravel 11"
            echo "2. Laravel 10"
            read -p "Enter your choice (1-2): " laravel_version
        ;;
        16)
            echo "Select Symfony version:"
            echo "1. Symfony 6"
            echo "2. Symfony 7"
            read -p "Enter your choice (1-2): " symfony_version
        ;;
        4)
            echo "Select Drupal version:"
            echo "1. Drupal 10"
            echo "2. Drupal 9"
            read -p "Enter your choice (1-2): " drupal_version
        ;;
    esac
    
    log_info "Creating php $PHP_VERSION site..."
    
    case $php_website_type in
        1)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='WooCommerce' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create WooCommerce website."
                exit 1
            }
        ;;
        2)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='WordPress' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create WordPress website."
                exit 1
            }
        ;;
        3)
            case $laravel_version in
                1)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Laravel' --siteUser=$site_user --siteUserPassword=$site_password --version=11  || {
                        echo "Failed to create PHP site for $domain_name."
                        exit 1
                    }
                ;;
                2)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Laravel' --siteUser=$site_user --siteUserPassword=$site_password --version=10  || {
                        echo "Failed to create PHP site for $domain_name."
                        exit 1
                    }
                ;;
            esac
        ;;
        4)
            case $drupal_version in
                1)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Drupal' --siteUser=$site_user --siteUserPassword=$site_password --version=10
                ;;
                2)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Drupal' --siteUser=$site_user --siteUserPassword=$site_password --version=9  || {
                        echo "Failed to create PHP site for $domain_name."
                        exit 1
                    }
                ;;
            esac
        ;;
        5)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Joomla' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        6)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Yii' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        7)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Magento' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        8)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Moodle' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        9)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Mautic' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        10)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Laminas' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        11)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='CakePHP' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        12)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Nextcloud' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        13)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='TYPO3' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        14)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='FuelPHP' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        15)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='OroCommerce' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        16)
            case $symfony_version in
                1)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Symfony' --siteUser=$site_user --siteUserPassword=$site_password --version=6  || {
                        echo "Failed to create PHP site for $domain_name."
                        exit 1
                    }
                ;;
                2)
                    clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Symfony' --siteUser=$site_user --siteUserPassword=$site_password --version=7  || {
                        echo "Failed to create PHP site for $domain_name."
                        exit 1
                    }
                ;;
            esac
        ;;
        17)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='PrestaShop 1.7' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        18)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Generic' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        19)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Shopware 6' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        20)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='WHMCS' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        21)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Contao 4' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        22)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Neos 8' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
        23)
            clpctl site:add:php --domainName=$domain_name --phpVersion=$PHP_VERSION --vhostTemplate='Slim 4' --siteUser=$site_user --siteUserPassword=$site_password  || {
                echo "Failed to create PHP site for $domain_name."
                exit 1
            }
        ;;
    esac
    
else
    case $website_type in
        4)
            log_info "Creating a Static HTML site for $domain_name..."
            clpctl site:add:static --domainName=$domain_name --siteUser=$site_user --siteUserPassword=$site_password || {
                echo "Failed to create Static HTML site for $domain_name."
                exit 1
            }
        ;;
    esac
fi

log_info "Restoring Backup website..."

dst_folder='/home/$site_user/'

if [ -d "$temp_dir/home/$site_user" ]; then
    # The --delete option ensures that all files in the destination folder are overwritten by the files from the source folder.
    rsync -aAXv --delete "$temp_dir/home/$site_user/" $dst_folder  || {
        echo "Failed to restore site $domain_name under $dst_folder."
        exit 1
    }
    echo "Backup restored successfully!"
else
    echo "'$dst_folder' directory not found in the uncompressed result."
    exit 1
fi

while true; do
    read -p "Do you want to add a database for this site? (y/n): " site_database
    
    case "$site_database" in
        [yY])
            read -p "Enter database name: " database_name
            read -p "Enter database username: " database_username
            read -sp "Enter database password: " database_password
            echo
            log_info "Adding database for $domain_name site..."
            clpctl db:add --domainName="$domain_name" --databaseName="$database_name" --databaseUserName="$database_username" --databaseUserPassword="$database_password" || {
                echo "Failed to create database for site $domain_name."
                exit 1
            }
            break
        ;;
        [nN])
            echo "Skipping database addition."
            break
        ;;
        *)
            echo "Invalid input. Please enter 'y' or 'Y' or 'n' or 'N'."
        ;;
    esac
done

ask_import_database() {
    new_domain="https://$domain_name"
    read -p "Do you want to import database for this site? (y/n): " import_database
    if [[ "$import_database" == "y" || "$import_database" == "Y" ]]; then
        echo "The assumption is that your backup has database dumps at default destination - $file_path/home/$site_user/backups/databases "
        read -p "Enter database name (same as your backup): " import_dbname
        read -p "Enter date of database backup (e.g. 2024-08-13): " import_date
        read -p "Enter database backup dump name (e.g. databasename_1723508101.sql.gz): " import_dump
        read -p "Enter old domain url to replace (optional e.g. https://myolddomain.com): " old_domain
        : ${old_domain:=""}
        echo
        log_info "Looking up database backup file for $domain_name site..."
        
        backup_dir="/home/$site_user/backups/databases/$import_dbname/$import_date"
        
        if [ -d "$backup_dir" ]; then
            cd $backup_dir  || {
                echo "Failed to find database backup for site $domain_name."
                exit 1
            }
        else
            echo "'$backup_dir' directory not found in the uncompressed result."
            exit 1
        fi
        
        log_info "Importing database for $domain_name site..."
        
        clpctl db:import --databaseName="$import_dbname" --file="$import_dump"  || {
            echo "Failed to import database for $domain_name."
            exit 1
        }
        
        if [ -n "$old_domain" ]; then
            if [ "$php_website_type" == "2" ]; then
                wp search-replace "$old_domain" "$new_domain" --skip-columns=guid --allow-root || {
                    echo "Failed to update WordPress site url for site $domain_name."
                    exit 1
                }
                echo "Old Domain url replaced in Database."
            fi
        fi
        
        echo "Backup Database imported successfully!"
        elif [[ "$import_database" == "n" || "$import_database" == "N" ]]; then
        echo "Backup Database import skipped."
    else
        echo "Invalid input. Please enter 'y' or 'Y' or 'n' or 'N'."
        ask_import_database  # Recursively call the function until valid input is received
    fi
}

ask_import_database

ask_create_restricted_user() {
    read -p "Do you want to add a user who is restricted to this site? (y/n): " domain_site_user
    if [[ "$domain_site_user" == "y" || "$domain_site_user" == "Y" ]]; then
        read -p "Enter first name: " user_firstname
        read -p "Enter last name: " user_lastname
        read -p "Enter email address: " user_email
        read -p "Enter username: " user_name
        read -sp "Enter password: " user_password
        echo
        log_info "Creating a Restricted User for $domain_name site..."
        clpctl user:add --userName=$user_name --email=$user_email --firstName=$user_firstname --lastName=$user_lastname --password=$user_username --role='user' --sites=$domain_name --timezone='UTC' --status='1'  || {
            echo "Failed to create restricted user for $domain_name."
            exit 1
        }
        elif [[ "$import_database" == "n" || "$import_database" == "N" ]]; then
        echo "Adding Restricted user for the site skipped."
    else
        echo "Invalid input. Please enter 'y' or 'Y' or 'n' or 'N'."
        ask_create_restricted_user  # Recursively call the function until valid input is received
    fi
}

ask_create_restricted_user

# clean up
rm -rf "$temp_dir"

echo "==========================================================="
echo "Domain Name: $domain_name"
if [ "$website_type" == "1" ]; then
    echo "Website Type: NodeJS"
    elif [ "$website_type" == "2" ]; then
    echo "Website Type: Python"
    elif [ "$website_type" == "3" ]; then
    echo "Website Type: PHP"
    elif [ "$website_type" == "4" ]; then
    echo "Website Type: Static HTML"
    elif [ "$website_type" == "5" ]; then
    echo "Website Type: Reverse proxy"
fi
echo "Site User: $site_user"
echo "Site User Password: $site_password"
if [[ "$domain_site_user" == "y" || "$domain_site_user" == "Y" ]]; then
    echo "==========================================================="
    echo "Restricted User Email: $user_email"
    echo "Restricted User First Name: $user_firstname"
    echo "Restricted User Last Name: $user_lastname"
    echo "Restricted Username: $user_name"
    echo "Restricted User Password: $user_password"
fi
echo "==========================================================="
if [ "$website_type" == "1" ]; then
    echo "Node.js Version: $node_version"
    echo "App Version: $node_port"
    elif [ "$website_type" == "2" ]; then
    echo "Python Version: $python_version"
    echo "App Port: python_port"
    elif [ "$website_type" == "3" ]; then
    echo "PHP Version: $PHP_VERSION"
    echo "PHP Website Type: $php_website_type"
    if [ "$php_website_type" == "3" ]; then
        echo "Laravel Version: ${laravel_version:-Not Selected}"
        elif [ "$php_website_type" == "4" ]; then
        echo "Drupal Version: ${drupal_version:-Not Selected}"
        elif [ "$php_website_type" == "16" ]; then
        echo "Symfony Version: ${symfony_version:-Not Selected}"
    fi
fi
echo "==========================================================="
if [[ "$site_database" == "y" || "$site_database" == "Y" ]]; then
    echo "Database Name: $database_name"
    echo "Database Username: $database_username"
    echo "Database Password: $database_password"
    echo "==========================================================="
fi
echo "Website restored successfully!"