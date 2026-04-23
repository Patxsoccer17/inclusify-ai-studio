#!/bin/bash
# Daily LinkedIn Prospecting Routine — Inclusify Studio
# Runs every morning at 8am via cron.
# Finds 10 new outreach contacts and logs them to the Notion Outreach CRM.
#
# Requirements for automated runs:
#   - NOTION_API_KEY must be set in ~/.claude/env or exported before calling
#   - MCP servers (Notion, WebSearch) must be configured in ~/.claude/settings.json
#   - ANTHROPIC_API_KEY or OAuth must be available to the claude CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/prospector.log"
PROMPT_FILE="$SCRIPT_DIR/daily_prospector_prompt.txt"
CLAUDE_BIN="/opt/node22/bin/claude"

mkdir -p "$PROJECT_DIR/logs"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Daily Prospecting Run Starting ==="

# Source environment file if present (for API keys in non-interactive cron runs)
if [ -f "$HOME/.claude/env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.claude/env"
  log "Loaded environment from ~/.claude/env"
fi

if [ ! -f "$PROMPT_FILE" ]; then
  log "ERROR: Prompt file not found at $PROMPT_FILE"
  exit 1
fi

if [ ! -x "$CLAUDE_BIN" ]; then
  log "ERROR: claude CLI not found at $CLAUDE_BIN"
  exit 1
fi

log "Running Claude prospecting agent..."

"$CLAUDE_BIN" \
  --print \
  --permission-mode auto \
  --model sonnet \
  "$(cat "$PROMPT_FILE")" \
  >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  log "=== Prospecting run completed successfully ==="
else
  log "=== Prospecting run exited with code $EXIT_CODE ==="
fi

exit $EXIT_CODE
