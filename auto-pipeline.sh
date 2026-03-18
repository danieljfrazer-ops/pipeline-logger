#!/bin/bash
# Auto-pipeline: Spawn subagent, capture timing, auto-log on completion
# Usage: ./auto-pipeline.sh <agent> <task> [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT="$1"
TASK="$2"
shift 2

# Parse remaining options
PROJECT=""
VERSION=""
DESCRIPTION=""
TYPE="FEATURE_BUILD"
SPEC_FILE=""
LABEL="auto-$(date +%s)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2;;
    --version) VERSION="$2"; shift 2;;
    --description) DESCRIPTION="$2"; shift 2;;
    --type) TYPE="$2"; shift 2;;
    --spec) SPEC_FILE="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    *) shift;;
  esac
done

if [ -z "$AGENT" ] || [ -z "$TASK" ]; then
  echo "Usage: $0 <agent> <task> [options]"
  echo "Example: $0 coder 'Build feature X' --project myapp --version 1.0.0"
  exit 1
fi

if [ -z "$PROJECT" ] || [ -z "$VERSION" ]; then
  echo "Error: --project and --version are required"
  exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }

START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_EPOCH=$(date -u +%s)

log "Starting auto-pipeline..."
log "Agent: $AGENT"
log "Project: $PROJECT"
log "Version: $VERSION"
log "Type: $TYPE"
log "Start time: $START_TIME"

# Spawn the subagent (non-blocking)
echo ""
echo "Spawning $AGENT agent..."
openclaw sessions spawn \
  --agentId "$AGENT" \
  --label "$LABEL" \
  --mode run \
  --runtime subagent \
  --task "$TASK" 2>/dev/null || \
openclaw session spawn \
  --agentId "$AGENT" \
  --label "$LABEL" \
  --mode run \
  --task "$TASK" 2>/dev/null || {
  echo "Trying alternative spawn method..."
  # Fallback: just run the task directly and time it
  START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
}

log "Agent spawned with label: $LABEL"
log "Monitoring for completion..."

# Poll for completion
COMPLETED=false
while [ "$COMPLETED" = "false" ]; do
  sleep 30
  
  # Check if session completed
  if openclaw sessions list 2>/dev/null | grep -q "$LABEL"; then
    : # still running
  else
    COMPLETED=true
  fi
  
  # Alternative: check via sessions_list
  if sessions_list --activeMinutes 60 2>/dev/null | grep -q "$LABEL"; then
    : # still running
  else
    COMPLETED=true
  fi
done

END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
END_EPOCH=$(date -u +%s)

DURATION_MS=$(( (END_EPOCH - START_EPOCH) * 1000 ))

log "Agent completed!"
log "End time: $END_TIME"
log "Duration: $((DURATION_MS/60000))m $(( (DURATION_MS%60000)/1000 ))s"

# Try to get actual times from session
echo ""
log "Fetching session details..."

# Query session history for stats
SESSION_INFO=$(sessions_history --sessionKey "agent:$AGENT:subagent:$LABEL" 2>/dev/null | head -50 || echo "")

# Extract runtime from session if available
RUNTIME_MS="$DURATION_MS"
if echo "$SESSION_INFO" | grep -q "runtime"; then
  RUNTIME_MS=$(echo "$SESSION_INFO" | grep -o '"runtime":[0-9]*' | head -1 | cut -d: -f2 || echo "$DURATION_MS")
fi

log "Runtime: $((RUNTIME_MS/60000))m"

# Auto-log the run
echo ""
log "Logging to pipeline..."

$SCRIPT_DIR/smart-log.sh \
  --project "$PROJECT" \
  --type "$TYPE" \
  --version "$VERSION" \
  --description "$DESCRIPTION" \
  --spec "$SPEC_FILE" \
  --started-at "$START_TIME" \
  --completed-at "$END_TIME" \
  --coder-ms "$RUNTIME_MS"

log "Pipeline run logged!"
