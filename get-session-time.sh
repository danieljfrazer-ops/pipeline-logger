#!/bin/bash
# Fetch session info and extract timing
# Usage: ./get-session-time.sh <session-label>

LABEL="$1"

if [ -z "$LABEL" ]; then
  echo "Usage: $0 <session-label>"
  echo "Example: $0 coder-v3.2.0"
  exit 1
fi

# Find the session key
SESSION_KEY=$(openclaw sessions --json 2>/dev/null | \
  jq -r ".sessions[] | select(.label == \"$LABEL\") | .key" 2>/dev/null | head -1)

if [ -z "$SESSION_KEY" ]; then
  echo "Session not found: $LABEL"
  exit 1
fi

echo "Found session: $SESSION_KEY"

# Get session history
openclaw sessions history "$SESSION_KEY" --json 2>/dev/null | \
  jq '.messages[-1] | {timestamp: .timestamp, role: .message.role, content: .message.content[0].text[:100]}' 2>/dev/null

# Try to get timing from messages
echo ""
echo "Session timing:"
openclaw sessions history "$SESSION_KEY" --json 2>/dev/null | \
  jq -r '.messages[] | select(.message.role == "toolResult") | .details.runtime // .details.durationMs // empty' 2>/dev/null | head -5
