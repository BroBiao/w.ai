#!/bin/zsh

APP_NAME="w ai"
APP_PATH="/Applications/w ai.app/Contents/MacOS/w ai"
SERV_NAME=$(launchctl list | grep application.ai.wombo.wai | awk '{print $3}')
LOG_PATH="/Users/$(whoami)/.wombo/cache/logs/ai.log"
MAX_SECONDS=100

export PATH="$($SHELL -lc 'echo $PATH')"

now_time=$(date "+%m-%d %H:%M:%S")
log_modtime=$(stat -f %m "$LOG_PATH")
now_ts=$(date +%s)
time_diff=$((now_ts - log_modtime))
if [ $time_diff -gt $MAX_SECONDS ]; then
    echo "$now_time No new logs for $time_diff seconds, trying to restart..."
    if pgrep -xq "$APP_NAME"; then
	pgid=$(pgrep -f "$APP_PATH")
	launchctl stop $SERV_NAME
	sleep 3
	kill -TERM -$pgid
	sleep 10
    fi
    open -a "$APP_NAME"
else
    echo "$now_time Everything is fine..."
fi
