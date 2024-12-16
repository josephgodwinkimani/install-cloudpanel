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

echo "Secure a CloudPanel service:"
echo "1. Nginx"
echo "2. MariaDB"
echo "3. MySQL"
echo "4. Node.js"
echo "5. SSH"
echo "6. ProFTPD"
echo "7. PHP"
echo "8. CUSTOM"
read -p "Enter your choice (1-8): " service_type

if [ "$service_type" == "1" ]; then
    log_info "Securing Nginx..."
    if ! command -v lua5.1 &> /dev/null; then
        echo "lua5.1 could not be found. Installing..."
        sudo apt install -y lua5.1
        
        if [ $? -eq 0 ]; then
            echo "lua5.1 installed successfully."
        else
            echo "lua5.1 installation failed..."
            exit 1
        fi
    else
        echo "lua5.1 version: $(lua5.1 -v 2>&1 | head -n1)"
        echo "lua5.1 dependency exists."
    fi
    
    if ! dpkg -s libnginx-mod-http-lua &> /dev/null; then
        echo "libnginx-mod-http-lua could not be found. Installing..."
        sudo apt install -y libnginx-mod-http-lua
        
        if [ $? -eq 0 ]; then
            echo "libnginx-mod-http-lua installed successfully."
        else
            echo "libnginx-mod-http-lua installation failed..."
            exit 1
        fi
    else
        dpkg -l | grep libnginx-mod-http-lua
        echo "libnginx-mod-http-lua dependency exists."
    fi
    
    if ! command -v luarocks &> /dev/null; then
        echo "luarocks could not be found. Installing..."
        sudo apt install -y luarocks
        
        if [ $? -eq 0 ]; then
            echo "luarocks installed successfully."
        else
            echo "luarocks installation failed..."
            exit 1
        fi
    else
        dpkg -l | grep luarocks
        echo "laurocks dependency exists."
    fi
    
    if ! command -v crowdsec-nginx &> /dev/null; then
        echo "CrowdSec NGINX Bouncer is not installed. Installing..."
        
        sudo apt install -y crowdsec-nginx
        
        if [ $? -eq 0 ]; then
            FILE="/etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf"
            yq e '.API_URL=http://127.0.0.1:8089' -i "$FILE" || {
                echo "Failed to change API url port in crowdsec-nginx-bouncer.conf."
                exit 1
            }

            NEW_LISTEN_URI=$(yq e '.listen_uri' "$FILE")

            if [ "$NEW_LISTEN_URI" != "127.0.0.1:8089" ]; then
                echo "Verification failed: listen_uri was not updated correctly."
                echo "Expected: 127.0.0.1:8089"
                echo "Actual: $NEW_LISTEN_URI"
                exit 1
            else
                echo "Verification successful: listen_uri updated to 127.0.0.1:8089"
            fi           

            echo "CrowdSec NGINX Bouncer installed successfully."
        else
            echo "CrowdSec NGINX Bouncer installation failed..."
            exit 1
        fi
    else
        echo "CrowdSec NGINX Bouncer is already installed."
        sudo apt-get update
        sudo apt-get install crowdsec-nginx-bouncer
        
        if [ $? -eq 0 ]; then
            echo "CrowdSec NGINX Bouncer upgraded successfully."
        else
            echo "CrowdSec NGINX Bouncer upgrade failed..."
            exit 1
        fi
    fi
    
    log_info "Installing Nginx parser using nginx-logs parser by crowdsecurity..."
    echo "A generic parser for nginx, support both access and error logs."
    cscli parsers install crowdsecurity/nginx-logs || {
        echo "Failed to install the nginx-logs parser."
        exit 1
    }
    
    elif [ "$service_type" == "2" ]; then
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/mariadb-bf || {
        log_info "Securing MariaDB using mariadb-bf scenario by crowdsecurity..."
        echo "Detects several failed mariadb authentications."
        cscli scenarios install crowdsecurity/mariadb-bf  || {
            echo "Failed to install the mariadb-bf scenario."
            exit 1
        }
    }
    
    log_info "Upgrading MariaDB scenario - mariadb-bf scenario by crowdsecurity..."
    echo "Detects several failed mariadb authentications."
    cscli scenarios upgrade crowdsecurity/mariadb-bf  || {
        echo "Failed to upgrade the mariadb-bf scenario."
        exit 1
    }
    
    log_info "Checking..."
    cscli parsers inspect crowdsecurity/mariadb-logs || {
        log_info "Installing MariaDB parser using maraidb-logs parser by crowdsecurity..."
        echo "Mariadb authentication failure parser."
        cscli parsers install crowdsecurity/mariadb-logs || {
            echo "Failed to install the mariadb-logs parser."
            exit 1
        }
    }
    
    log_info "Upgrading MariaDB parser - maraidb-logs parser by crowdsecurity..."
    echo "Mariadb authentication failure parser."
    cscli parsers upgrade crowdsecurity/mariadb-logs || {
        echo "Failed to upgrade the mariadb-logs parser."
        exit 1
    }
    
    elif [ "$service_type" == "3" ]; then
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/mysql-bf || {
        log_info "Securing MySQL using mysql-bf scenario by crowdsecurity..."
        echo "Detect several failed mysql authentications."
        cscli scenarios install crowdsecurity/mysql-bf || {
            echo "Failed to install the mysql-bf scenario."
            exit 1
        }
    }
    
    log_info "Upgrading MySQL scenario - mysql-bf scenario by crowdsecurity..."
    echo "Detect several failed mysql authentications."
    cscli scenarios upgrade crowdsecurity/mysql-bf || {
        echo "Failed to upgrade the mysql-bf scenario."
        exit 1
    }
    
    log_info "Checking..."
    cscli parsers inspect crowdsecurity/mysql-logs || {
        log_info "Installing MySQL parser using mysql-logs parser by crowdsecurity..."
        echo "Mysql authentication fail parser."
        cscli parsers install crowdsecurity/mysql-logs || {
            echo "Failed to install the mysql-logs parser."
            exit 1
        }
    }
    
    log_info "Upgrading MySQL parser - mysql-logs parser by crowdsecurity..."
    echo "Mysql authentication fail parser."
    cscli parsers upgrade crowdsecurity/mysql-logs || {
        echo "Failed to upgrade the mysql-logs parser."
        exit 1
    }
    
    elif [ "$service_type" == "4" ]; then
    
    log_info "Checking..."
    cscli postoverflows inspect crowdsecurity/auditd-nvm-whitelist-process || {
        log_info "Whitelisting nvm..."
        echo "This postoverflow will whitelist the process node when they are executed from the .nvm directory."
        cscli postoverflows install crowdsecurity/auditd-nvm-whitelist-process || {
            echo "Failed to install the nvm-poweroverflows scenario."
            exit 1
        }
    }
    
    log_info "Upgrading nvm Whitelist..."
    echo "This postoverflow will whitelist the process node when they are executed from the .nvm directory."
    cscli postoverflows upgrade crowdsecurity/auditd-nvm-whitelist-process || {
        echo "Failed to upgrade the nvm-poweroverflows scenario."
        exit 1
    }
    
    elif [ "$service_type" == "5" ]; then
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/ssh-bf || {
        log_info "Securing SSH..."
        echo "Detect failed ssh authentications."
        cscli scenarios install crowdsecurity/ssh-bf || {
            echo "Failed to install the ssh-bf scenario."
            exit 1
        }
    }
    
    log_info "Upgrading SSH scenario - crowdsecurity/ssh-bf by crowdsecurity..."
    echo "Detect failed ssh authentications."
    cscli scenarios upgrade crowdsecurity/ssh-bf || {
        echo "Failed to upgrade the ssh-bf scenario."
        exit 1
    }
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/ssh-slow-bf || {
        echo "Detect slow ssh bruteforce authentications"
        cscli scenarios install crowdsecurity/ssh-slow-bf || {
            echo "Failed to install the ssh-slow-bf scenario."
            exit 1
        }
    }
    
    echo "Upgrade slow ssh bruteforce scenarios - ssh-slow-bf by crowdsecurity"
    cscli scenarios upgrade crowdsecurity/ssh-slow-bf || {
        echo "Failed to upgrade the ssh-slow-bf scenario."
        exit 1
    }
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/ssh-cve-2024-6387 || {
        echo "Detect exploitation attempts of CVE-2024-6387"
        cscli scenarios install crowdsecurity/ssh-cve-2024-6387 || {
            echo "Failed to install the ssh-cve-2024-638 scenario."
            exit 1
        }
    }
    
    echo "Upgrade CVE-2024-6387 scenario - ssh-cve-2024-6387 by crowdsecurity"
    cscli scenarios upgrade crowdsecurity/ssh-cve-2024-6387 || {
        echo "Failed to upgrade the ssh-cve-2024-638 scenario."
        exit 1
    }
    
    log_info "Checking..."
    cscli parsers inspect crowdsecurity/sshd-success-logs || {
        log_info "Installing SSH Parser using ssh-success-logs parser by crowdsecurity..."
        cscli parsers install crowdsecurity/sshd-success-logs || {
            echo "Failed to install the sshd-success-logs parser."
            exit 1
        }
    }
    
    log_info "Upgrading SSH Parser - ssh-success-logs parser by crowdsecurity..."
    cscli parsers upgrade crowdsecurity/sshd-success-logs || {
        echo "Failed to upgrade the sshd-success-logs parser."
        exit 1
    }
    
    log_info "Checking..."
    cscli parsers inspect crowdsecurity/sshd-logs || {
        log_info "Installing SSH parser using sshd-logs parser by crowdsecurity..."
        echo "Your one fits-all ssh parser with support for the most common kind of failed authentications and errors."
        cscli parsers install crowdsecurity/sshd-logs || {
            echo "Failed to install the sshd-logs parser."
            exit 1
        }
    }
    
    log_info "Upgrading SSH parser - sshd-logs parser by crowdsecurity..."
    echo "Your one fits-all ssh parser with support for the most common kind of failed authentications and errors."
    cscli parsers upgrade crowdsecurity/sshd-logs || {
        echo "Failed to upgrade the sshd-logs parser."
        exit 1
    }
    
    elif [ "$service_type" == "6" ]; then
    
    log_info "Checking..."
    cscli scenarios inspect crowdsecurity/proftpd-bf || {
        log_info "Securing ProFTPD..."
        echo "Detect failed proftpd authentications."
        cscli scenarios install crowdsecurity/proftpd-bf  || {
            echo "Failed to install the proftpd-bf scenario."
            exit 1
        }
    }
    
    log_info "Upgrading ProFTPD scenario - proftpd-bf by crowdsecurity..."
    echo "Detect failed proftpd authentications."
    cscli scenarios upgrade crowdsecurity/proftpd-bf  || {
        echo "Failed to upgrade the proftpd-bf scenario."
        exit 1
    }
    
    elif [ "$service_type" == "7" ]; then
    
    log_info "Securing PHP Standalone..."
    
    if command -v composer &> /dev/null; then
        echo "Composer is already installed."
        echo "Composer version: $(composer --version)"
    else
        echo "Composer is not installed."
        echo "Installing Composer..."
        
        curl -sS https://getcomposer.org/installer -o composer-setup.php
        
        HASH="$(curl -sS https://composer.github.io/installer.sig)"
        echo "$HASH composer-setup.php" | sha384sum -c - || { echo "Installer verification failed"; exit 1; }
        
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        
        rm composer-setup.php
        
        if command -v composer &> /dev/null; then
            echo "Composer installed successfully."
            echo "Composer version: $(composer --version)"
        else
            echo "Composer installation failed..."
        fi
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found. Installing..."
        sudo apt install -y jq
    else
        dpkg -l | grep jq
        echo "jq Version: $(jq --version)"
    fi
    
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Installing..."
        
        sudo apt update
        
        sudo apt install -y git
        
        if [ $? -eq 0 ]; then
            echo "Git installed successfully."
        else
            echo "Git installation failed..."
            exit 1
        fi
    else
        echo "Git Version: $(git --version)"
    fi
    
    read -p "Enter the directory where to setup PHP Bouncer (e.g. /opt/crowdsec-standalone-bouncer): " BOUNCER_DIR
    
    BOUNCER_DIR=${BOUNCER_DIR:-/opt/crowdsec-standalone-bouncer}
    
    echo "Creating bouncer directory..."
    sudo mkdir -p $BOUNCER_DIR
    
    if [ ! -d "$BOUNCER_DIR" ]; then
        log_info "PHP Standalone Bouncer directory does not exist. Creating directory: $BOUNCER_DIR"
        mkdir -p "$BOUNCER_DIR"
    else
        log_info "Using existing PHP Standalone Bouncer directory: $BOUNCER_DIR"
        git config --global --add safe.directory $BOUNCER_DIR
        git fetch
        echo "Once you have picked up the vX.Y.Z tag you want to try, you could switch to it and update composer dependencies."
        read -p "Enter git tag (e.g. v1.0.0): " GIT_TAG
        git checkout $GIT_TAG && composer update
        echo "CrowdSec standalone PHP bouncer updated successfully!"
        exit 1
    fi
    
    sudo chown -R $(whoami):$(whoami) $BOUNCER_DIR
    
    composer create-project crowdsec/standalone-bouncer $BOUNCER_DIR --keep-vcs
    
    if id -u www-data >/dev/null 2>&1; then
        echo "www-data user exists."
    else
        echo "www-data user does not exist..."
        exit 1
    fi
    
    sudo chown -R www-data $BOUNCER_DIR
    sudo chmod g+w $BOUNCER_DIR
    
    read -p "Enter the bouncer key: " BOUNCER_KEY
    
    echo "Copying settings.php.dist to settings.php..."
    # sudo cp $BOUNCER_DIR/scripts/settings.php.dist $BOUNCER_DIR/settings.php
    cat << EOF > scripts/settings.php
