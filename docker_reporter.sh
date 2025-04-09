#!/bin/bash

# Container monitoring script for Mailcow docker containers plus any other important containers you have
# This script monitors containers by name and sends Discord alerts when any are down

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/"
SERVER_NAME="192.124.453-docker"

# How many notifications to keep in history (to avoid spam for the same issue)
NOTIFICATION_HISTORY_SIZE=20
NOTIFICATION_HISTORY_FILE="/tmp/container_notification_history.txt"

touch "$NOTIFICATION_HISTORY_FILE"
# Trim the notification history file if it gets too large
if [ "$(wc -l < "$NOTIFICATION_HISTORY_FILE")" -gt "$NOTIFICATION_HISTORY_SIZE" ]; then
    tail -n "$NOTIFICATION_HISTORY_SIZE" "$NOTIFICATION_HISTORY_FILE" > "$NOTIFICATION_HISTORY_FILE.tmp"
    mv "$NOTIFICATION_HISTORY_FILE.tmp" "$NOTIFICATION_HISTORY_FILE"
fi

# Mailcow containers
MAILCOW_CONTAINERS=(
    "mailcowdockerized-ipv6nat-mailcow-1"
    "mailcowdockerized-watchdog-mailcow-1"
    "mailcowdockerized-acme-mailcow-1"
    "mailcowdockerized-nginx-mailcow-1"
    "mailcowdockerized-rspamd-mailcow-1"
    "mailcowdockerized-ofelia-mailcow-1"
    "mailcowdockerized-dovecot-mailcow-1"
    "mailcowdockerized-php-fpm-mailcow-1"
    "mailcowdockerized-postfix-mailcow-1"
    "mailcowdockerized-redis-mailcow-1"
    "mailcowdockerized-mysql-mailcow-1"
    "mailcowdockerized-clamd-mailcow-1"
    "mailcowdockerized-unbound-mailcow-1"
    "mailcowdockerized-dockerapi-mailcow-1"
    "mailcowdockerized-olefy-mailcow-1"
    "mailcowdockerized-memcached-mailcow-1"
    "mailcowdockerized-sogo-mailcow-1"
    "mailcowdockerized-netfilter-mailcow-1"
)

# Sepcial containers
MUSTBEUP_CONTAINERS=(
    "mongodb"
    "prom"
    "grafana"
)

# Other containers
OTHER_CONTAINERS=(
    "pgadmin"
    "adminerevo"
)

# Containers that are OK to be in "Exited" state (intentionally stopped)
ALLOWED_EXITED=(
    "mailcowdockerized-clamd-mailcow-1"
)

# Check if a container is in the allowed exited list
is_allowed_exited() {
    local container_name="$1"
    for allowed in "${ALLOWED_EXITED[@]}"; do
        if [ "$container_name" = "$allowed" ]; then
            return 0
        fi
    done
    return 1
}

send_discord_notification() {
    local message="$1"
    local notification_key="$2"
    
    # Check if we've already sent this notification recently
    if grep -q "$notification_key" "$NOTIFICATION_HISTORY_FILE"; then
        # We've already notified about this issue, skip
        echo "Skipping duplicate notification for: $notification_key"
        return
    fi
    
    # Send the notification
    curl -s -H "Content-Type: application/json" \
         -d "{\"content\": \"$message\"}" \
         "$DISCORD_WEBHOOK_URL"
    
    # Record this notification
    echo "$(date +%s) $notification_key" >> "$NOTIFICATION_HISTORY_FILE"
}

check_docker_service() {
    if ! systemctl is-active --quiet docker; then
        send_discord_notification "@here **⚠️ CRITICAL ALERT ⚠️**\n**Docker service is DOWN on $SERVER_NAME**\nContainer monitoring cannot continue." "docker_down"
        exit 1
    fi
}

