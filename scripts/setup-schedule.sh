#!/usr/bin/env bash
# Run this once on your actual machine to activate the 8am daily outreach schedule.
# Supports Linux (cron) and macOS (launchd).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_DIR/scripts/daily-outreach.sh"

if [[ ! -x "$SCRIPT" ]]; then
  chmod +x "$SCRIPT"
fi

OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  # macOS — install a LaunchAgent plist
  PLIST_DIR="$HOME/Library/LaunchAgents"
  PLIST="$PLIST_DIR/studio.inclusify.outreach.plist"
  mkdir -p "$PLIST_DIR"
  cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>              <string>studio.inclusify.outreach</string>
  <key>ProgramArguments</key>   <array><string>$SCRIPT</string></array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>   <integer>8</integer>
    <key>Minute</key> <integer>0</integer>
  </dict>
  <key>StandardOutPath</key> <string>$REPO_DIR/logs/outreach-cron.log</string>
  <key>StandardErrorPath</key><string>$REPO_DIR/logs/outreach-cron.log</string>
  <key>RunAtLoad</key> <false/>
</dict>
</plist>
PLIST
  launchctl load "$PLIST" && echo "LaunchAgent installed — runs daily at 8am."

elif [[ "$OS" == "Linux" ]]; then
  # Linux — install a per-user crontab entry
  TMP=$(mktemp)
  crontab -l 2>/dev/null > "$TMP" || true
  if ! grep -q "daily-outreach.sh" "$TMP"; then
    echo "0 8 * * * $SCRIPT >> $REPO_DIR/logs/outreach-cron.log 2>&1" >> "$TMP"
    crontab "$TMP"
    echo "Cron job installed — runs daily at 8am."
  else
    echo "Cron job already exists — no changes made."
  fi
  rm "$TMP"

else
  echo "Unsupported OS: $OS. Add this line to your scheduler:"
  echo "  0 8 * * * $SCRIPT"
fi
