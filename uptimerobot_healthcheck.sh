#!/bin/bash
#
# UptimeRobot Health Check Script
# 
# This script checks the status of monitors using the UptimeRobot API
# and sends alerts to Discord when monitors are not up.
#
# Recommended cron: */5 * * * * /path/to/script/uptimerobot_healthcheck.sh
#

# UptimeRobot API Key (read-only key is sufficient)
API_KEY="YOUR_UPTIME_ROBOT_API_KEY"

DISCORD_WEBHOOK_URL="YOUR_DISCORD_WEBHOOK_URL"

LOG_FILE="/var/log/uptimerobot_healthcheck.log"
# Alternative for non-root users:
# LOG_FILE="$HOME/logs/uptimerobot_healthcheck.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Print to stdout if running in interactive mode
    if [ -t 1 ]; then
        echo "[$timestamp] [$level] $message"
    fi
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log "ERROR" "jq is not installed. Please install jq (apt-get install jq or yum install jq)."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log "ERROR" "curl is not installed. Please install curl."
        exit 1
    fi
}

get_status_text() {
    local status="$1"
    
    case "$status" in
        0) echo "Paused" ;;
        1) echo "Not checked yet" ;;
        2) echo "Up" ;;
        8) echo "Seems Down" ;;
        9) echo "Down" ;;
        *) echo "Unknown (Status $status)" ;;
    esac
}

send_discord_alert() {
    local monitor_name="$1"
    local monitor_url="$2"
    local monitor_status="$3"
    local status_text="$(get_status_text "$monitor_status")"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local color
    case "$monitor_status" in
        8|9) color=16711680 ;; # Red
        0) color=16776960 ;; # Yellow
        *) color=9807270 ;; # Gray
    esac
    
    local payload=$(cat <<EOF
{
  "embeds": [{
    "title": "⚠️ Monitor Alert: $monitor_name",
    "description": "Monitor status has changed",
    "color": $color,
    "fields": [
      {
        "name": "Monitor",
        "value": "$monitor_name",
        "inline": true
      },
      {
        "name": "URL",
        "value": "$monitor_url",
        "inline": true
      },
      {
        "name": "Status",
        "value": "$status_text",
        "inline": true
      }
    ],
    "timestamp": "$timestamp"
  }]
}
EOF
)
    
    # Send to Discord
    local response
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL" 2>&1)
    local curl_exit=$?
    
    if [ $curl_exit -ne 0 ]; then
        log "ERROR" "Failed to send Discord alert: $response"
        return 1
    elif echo "$response" | grep -q "The request body contains invalid JSON"; then
        log "ERROR" "Discord webhook rejected the JSON payload: $response"
        return 1
    else
        log "INFO" "Successfully sent alert to Discord for monitor '$monitor_name' (Status: $status_text)"
        return 0
    fi
}

# check monitor and send alerts if needed
check_monitors() {
    log "INFO" "Starting UptimeRobot health check"
    
    # Make API call to UptimeRobot
    local api_response
    api_response=$(curl -s -X POST https://api.uptimerobot.com/v2/getMonitors \
                       -H "Content-Type: application/x-www-form-urlencoded" \
                       -H "Cache-Control: no-cache" \
                       -d "api_key=$API_KEY&format=json" 2>&1)
    local curl_exit=$?
    
    if [ $curl_exit -ne 0 ]; then
        log "ERROR" "Failed to call UptimeRobot API: $api_response"
        return 1
    fi
    
    if ! echo "$api_response" | jq -e '.stat' &> /dev/null; then
        log "ERROR" "Invalid response from UptimeRobot API: $api_response"
        return 1
    fi
    
    local api_status
    api_status=$(echo "$api_response" | jq -r '.stat')
    if [ "$api_status" != "ok" ]; then
        local error_message
        error_message=$(echo "$api_response" | jq -r '.error.message // "Unknown error"')
        log "ERROR" "UptimeRobot API returned error: $error_message"
        return 1
    fi
    
    local monitors_down=0
    local monitors_total=0
    
    while read -r id name url status; do
        ((monitors_total++))
        
        if [ "$status" != "2" ]; then
            log "WARN" "Monitor '$name' ($url) is not up. Status: $(get_status_text "$status")"
            send_discord_alert "$name" "$url" "$status"
            ((monitors_down++))
        else
            log "INFO" "Monitor '$name' ($url) is up."
        fi
    done < <(echo "$api_response" | jq -r '.monitors[] | "\(.id) \(.friendly_name) \(.url) \(.status)"')
    
    log "INFO" "Health check completed. $monitors_down of $monitors_total monitors are down."
    
    return 0
}

check_dependencies

check_monitors
exit_code=$?

exit $exit_code
