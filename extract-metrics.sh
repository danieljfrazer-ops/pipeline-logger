#!/bin/bash
# Extract comprehensive metrics from a completed subagent session
# Usage: ./extract-metrics.sh <session-label>

LABEL="$1"
PROJECT="$2"

if [ -z "$LABEL" ]; then
  echo "Usage: $0 <session-label> [project]"
  echo "Example: $0 coder-v3.2.0 llm-benchmarks"
  exit 1
fi

SESSION_KEY=$(openclaw sessions --json 2>/dev/null | \
  jq -r ".sessions[] | select(.label == \"$LABEL\") | .key" 2>/dev/null | head -1)

if [ -z "$SESSION_KEY" ]; then
  echo "Session not found: $LABEL"
  exit 1
fi

echo "=== Session Metrics: $LABEL ==="
echo ""

# Get all messages as JSON
MESSAGES=$(openclaw sessions history "$SESSION_KEY" --json 2>/dev/null)

# Extract timing - look for subagent stats in completion events
echo "📊 Timing:"
echo "$MESSAGES" | jq -r '.messages[] | select(.message.role == "assistant") | .timestamp' 2>/dev/null | head -1 | xargs -I{} echo "  Started: {}"
echo "$MESSAGES" | jq -r '.messages[] | select(.message.role == "user") | .timestamp' 2>/dev/null | tail -1 | xargs -I{} echo "  Completed: {}"

# Try to find runtime from tool results
RUNTIME=$(echo "$MESSAGES" | jq -r '[.messages[] | .details.runtime // .details.durationMs // empty] | add' 2>/dev/null)
if [ -n "$RUNTIME" ] && [ "$RUNTIME" != "null" ]; then
  echo "  Runtime: $((RUNTIME/60000))m $(( (RUNTIME%60000)/1000 ))s"
fi

# Extract test results - look for test report files
echo ""
echo "🧪 Tests:"
TEST_REPORT=$(echo "$MESSAGES" | jq -r '.messages[] | .content[] | select(.text | contains("TEST_REPORT")) | .text' 2>/dev/null | head -1)

if [ -n "$TEST_REPORT" ]; then
  echo "  Test report found in session"
  # Try to extract test counts
  PASSED=$(echo "$MESSAGES" | jq -r '[.messages[] | .content[]? | .text?] | map(select(contains("tests passed") or contains("Tests Passed"))) | .[0]' 2>/dev/null | grep -oE '[0-9]+' | head -1)
  FAILED=$(echo "$MESSAGES" | jq -r '[.messages[] | .content[]? | .text?] | map(select(contains("tests failed") or contains("Tests Failed"))) | .[0]' 2>/dev/null | grep -oE '[0-9]+' | head -1)
  echo "  Passed: ${PASSED:-0}"
  echo "  Failed: ${FAILED:-0}"
else
  echo "  No test report found"
fi

# Look for UAT/Regression test mentions
UAT_TESTS=$(echo "$MESSAGES" | jq -r '.messages[] | .content[]? | select(.text | contains("UAT") or contains("regression") or contains("e2e")) | .text' 2>/dev/null | wc -l)
if [ "$UAT_TESTS" -gt 0 ]; then
  echo "  UAT/Regression tests: $UAT_TESTS mentions"
fi

# Extract code stats
echo ""
echo "💻 Code Stats:"
FILES_CHANGED=$(echo "$MESSAGES" | jq -r '[.messages[] | .content[]? | .text?] | map(select(contains("files changed") or contains("files modified"))) | .[0]' 2>/dev/null | grep -oE '[0-9]+' | head -1)
echo "  Files changed: ${FILES_CHANGED:-?}"

# Look for build status
BUILD_STATUS=$(echo "$MESSAGES" | jq -r '.messages[] | .content[]? | select(.text | contains("built in") or contains("build passed") or contains("build failed")) | .text' 2>/dev/null | head -1 | cut -c1-100)
if [ -n "$BUILD_STATUS" ]; then
  echo "  Build: $BUILD_STATUS"
fi

echo ""
echo "=== Raw Metrics JSON ==="
# Output machine-readable metrics
echo "{"
echo "  \"label\": \"$LABEL\","
echo "  \"sessionKey\": \"$SESSION_KEY\","
echo "  \"runtimeMs\": ${RUNTIME:-0},"
echo "  \"testsPassed\": ${PASSED:-0},"
echo "  \"testsFailed\": ${FAILED:-0},"
echo "  \"filesChanged\": ${FILES_CHANGED:-0},"
echo "  \"hasUAT\": $UAT_TESTS"
echo "}"