check_container_status() {
    local container_name="$1"
    local group="$2"
    
    # Get container status
    local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Container doesn't exist
        send_discord_notification "@here **⚠️ CONTAINER MISSING ⚠️**\n**[$group]** Container **$container_name** is MISSING on **$SERVER_NAME**\nThe container does not exist." "${container_name}_missing"
        return 1
    elif [ "$status" != "running" ]; then
        # Container exists but is not running
        if is_allowed_exited "$container_name"; then
            return 0
        else
            # Container should be running but isn't
            local state_detail=$(docker inspect --format='{{.State.Status}} (Exit Code: {{.State.ExitCode}})' "$container_name")
            send_discord_notification "@here **⚠️ CONTAINER DOWN ⚠️**\n**[$group]** Container **$container_name** is DOWN on **$SERVER_NAME**\nCurrent state: $state_detail" "${container_name}_down"
            return 1
        fi
    fi
    
    return 0
}

check_container_health() {
    local container_name="$1"
    local group="$2"
    
    # Check if container has a health check
    if docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health-check{{end}}' "$container_name" 2>/dev/null | grep -q "unhealthy"; then
        # Container is unhealthy
        send_discord_notification "@here **⚠️ CONTAINER UNHEALTHY ⚠️**\n**[$group]** Container **$container_name** is UNHEALTHY on **$SERVER_NAME**\nThe container is running but its health check is failing." "${container_name}_unhealthy"
        return 1
    fi
    
    return 0
}

check_container_group() {
    local group_name="$1"
    shift
    local containers=("$@")
    
    local failed_count=0
    
    for container in "${containers[@]}"; do
        check_container_status "$container" "$group_name"
        if [ $? -ne 0 ]; then
            ((failed_count++))
            continue
        fi
        
        # Only check health if status check passed
        check_container_health "$container" "$group_name"
        if [ $? -ne 0 ]; then
            ((failed_count++))
        fi
    done
    
    return $failed_count
}

# Send summary report
send_summary_report() {
    local mailcow_failed="$1"
    local mustbeup_failed="$2"
    local other_failed="$3"
    
    # Only send summary if there are failures
    local total_failed=$((mailcow_failed + mustbeup_failed + other_failed))
    
    if [ $total_failed -gt 0 ]; then
        local message="**📊 CONTAINER STATUS SUMMARY 📊**\n"
        message+="Server: **$SERVER_NAME**\n"
        message+="Total containers with issues: **$total_failed**\n\n"
        message+="**System breakdown:**\n"
        message+="- Mailcow: $mailcow_failed/${#MAILCOW_CONTAINERS[@]} containers with issues\n"
        message+="- MustBeUp: $mustbeup_failed/${#MUSTBEUP_CONTAINERS[@]} containers with issues\n"
        message+="- Other: $other_failed/${#OTHER_CONTAINERS[@]} containers with issues\n\n"
        message+="Check individual alerts for details. A new notification will be sent when systems recover."
        
        send_discord_notification "$message" "summary_report_$(date +%Y%m%d%H)"
    fi
}

# Clear notifications for recovered containers
clear_recovered_containers() {
    local container_name="$1"
    
    # Check if container is now running
    if docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null | grep -q "running"; then
        # If we had a notification for this container, send a recovery message
        if grep -q "${container_name}_" "$NOTIFICATION_HISTORY_FILE"; then
            send_discord_notification "**✅ CONTAINER RECOVERED ✅**\nContainer **$container_name** has RECOVERED on **$SERVER_NAME**." "${container_name}_recovered"
            
            # Remove old notification records for this container
            grep -v "${container_name}_" "$NOTIFICATION_HISTORY_FILE" > "$NOTIFICATION_HISTORY_FILE.tmp"
            mv "$NOTIFICATION_HISTORY_FILE.tmp" "$NOTIFICATION_HISTORY_FILE"
        fi
    fi
}

main() {
    check_docker_service
    
    mailcow_failed=0
    mustbeup_failed=0
    other_failed=0
    
    check_container_group "Mailcow" "${MAILCOW_CONTAINERS[@]}"
    mailcow_failed=$?
    
    check_container_group "MustBeUp" "${MUSTBEUP_CONTAINERS[@]}"
    mustbeup_failed=$?
    
    check_container_group "Other" "${OTHER_CONTAINERS[@]}"
    other_failed=$?
    
    send_summary_report $mailcow_failed $mustbeup_failed $other_failed
    
    for container in "${MAILCOW_CONTAINERS[@]}" "${MUSTBEUP_CONTAINERS[@]}" "${OTHER_CONTAINERS[@]}"; do
        clear_recovered_containers "$container"
    done
}

main
exit 0
