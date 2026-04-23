#!/usr/bin/env bash
# Daily 8am routine: find 10 new outreach contacts for Inclusify Studio and add them to Notion CRM.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/morning-outreach-$(date +%Y-%m-%d).log"
PROMPT_FILE="$SCRIPT_DIR/morning-outreach-prompt.txt"
CLAUDE_BIN="/opt/node22/bin/claude"

mkdir -p "$LOG_DIR"

echo "=== Inclusify Studio Morning Outreach — $(date) ===" | tee -a "$LOG_FILE"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: Prompt file not found at $PROMPT_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

if [[ ! -x "$CLAUDE_BIN" ]]; then
  echo "ERROR: claude CLI not found at $CLAUDE_BIN" | tee -a "$LOG_FILE"
  exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

"$CLAUDE_BIN" \
  --print \
  --dangerously-skip-permissions \
  --model sonnet \
  --output-format text \
  "$PROMPT" 2>&1 | tee -a "$LOG_FILE"

echo "=== Run complete — $(date) ===" | tee -a "$LOG_FILE"

# Keep only the last 30 daily logs to avoid disk bloat
find "$LOG_DIR" -name "morning-outreach-*.log" -mtime +30 -delete 2>/dev/null || true
