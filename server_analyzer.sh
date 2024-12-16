#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# CloudPanel paths
CLP_PATH="/home/clp"
CLP_DB="${CLP_PATH}/htdocs/app/data/db.sq3"
COMMON_NGINX="/etc/nginx"
COMMON_PHP="/etc/php"

# Timestamp for reports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="cloudpanel_analysis_${TIMESTAMP}"
mkdir -p "${OUTPUT_DIR}"

# Log function
log() {
    echo -e "${2}[$(date '+%Y-%m-%d %H:%M:%S')] ${1}${NC}" | tee -a "${OUTPUT_DIR}/analysis.log"
}

# Function to analyze CloudPanel database
analyze_clp_database() {
    log "Analyzing CloudPanel Database..." "${BLUE}"
    
    # Create directory for database analysis
    mkdir -p "${OUTPUT_DIR}/database"
    
    # Method 1: Using PHP console command for user data
    log "Fetching user data from Doctrine..." "${BLUE}"
    sudo -u clp /usr/bin/php8.1 /home/clp/htdocs/app/files/bin/console doctrine:query:sql "SELECT * from user;" \
        > "${OUTPUT_DIR}/database/user_data.txt" 2>/dev/null || \
        log "Error fetching user data from Doctrine" "${RED}"

    # Method 2: Using SQLite for event data
    log "Fetching event data from SQLite..." "${BLUE}"
    if [ -f "${CLP_DB}" ]; then
        sqlite3 "${CLP_DB}" <<EOF > "${OUTPUT_DIR}/database/event_history.txt"
.mode column
.headers on
SELECT 
    event_name,
    user_name,
    datetime(created_at, 'unixepoch') as event_time
FROM event
ORDER BY event_time DESC;
EOF
        log "Database analysis completed" "${GREEN}"
    else
        log "CloudPanel database not found at ${CLP_DB}" "${RED}"
    fi

    # Generate a combined analysis report
    {
        echo "CloudPanel Database Analysis Report"
        echo "================================="
        echo "Generated at: $(date)"
        echo ""
        echo "1. User Data (from Doctrine):"
        echo "----------------------------"
        cat "${OUTPUT_DIR}/database/user_data.txt"
        echo ""
        echo "2. Event History (from SQLite):"
        echo "-----------------------------"
        cat "${OUTPUT_DIR}/database/event_history.txt"
    } > "${OUTPUT_DIR}/database/database_analysis_report.txt"
}

# Function to analyze bash configuration changes
analyze_bash_configs() {
    log "Analyzing Bash configurations..." "${BLUE}"
    
    # Compare with default Ubuntu configs
    diff "/etc/skel/.bashrc" "${CLP_PATH}/.bashrc" > "${OUTPUT_DIR}/bashrc_changes.diff" 2>&1 || true
    diff "/etc/skel/.bash_logout" "${CLP_PATH}/.bash_logout" > "${OUTPUT_DIR}/bash_logout_changes.diff" 2>&1 || true
    
    # Get last modification times
    stat "${CLP_PATH}/.bashrc" "${CLP_PATH}/.bash_logout" > "${OUTPUT_DIR}/bash_config_stats.txt"
}

