#!/bin/bash

APP_NAME="w.ai"
LOG_PATH="/home/$(whoami)/.wombo/cache/logs/ai.log"
MAX_SECONDS=100

export DISPLAY=$(who | awk -v user="$(whoami)" '$1 == user && $2 ~ /^:[0-9]+$/ {last_display = $2} END {if (last_display) print last_display}')
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

now_time=$(date "+%m-%d %H:%M:%S")
log_modtime=$(stat -c %Y "$LOG_PATH")
now_ts=$(date +%s)
time_diff=$((now_ts - log_modtime))
if [ $time_diff -gt $MAX_SECONDS ]; then
    echo "$now_time No new logs for $time_diff seconds, trying to restart..."
    if pgrep -x $APP_NAME > /dev/null; then
        kill -- -$(ps -o pgid= -p $(pgrep -o $APP_NAME) | tr -d ' ')
        sleep 10
    fi
    gtk-launch $APP_NAME
else
    echo "$now_time Everything is fine..."
fi
