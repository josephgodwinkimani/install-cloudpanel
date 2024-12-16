#!/bin/bash

# https://forum.hhf.technology/t/analyse-script-cloudplanel/425

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Timestamp and Output Directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="cloudpanel_analysis_${TIMESTAMP}"
mkdir -p "${OUTPUT_DIR}/traffic_analysis"
mkdir -p "${OUTPUT_DIR}/security"
mkdir -p "${OUTPUT_DIR}/file_changes"

# Log function
log() {
    echo -e "${2}[$(date '+%Y-%m-%d %H:%M:%S')] ${1}${NC}" | tee -a "${OUTPUT_DIR}/analysis.log"
}

# Function to analyze IP addresses and traffic patterns
analyze_traffic_patterns() {
    local user_dir="$1"
    local username="$2"
    local analysis_dir="${OUTPUT_DIR}/traffic_analysis/${username}"
    mkdir -p "$analysis_dir"

    log "Analyzing traffic patterns for user: ${username}" "${BLUE}"

    if [ -d "${user_dir}logs/nginx" ]; then
        for access_log in "${user_dir}logs/nginx"/*access.log; do
            if [ -f "$access_log" ]; then
                # Top IP addresses
                log "Extracting top IP addresses..." "${GREEN}"
                awk '{print $1}' "$access_log" | sort | uniq -c | sort -rn | head -n 20 > \
                    "${analysis_dir}/top_ips.txt"

                # HTTP Status Distribution
                log "Analyzing HTTP status codes..." "${GREEN}"
                awk '{print $9}' "$access_log" | sort | uniq -c | sort -rn > \
                    "${analysis_dir}/http_status_distribution.txt"

                # Error Requests Analysis (4xx and 5xx)
                log "Analyzing error requests..." "${GREEN}"
                awk '$9 ~ /^[45]/ {print $1,$9,$7,$time_local}' "$access_log" | \
                    tail -n 100 > "${analysis_dir}/error_requests.txt"

                # Traffic by Hour
                log "Analyzing traffic patterns by hour..." "${GREEN}"
                awk '{print $4}' "$access_log" | cut -d: -f2 | sort | uniq -c | \
                    sort -n > "${analysis_dir}/traffic_by_hour.txt"

                # Large File Transfers
                log "Identifying large file transfers..." "${GREEN}"
                awk '$10 > 1000000 {print $7,$10,$1}' "$access_log" | \
                    sort -nr -k2 | head -n 20 > "${analysis_dir}/large_transfers.txt"

                # Suspicious Patterns
                log "Checking for suspicious patterns..." "${GREEN}"
                {
                    echo "=== SQL Injection Attempts ==="
                    grep -i "union\|select\|insert\|delete\|update" "$access_log" | tail -n 20
                    echo -e "\n=== Script Injection Attempts ==="
                    grep -i "<script\|alert(" "$access_log" | tail -n 20
                    echo -e "\n=== File Upload Attempts ==="
                    grep -i "\.php\|\.jsp\|\.asp" "$access_log" | tail -n 20
                } > "${analysis_dir}/suspicious_patterns.txt"
            fi
        done
    fi
}

# Function to analyze outbound connections
analyze_outbound_traffic() {
    log "Analyzing outbound connections..." "${BLUE}"
    local outbound_dir="${OUTPUT_DIR}/traffic_analysis/outbound"
    mkdir -p "$outbound_dir"

    # Current outbound connections
    if command -v ss &> /dev/null; then
        ss -ntp 2>/dev/null | grep ESTAB > "${outbound_dir}/current_connections.txt"
    elif command -v netstat &> /dev/null; then
        netstat -ntp 2>/dev/null | grep ESTABLISHED > "${outbound_dir}/current_connections.txt"
    fi

    # Analyze varnish cache connections if available
    for user_dir in /home/*/; do
        if [ -d "${user_dir}logs/varnish-cache" ]; then
            username=$(basename "$user_dir")
            log "Analyzing Varnish cache connections for ${username}..." "${GREEN}"
            ls -lah "${user_dir}logs/varnish-cache" > "${outbound_dir}/varnish_${username}.txt"
        fi
    done
}