# Function to analyze user site structure
analyze_user_sites() {
    log "Analyzing user sites structure..." "${BLUE}"
    
    # Find all user directories
    for user_dir in /home/*/; do
        # Skip clp directory
        if [ "$user_dir" = "/home/clp/" ]; then
            continue
        fi
        
        username=$(basename "$user_dir")
        log "Analyzing user: ${username}" "${GREEN}"
        
        # Create user report directory
        user_report_dir="${OUTPUT_DIR}/users/${username}"
        mkdir -p "${user_report_dir}"
        
        # Analyze site structure
        if [ -d "${user_dir}htdocs" ]; then
            find "${user_dir}htdocs" -type d -maxdepth 2 > "${user_report_dir}/site_structure.txt"
            
            # Check WordPress installations
            find "${user_dir}htdocs" -name "wp-config.php" > "${user_report_dir}/wordpress_installations.txt"
        fi
        
        # Analyze logs
        if [ -d "${user_dir}logs" ]; then
            # Nginx logs analysis
            if [ -d "${user_dir}logs/nginx" ]; then
                log "Analyzing Nginx logs for ${username}..." "${BLUE}"
                for nginx_log in "${user_dir}logs/nginx"/*access.log; do
                    if [ -f "$nginx_log" ]; then
                        # Extract unique IPs and their request counts
                        awk '{print $1}' "$nginx_log" | sort | uniq -c | sort -rn > "${user_report_dir}/nginx_ip_stats.txt"
                        
                        # Get error requests (4xx and 5xx)
                        awk '$9 ~ /^[45]/' "$nginx_log" > "${user_report_dir}/nginx_errors.txt"
                        
                        # Look for suspicious patterns (common attack vectors)
                        grep -i "wp-login.php\|wp-admin\|xmlrpc.php" "$nginx_log" > "${user_report_dir}/wordpress_access_attempts.txt"
                    fi
                done
            fi
            
            # PHP logs analysis
            if [ -d "${user_dir}logs/php" ]; then
                log "Analyzing PHP logs for ${username}..." "${BLUE}"
                for php_log in "${user_dir}logs/php"/*error.log; do
                    if [ -f "$php_log" ]; then
                        # Extract PHP errors and warnings
                        grep -i "error\|warning\|notice" "$php_log" > "${user_report_dir}/php_errors.txt"
                    fi
                done
            fi
            
            # Varnish cache analysis
            if [ -d "${user_dir}logs/varnish-cache" ]; then
                log "Analyzing Varnish cache logs for ${username}..." "${BLUE}"
                ls -lah "${user_dir}logs/varnish-cache" > "${user_report_dir}/varnish_cache_stats.txt"
            fi
        fi
        
        # Analyze backups
        if [ -d "${user_dir}backups" ]; then
            ls -lah "${user_dir}backups" > "${user_report_dir}/backup_stats.txt"
        fi
    done
}

# Function to analyze common Nginx and PHP configurations
analyze_common_configs() {
    log "Analyzing common configurations..." "${BLUE}"
    
    # Nginx config analysis
    if [ -d "$COMMON_NGINX" ]; then
        mkdir -p "${OUTPUT_DIR}/common_configs/nginx"
        cp -r "$COMMON_NGINX/sites-enabled" "${OUTPUT_DIR}/common_configs/nginx/"
        nginx -T 2> "${OUTPUT_DIR}/common_configs/nginx/nginx_config_test.txt" || true
    fi
    
    # PHP config analysis
    if [ -d "$COMMON_PHP" ]; then
        mkdir -p "${OUTPUT_DIR}/common_configs/php"
        for version in "$COMMON_PHP"/*; do
            if [ -d "$version" ]; then
                version_num=$(basename "$version")
                php_info_file="${OUTPUT_DIR}/common_configs/php/phpinfo_${version_num}.txt"
                php -v > "$php_info_file" 2>&1
                php -i >> "$php_info_file" 2>&1
            fi
        done
    fi
}

# Main execution
main() {
    log "Starting CloudPanel analysis..." "${GREEN}"
    
    # Create output directory structure
    mkdir -p "${OUTPUT_DIR}/users"
    
    # Run analysis functions
    analyze_clp_database
    analyze_bash_configs
    analyze_user_sites
    analyze_common_configs
    
    # Generate summary report
    {
        echo "CloudPanel Analysis Summary"
        echo "=========================="
        echo "Analysis Date: $(date)"
        echo ""
        echo "Analysis Components:"
        echo "1. CloudPanel Database"
        echo "2. Bash Configurations"
        echo "3. User Sites Structure"
        echo "4. Common Configurations"
        echo ""
        echo "Output Directory: ${OUTPUT_DIR}"
    } > "${OUTPUT_DIR}/summary.txt"
    
    log "Analysis complete. Results are in: ${OUTPUT_DIR}" "${GREEN}"
}

main "$@"
