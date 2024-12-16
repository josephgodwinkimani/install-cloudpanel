#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script adds a cron job to the crontab."
    echo "You will be prompted for the following:"
    echo "1. Command to run"
    echo "2. Frequency (in minutes or seconds) or choose preset (once a day, week, or month)"
    echo "3. Day of the week (0-7, where 0 and 7 are Sunday)"
    echo "4. Day of the month (1-31)"
    echo "5. Month of the year (1-12)"
    echo "6. Output file path (optional)"
    exit 1
}

# Function to validate input
validate_input() {
    local input="$1"
    local type="$2"
    
    case "$type" in
        "command")
            if [[ ! -f "$input" ]]; then
                echo "Error: The command '$input' does not exist."
                exit 1
            fi
        ;;
        "frequency")
            if [[ "$input" == "once a day" ]]; then
                echo "Command will run 00:00 (midnight)."
                frequency="1440"
                elif [[ "$input" == "once a week" ]]; then
                echo "Command will run 00:00 (midnight) on Sunday."
                frequency="10080"
                elif [[ "$input" == "once a month" ]]; then
                echo "Command will run 00:00 (midnight) on the 1st of each month."
                frequency="43200"
                elif ! [[ "$input" =~ ^[0-9]+$ ]]; then
                echo "Error: Frequency must be a number or a preset (once a day, once a week, or once a month)."
                exit 1
            else
                frequency="$input"
            fi
        ;;
        "day_of_week")
            if ! [[ "$input" =~ ^[0-7]$ ]]; then
                echo "Error: Day of the week must be between 0 and 7."
                exit 1
            fi
        ;;
        "day_of_month")
            if ! [[ "$input" =~ ^[1-9][0-9]?$|^3[01]$ ]]; then
                echo "Error: Day of the month must be between 1 and 31."
                exit 1
            fi
        ;;
        "month")
            if ! [[ "$input" =~ ^[1-9]$|^1[0-2]$ ]]; then
                echo "Error: Month must be between 1 and 12."
                exit 1
            fi
        ;;
    esac
}

read -p "Enter the command to run: " command
validate_input "$command" "command"

read -p "Enter frequency (in minutes or seconds) or preset (once a day, week, or month): " frequency
validate_input "$frequency" "frequency"

read -p "Enter day of the week (0-7): " day_of_week
validate_input "$day_of_week" "day_of_week"

read -p "Enter day of the month (1-31): " day_of_month
validate_input "$day_of_month" "day_of_month"

read -p "Enter month of the year (1-12): " month
validate_input "$month" "month"

read -p "Enter the path of the output file (optional): " output_file

if [[ "$frequency" -lt 60 ]]; then
    # If frequency is in seconds, convert to minutes
    frequency=$((frequency / 60))
    cron_time="$frequency * * * *"
else
    # If frequency is in minutes
    cron_time="$frequency * * * *"
fi

if [[ -z "$output_file" ]]; then
    cron_job="$cron_time $command >> /dev/null 2>&1"
else
    cron_job="$cron_time $command >> $output_file 2>&1"
fi

(crontab -l; echo "$cron_job") | crontab -

echo "Cron job added successfully: $cron_job"