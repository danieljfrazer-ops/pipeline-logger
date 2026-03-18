#!/bin/bash
# Overnight UAT Regression Testing
# Runs tests on all software projects
# Usage: ./overnight-uat.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/pipeline-runs/overnight-uat.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date +"%H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "Starting Overnight UAT Run: $TIMESTAMP"
log "========================================"

# Define projects to test
PROJECTS=(
  "llm-benchmarks:/projects/llm-benchmarks:3003"
  "software-estimator:/projects/software-estimator:3005"
)

RESULTS=()

for PROJECT_INFO in "${PROJECTS[@]}"; do
  IFS=':' read -r PROJECT_NAME PROJECT_PATH PORT <<< "$PROJECT_INFO"
  
  log ""
  log "Testing: $PROJECT_NAME"
  log "Path: $PROJECT_PATH"
  
  # Check if project exists
  if [ ! -d "$PROJECT_PATH" ]; then
    log "⚠ Project not found, skipping"
    continue
  fi
  
  # Check if dev server is running
  if ! curl -s "http://localhost:$PORT" >/dev/null 2>&1; then
    log "⚠ Server not running on port $PORT, attempting to start..."
    # Try to start dev server in background
    (cd "$PROJECT_PATH" && npm run dev >/dev/null 2>&1 &)
    sleep 5
  fi
  
  # Run UAT tests
  START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # For each project, spawn a tester agent for UAT
  log "Spawning UAT tester..."
  
  LABEL="overnight-uat-${PROJECT_NAME}-$(date +%s)"
  
  # Create UAT task based on project type
  if [ "$PROJECT_NAME" = "llm-benchmarks" ]; then
    TASK="Run UAT tests on llm-benchmarks:
1. Visit http://localhost:$PORT
2. Test: Provider filter dropdown works
3. Test: Model table loads
4. Test: Best For column displays
5. Test: Export config modal opens
6. Test: Hardware fit indicator shows
7. Report results to docs/test/overnight_UAT.md"
  elif [ "$PROJECT_NAME" = "software-estimator" ]; then
    TASK="Run UAT tests on software-estimator:
1. Visit http://localhost:$PORT
2. Test: Homepage loads
3. Test: Create new project works
4. Test: Monte Carlo simulation runs
5. Test: Risk analysis displays
6. Report results to docs/test/overnight_UAT.md"
  fi
  
  # Spawn tester (non-blocking)
  openclaw sessions spawn \
    --agentId tester \
    --label "$LABEL" \
    --mode run \
    --runtime subagent \
    --task "$TASK" 2>/dev/null || {
    log "⚠ Could not spawn tester, running basic checks..."
  }
  
  # Wait for tests to complete (or run basic checks)
  sleep 60
  
  # Basic smoke test
  if curl -s "http://localhost:$PORT" | grep -q "<!DOCTYPE html\|<html"; then
    log "✅ $PROJECT_NAME: Server responding"
    RESULTS+=("$PROJECT_NAME:✅")
  else
    log "❌ $PROJECT_NAME: Server not responding"
    RESULTS+=("$PROJECT_NAME:❌")
  fi
  
  END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Log the UAT run
  $SCRIPT_DIR/smart-log.sh \
    --project "$PROJECT_NAME" \
    --type MAINTENANCE \
    --version "overnight-uat" \
    --description "Overnight UAT regression testing" \
    --severity low \
    --started-at "$START_TIME" \
    --completed-at "$END_TIME" \
    2>/dev/null || true
  
  log "Completed: $PROJECT_NAME"
done

log ""
log "========================================"
log "Overnight UAT Complete"
log "========================================"
log "Results:"
for RESULT in "${RESULTS[@]}"; do
  log "  $RESULT"
done

log "Log file: $LOG_FILE"
