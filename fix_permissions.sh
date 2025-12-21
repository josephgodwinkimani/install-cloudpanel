#!/bin/bash

# Set a trap to handle exit status
trap 'ret=$?; if [ $ret -ne 0 ]; then printf "failed\n\n" >&2; fi; exit $ret' EXIT

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log information with formatting (Matches your sample)
log_info() {
    printf "\n\e[0;35m%s\e[0m\n\n" "$1"
}

# Ensure Root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root..."
    exit 1
fi

# Introduction
echo "==========================================================="
echo " CloudPanel Permission Fixer"
echo " For: Node.js, React, Next.js, Python, PHP, Laravel"
echo "==========================================================="

while true; do
    read -p "Do you want to proceed? (y/n) " yn
    case $yn in
        [yY] ) echo "ok, we will proceed..."; break;;
        [nN] ) echo "exiting..."; exit;;
        * ) echo "invalid response";;
    esac
done

log_info "Configuration..."

# Gather Details
read -p "Enter domain name (e.g., domain.com): " domain_name
read -p "Enter site user name (the owner of the site): " site_user

# Verify Path
TARGET_DIR="/home/$site_user/htdocs/$domain_name"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    echo "Please check the domain and username."
    exit 1
fi

echo "Target Directory: $TARGET_DIR"
echo ""

echo "Select application type to apply specific tweaks:"
echo "1. Node.js / React / Vite / Next.js"
echo "2. Python (Django/Flask)"
echo "3. Laravel (PHP)"
echo "4. Standard PHP / HTML / Wordpress"
read -p "Enter your choice (1-4): " app_type

log_info "Applying Base Permissions..."

# 1. Set Ownership
# CloudPanel apps run under the site user
echo "Setting ownership to $site_user:$site_user..."
chown -R "$site_user":"$site_user" "$TARGET_DIR"

# 2. Set Standard Directory Permissions (755)
# User: Read/Write/Execute, Group/World: Read/Execute
echo "Setting directory permissions to 755..."
find "$TARGET_DIR" -type d -exec chmod 755 {} +

# 3. Set Standard File Permissions (644)
# User: Read/Write, Group/World: Read
echo "Setting file permissions to 644..."
find "$TARGET_DIR" -type f -exec chmod 644 {} +

log_info "Applying Application Specific Fixes..."

case $app_type in
    1) # Node.js / React / Next.js
        echo "Optimizing for Node.js ecosystem..."
        
        # Secure .env files (Sensitive data)
        if [ -f "$TARGET_DIR/.env" ]; then
            echo "Securing .env file (600)..."
            chmod 600 "$TARGET_DIR/.env"
        fi
        
        # If there is a dist or build folder, ensure it's readable
        # (Already handled by 755/644 base rules, but good to verify)
        ;;
        
    2) # Python
        echo "Optimizing for Python..."
        
        # Secure .env files
        if [ -f "$TARGET_DIR/.env" ]; then
            echo "Securing .env file (600)..."
            chmod 600 "$TARGET_DIR/.env"
        fi
        
        # Make manage.py executable if it exists
        if [ -f "$TARGET_DIR/manage.py" ]; then
            echo "Making manage.py executable (755)..."
            chmod 755 "$TARGET_DIR/manage.py"
        fi
        ;;
        
    3) # Laravel
        echo "Optimizing for Laravel..."
        
        # Secure .env file
        if [ -f "$TARGET_DIR/.env" ]; then
            echo "Securing .env file (600)..."
            chmod 600 "$TARGET_DIR/.env"
        fi
        
        # Make artisan executable
        if [ -f "$TARGET_DIR/artisan" ]; then
            echo "Making artisan executable (755)..."
            chmod 755 "$TARGET_DIR/artisan"
        fi
        
        # Ensure Storage and Bootstrap cache are writable
        # In CloudPanel, since the PHP user owns the files, 755 is usually enough.
        # However, 775 is often used if the web group needs separate access.
        # We will stick to Owner Writable (which is set) but ensure directories are explicit.
        if [ -d "$TARGET_DIR/storage" ]; then
            echo "Ensuring storage directory is writable..."
            chmod -R 775 "$TARGET_DIR/storage"
        fi
        
        if [ -d "$TARGET_DIR/bootstrap/cache" ]; then
            echo "Ensuring bootstrap/cache is writable..."
            chmod -R 775 "$TARGET_DIR/bootstrap/cache"
        fi
        ;;
        
    4) # Standard / WordPress
        echo "Optimizing for Standard Web/WordPress..."
        
        # WordPress wp-config.php security
        if [ -f "$TARGET_DIR/wp-config.php" ]; then
            echo "Securing wp-config.php (600)..."
            chmod 600 "$TARGET_DIR/wp-config.php"
        fi
        ;;
        
    *)
        echo "No specific application tweaks selected."
        ;;
esac

echo "==========================================================="
echo "Permissions fixed successfully for $domain_name"
echo "Path: $TARGET_DIR"
echo "Owner: $site_user"
echo "==========================================================="
