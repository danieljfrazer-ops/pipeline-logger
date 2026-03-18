#!/bin/bash
# Auto-log from subagent completion
# Usage: ./auto-log.sh <session-key> [options]

SESSION_KEY="$1"
shift

if [ -z "$SESSION_KEY" ]; then
  echo "Usage: $0 <session-key> --project NAME --version 1.0.0 [--type FEATURE_BUILD]"
  exit 1
fi

# Get session info from sessions_history
# This would need to query the session data

echo "Auto-logging from session: $SESSION_KEY"
echo "Note: Full automation requires integration with OpenClaw session events"
echo ""
echo "For now, use this workflow:"
echo "1. Spawn subagent with --label my-run"
echo "2. Note start time"
echo "3. Wait for completion"
echo "4. Run: smart-log.sh --project X --version 1.0.0 --started-at 'ISO' --completed-at 'ISO'"
