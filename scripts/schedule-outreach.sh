#!/bin/bash
# Persistent 8am daily scheduler for Inclusify Studio outreach prospecting.
# Run this once in a background terminal: nohup bash schedule-outreach.sh &

SCRIPT="/home/user/inclusify-ai-studio/scripts/daily-outreach-prospecting.sh"
LOGFILE="/home/user/inclusify-ai-studio/logs/scheduler.log"
mkdir -p "$(dirname "$LOGFILE")"

echo "[$(date)] Scheduler started. Will run outreach prospecting at 8:00am daily." >> "$LOGFILE"

while true; do
    NOW=$(date +%s)
    # Calculate next 8am
    TODAY_8AM=$(date -d "today 08:00" +%s)
    TOMORROW_8AM=$(date -d "tomorrow 08:00" +%s)

    if [ "$NOW" -lt "$TODAY_8AM" ]; then
        NEXT_RUN=$TODAY_8AM
    else
        NEXT_RUN=$TOMORROW_8AM
    fi

    SLEEP_SECS=$((NEXT_RUN - NOW))
    echo "[$(date)] Next run at $(date -d @$NEXT_RUN). Sleeping ${SLEEP_SECS}s." >> "$LOGFILE"

    sleep "$SLEEP_SECS"

    echo "[$(date)] Woke up. Running outreach prospecting..." >> "$LOGFILE"
    bash "$SCRIPT"
    echo "[$(date)] Run complete." >> "$LOGFILE"
done
