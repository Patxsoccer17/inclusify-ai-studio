#!/usr/bin/env bash
# Daily LinkedIn outreach routine for Inclusify Studio.
# Searches for 10 new contacts and logs them to the Notion Outreach CRM.
# Scheduled to run at 8am daily via cron.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/daily-outreach-prompt.md"
LOG_DIR="$SCRIPT_DIR/logs"
DATE="$(date +%Y-%m-%d)"
LOG_FILE="$LOG_DIR/outreach-$DATE.log"

mkdir -p "$LOG_DIR"

echo "[$DATE $(date +%H:%M:%S)] Starting daily outreach routine..." | tee -a "$LOG_FILE"

# Build the prompt with today's date injected
PROMPT="$(sed "s/\$(date +%Y-%m-%d)/$DATE/g" "$PROMPT_FILE")"

# Run the outreach routine via Claude CLI
/opt/node22/bin/claude \
  --model claude-sonnet-4-6 \
  --print \
  --allowedTools "mcp__Notion__notion-search,mcp__Notion__notion-create-pages,mcp__Notion__notion-fetch,mcp__Notion__notion-query-database-view,WebSearch,WebFetch" \
  "$PROMPT" \
  2>&1 | tee -a "$LOG_FILE"

echo "[$DATE $(date +%H:%M:%S)] Daily outreach routine complete." | tee -a "$LOG_FILE"