<?php
return [
    'bouncing_level' => Constants::BOUNCING_LEVEL_NORMAL,
    'trust_ip_forward_array' => [],
    'use_curl' => false,
    'excluded_uris' => ['/favicon.ico'],
    'cache_system' => Constants::CACHE_SYSTEM_PHPFS,
    'captcha_cache_duration' => Constants::CACHE_EXPIRATION_FOR_CAPTCHA,
    'debug_mode' => false,
    'disable_prod_log' => false,
    'log_directory_path' => __DIR__ . '/.logs',
    'display_errors' => false,
    'forced_test_ip' => '',
    'forced_test_forwarded_ip' => '',
    'custom_css' => '',
    'hide_mentions' => false,
    'color' => [
        'text' => [
            'primary' => 'black',
            'secondary' => '#AAA',
            'button' => 'white',
            'error_message' => '#b90000',
        ],
        'background' => [
            'page' => '#eee',
            'container' => 'white',
            'button' => '#626365',
            'button_hover' => '#333',
        ],
    ],
    'text' => [
        'captcha_wall' => [
            'tab_title' => 'Oops..',
            'title' => 'Hmm, sorry but...',
            'subtitle' => 'Please complete the security check.',
            'refresh_image_link' => 'refresh image',
            'captcha_placeholder' => 'Type here...',
            'send_button' => 'CONTINUE',
            'error_message' => 'Please try again.',
            'footer' => '',
        ],
        'ban_wall' => [
            'tab_title' => 'Oops..',
            'title' => '🤭 Oh!',
            'subtitle' => 'This page is protected against cyber attacks and your IP has been banned by our system.',
            'footer' => '',
        ],
    ],
    'auth_type' => Constants::AUTH_KEY,
    'tls_cert_path' => '',
    'tls_key_path' => '',
    'tls_verify_peer' => true,
    'tls_ca_cert_path' => '',
    'api_key' => '$BOUNCER_KEY',
    'api_url' => Constants::DEFAULT_LAPI_URL,
    'api_timeout' => Constants::API_TIMEOUT,
    'api_connect_timeout' => Constants::API_CONNECT_TIMEOUT,
    'fallback_remediation' => Constants::REMEDIATION_CAPTCHA,
    'ordered_remediations' => [Constants::REMEDIATION_BAN, Constants::REMEDIATION_CAPTCHA],
    'fs_cache_path' => __DIR__ . '/.cache',
    'redis_dsn' => 'redis://localhost:6379',
    'memcached_dsn' => 'memcached://localhost:11211',
    'clean_ip_cache_duration' => Constants::CACHE_EXPIRATION_FOR_CLEAN_IP,
    'bad_ip_cache_duration' => Constants::CACHE_EXPIRATION_FOR_BAD_IP,
    'stream_mode' => true,
    'geolocation' => [
        'enabled' => false,
        'type' => Constants::GEOLOCATION_TYPE_MAXMIND,
        'cache_duration' => Constants::CACHE_EXPIRATION_FOR_GEO,
        'maxmind' => [
            'database_type' => Constants::MAXMIND_COUNTRY,
            'database_path' => '/some/path/GeoLite2-Country.mmdb',
        ],
    ],
];
EOF
    
    echo "Setting up Stream mode cron task..."
    echo "Note: Cache is refreshed every 15 minutes"
    CRON_JOB="*/15 * * * * /usr/bin/php $BOUNCER_DIR/scripts/refresh-cache.php"
    
    if sudo -u www-data crontab -l | grep -Fxq "$CRON_JOB"; then
        echo "Cron job already exists for www-data user."
    else
        (sudo -u www-data crontab -l; echo "$CRON_JOB") | sudo -u www-data crontab -
        echo "Cron job added for www-data user."
    fi
    
    echo "CrowdSec standalone PHP bouncer installed successfully!"
    
    elif [ "$service_type" == "8" ]; then
    
    install_bouncer() {
        read -p "Enter the name of the Bouncer to install (e.g., crowdsec-blocklist-mirror): " bouncer_name
        log_info "Installing Bouncer: $bouncer_name..."
        sudo apt install "$bouncer_name" || {
            echo "Failed to install the Bouncer: $bouncer_name."
            exit 1
        }
        echo "Successfully installed Bouncer: $bouncer_name."
    }
    
    install_scenario() {
        read -p "Enter the name of the Scenario to install (e.g., crowdsecurity/mysql-bf): " scenario_name
        log_info "Installing Scenario: $scenario_name..."
        cscli scenarios install "$scenario_name" || {
            echo "Failed to install the Scenario: $scenario_name."
            exit 1
        }
        echo "Successfully installed Scenario: $scenario_name."
    }
    
    install_parser() {
        read -p "Enter the name of the Parser to install (e.g., crowdsecurity/mysql-logs): " parser_name
        log_info "Installing Parser: $parser_name..."
        cscli parsers install "$parser_name" || {
            echo "Failed to install the Parser: $parser_name."
            exit 1
        }
        echo "Successfully installed Parser: $parser_name."
    }
    
    install_collection() {
        read -p "Enter the name of the Collection to install (e.g., crowdsecurity/whitelist-good-actors): " collection_name
        log_info "Installing Collection: $collection_name..."
        cscli collections install "$collection_name" || {
            echo "Failed to install the Collection: $collection_name."
            exit 1
        }
        echo "Successfully installed Collection: $collection_name."
    }
    
    remove_scenarios() {
        log_info "Removing all Scenarios..."
        echo "If you have bouncers installed, it is recommended to uninstall them first to avoid conflicts."
        cscli scenarios remove -all || {
            echo "Failed to remove all scenarios."
            exit 1
        }
        echo "Successfully removed all Scenarios."
    }
    
    remove_parsers() {
        log_info "Removing all Parsers..."
        echo "If you have bouncers installed, it is recommended to uninstall them first to avoid conflicts."
        cscli parsers remove -all || {
            echo "Failed to remove all parsers."
            exit 1
        }
        echo "Successfully removed all Parsers."
    }
    
    remove_single_bouncer() {
        read -p "Enter the name of the Bouncer to remove (e.g., crowdsecurity/whitelist-good-actors): " bouncer_name
        log_info "Removing Bouncer: $bouncer_name..."
        cscli bouncers delete "$bouncer_name" || {
            echo "Failed to remove the Bouncer: $bouncer_name."
            exit 1
        }
        echo "Successfully deleted Bouncer from the database: $bouncer_name."
    }
    
    while true; do
        log_info "Choose your preferred action: "
        echo "Please choose an option:"
        echo "1. Install Bouncer"
        echo "2. Install Scenario"
        echo "3. Install Parser"
        echo "4. Install Collection"
        echo "5. Remove all Scenarios"
        echo "6. Remove all Parsers"
        echo "7. Remove a Single Bouncer"
        echo "8. Exit"
        read -p "Enter your choice (1-8): " choice
        
        case $choice in
            1)
                install_bouncer
            ;;
            2)
                install_scenario
            ;;
            3)
                install_parser
            ;;
            4)
                install_collection
            ;;
            5)
                remove_scenarios
            ;;
            6)
                remove_parsers
            ;;
            7)
                remove_single_bouncer
            ;;
            8)
                echo "exiting..."
                exit 0
            ;;
            *)
                echo "Invalid choice. Please select a valid option."
            ;;
        esac
    done
fi