# Function to analyze user activities and security
analyze_security() {
    log "Analyzing security events..." "${BLUE}"
    local security_dir="${OUTPUT_DIR}/security"

    # Recent user logins
    last -n 100 > "${security_dir}/recent_logins.txt"

    # Failed login attempts
    {
        echo "=== Failed SSH Attempts ==="
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 50
        echo -e "\n=== Invalid Users ==="
        grep "Invalid user" /var/log/auth.log 2>/dev/null | tail -n 50
        echo -e "\n=== Failed sudo ==="
        grep "sudo.*COMMAND" /var/log/auth.log 2>/dev/null | tail -n 50
    } > "${security_dir}/failed_attempts.txt"

    # CloudPanel specific security events
    if [ -f "${CLP_DB}" ]; then
        sqlite3 "${CLP_DB}" <<EOF > "${security_dir}/clp_security_events.txt"
.mode column
.headers on
SELECT event_name, user_name, datetime(created_at, 'unixepoch') as event_time
FROM event
WHERE event_name LIKE '%login%' OR event_name LIKE '%fail%' OR event_name LIKE '%error%'
ORDER BY created_at DESC LIMIT 100;
EOF
    fi
}

# Function to analyze file modifications
analyze_file_changes() {
    log "Analyzing file modifications..." "${BLUE}"
    local changes_dir="${OUTPUT_DIR}/file_changes"

    for user_dir in /home/*/; do
        username=$(basename "$user_dir")
        if [ "$username" != "clp" ]; then
            log "Analyzing file changes for user: ${username}" "${GREEN}"
            {
                echo "=== Recently Modified Files ==="
                find "${user_dir}" -type f -mtime -1 -ls 2>/dev/null | \
                    awk '{print $11,$7,$8,$9,$10}' | tail -n 50

                echo -e "\n=== Recently Created Files ==="
                find "${user_dir}" -type f -ctime -1 -ls 2>/dev/null | \
                    awk '{print $11,$7,$8,$9,$10}' | tail -n 50

                echo -e "\n=== Large Files (>100MB) ==="
                find "${user_dir}" -type f -size +100M -ls 2>/dev/null | \
                    awk '{print $11,$7,$8,$9,$10}'
            } > "${changes_dir}/${username}_file_changes.txt"
        fi
    done

    # Monitor CloudPanel specific files
    if [ -d "/home/clp" ]; then
        log "Analyzing CloudPanel file changes..." "${GREEN}"
        {
            echo "=== CloudPanel Configuration Changes ==="
            find "/home/clp/services" -type f -mtime -7 -ls 2>/dev/null
            
            echo -e "\n=== Recent Database Changes ==="
            ls -la "/home/clp/htdocs/app/data/db.sq3"
        } > "${changes_dir}/cloudpanel_changes.txt"
    fi
}

# Main execution
main() {
    log "Starting enhanced log analysis..." "${GREEN}"

    # Process each user's directory
    for user_dir in /home/*/; do
        username=$(basename "$user_dir")
        if [ "$username" != "clp" ]; then
            analyze_traffic_patterns "$user_dir" "$username"
        fi
    done

    analyze_outbound_traffic
    analyze_security
    analyze_file_changes

    # Generate summary report
    {
        echo "CloudPanel Analysis Summary Report"
        echo "================================="
        echo "Generated at: $(date)"
        echo ""
        echo "Analysis Components:"
        echo "1. Traffic Analysis"
        echo "   - Top IP addresses"
        echo "   - HTTP status distribution"
        echo "   - Error requests (4xx and 5xx)"
        echo "   - Traffic patterns by hour"
        echo ""
        echo "2. Security Analysis"
        echo "   - Recent logins"
        echo "   - Failed login attempts"
        echo "   - Suspicious activities"
        echo ""
        echo "3. File Changes"
        echo "   - Recent modifications"
        echo "   - New files"
        echo "   - Large files"
        echo ""
        echo "4. Outbound Traffic"
        echo "   - Current connections"
        echo "   - Varnish cache analysis"
    } > "${OUTPUT_DIR}/analysis_summary.txt"

    log "Analysis complete. Results are in: ${OUTPUT_DIR}" "${GREEN}"
}

main "$@"
