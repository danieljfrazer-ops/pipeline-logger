#!/bin/bash
# Smart Pipeline Logger - Auto-captures metrics and infers T-shirt size
# Usage: See help

set -e

LOGGER="npx tsx ~/projects/pipeline-logger/pipeline-logger-generic.ts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Parse arguments
PROJECT=""
TYPE="FEATURE_BUILD"
VERSION=""
STATUS="SUCCESS"
DESCRIPTION=""
SEVERITY=""
COMPLEXITY=""
STARTED_AT=""
COMPLETED_AT=""
CODER_MS=""
TESTER_MS=""
TESTS_PASSED=0
TESTS_FAILED=0
DEPS=0
API_CHANGES="false"
SPEC_FILE=""
AUTO_TSHIRT=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2;;
    --type) TYPE="$2"; shift 2;;
    --version) VERSION="$2"; shift 2;;
    --status) STATUS="$2"; shift 2;;
    --description) DESCRIPTION="$2"; shift 2;;
    --severity) SEVERITY="$2"; shift 2;;
    --complexity) COMPLEXITY="$2"; shift 2;;
    --started-at) STARTED_AT="$2"; shift 2;;
    --completed-at) COMPLETED_AT="$2"; shift 2;;
    --coder-ms) CODER_MS="$2"; shift 2;;
    --tester-ms) TESTER_MS="$2"; shift 2;;
    --tests-passed) TESTS_PASSED="$2"; shift 2;;
    --tests-failed) TESTS_FAILED="$2"; shift 2;;
    --deps) DEPS="$2"; shift 2;;
    --api-changes) API_CHANGES="$2"; shift 2;;
    --spec) SPEC_FILE="$2"; shift 2;;
    --no-auto-tshirt) AUTO_TSHIRT=false; shift;;
    --tshirt) TSHIRT="$2"; shift 2;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --project NAME           Project name (required)"
      echo "  --type TYPE              FEATURE_BUILD, BUG_FIX, MAINTENANCE"
      echo "  --version VERSION       Version number"
      echo "  --status STATUS         SUCCESS, FAILED"
      echo "  --description DESC       Description"
      echo "  --severity SEV          low, medium, high, critical (for bugs)"
      echo "  --complexity NUM         1-5 complexity"
      echo "  --started-at ISO         Start timestamp"
      echo "  --completed-at ISO      End timestamp"
      echo "  --coder-ms MS           Coder time in ms"
      echo "  --tester-ms MS          Tester time in ms"
      echo "  --tests-passed N        Tests passed"
      echo "  --tests-failed N        Tests failed"
      echo "  --deps N                Dependencies affected"
      echo "  --api-changes true/false API changes made"
      echo "  --spec FILE             Path to spec file (triggers auto T-shirt)"
      echo "  --tshirt SIZE           Manual T-shirt (XS,S,M,L,XL)"
      echo "  --no-auto-tshirt        Disable auto T-shirt sizing"
      echo ""
      echo "Auto T-shirt logic:"
      echo "  BUG_FIX: severity low=S, medium=M, high=L, critical=XL"
      echo "  FEATURE_BUILD with spec: size based on spec complexity"
      echo "  FEATURE_BUILD without spec: S or M"
      exit 0
      ;;
    *) shift;;
  esac
done

if [ -z "$PROJECT" ]; then
  warn "Missing --project"
  exit 1
fi

# === AUTO T-SHIRT SIZING ===
if [ "$AUTO_TSHIRT" = true ] && [ -z "$TSHIRT" ]; then
  TSHIRT_INFERRED=false
  
  if [ "$TYPE" = "BUG_FIX" ]; then
    # Bug fixes: infer from severity
    case "$SEVERITY" in
      low) TSHIRT="XS"; TSHIRT_INFERRED=true; warn "Inferred T-shirt: $TSHIRT (low severity)" ;;
      medium) TSHIRT="S"; TSHIRT_INFERRED=true; warn "Inferred T-shirt: $TSHIRT (medium severity)" ;;
      high) TSHIRT="M"; TSHIRT_INFERRED=true; warn "Inferred T-shirt: $TSHIRT (high severity)" ;;
      critical) TSHIRT="L"; TSHIRT_INFERRED=true; warn "Inferred T-shirt: $TSHIRT (critical severity)" ;;
      *)
        TSHIRT="S"
        TSHIRT_INFERRED=true
        warn "Inferred T-shirt: $TSHIRT (default for bug)" ;;
    esac
    
  elif [ "$TYPE" = "FEATURE_BUILD" ]; then
    # Features: check for spec file or description
    if [ -n "$SPEC_FILE" ] && [ -f "$SPEC_FILE" ]; then
      # Analyze spec file for complexity
      SPEC_LINES=$(wc -l < "$SPEC_FILE" 2>/dev/null || echo 0)
      
      if [ "$SPEC_LINES" -lt 100 ]; then
        TSHIRT="S"
      elif [ "$SPEC_LINES" -lt 300 ]; then
        TSHIRT="M"
      elif [ "$SPEC_LINES" -lt 600 ]; then
        TSHIRT="L"
      else
        TSHIRT="XL"
      fi
      
      TSHIRT_INFERRED=true
      warn "Inferred T-shirt: $TSHIRT (spec file: $SPEC_LINES lines)"
      
    elif [ -n "$DESCRIPTION" ]; then
      # Analyze description for complexity keywords
      DESC_LOWER=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')
      
      if echo "$DESC_LOWER" | grep -qE "simple|basic|small|quick"; then
        TSHIRT="S"
      elif echo "$DESC_LOWER" | grep -qE "complex|full|extensive|large|redesign"; then
        TSHIRT="L"
      elif echo "$DESC_LOWER" | grep -qE "moderate|medium"; then
        TSHIRT="M"
      else
        TSHIRT="M"  # Default for features
      fi
      
      TSHIRT_INFERRED=true
      warn "Inferred T-shirt: $TSHIRT (from description)"
    fi
  fi
fi

# Build command
CMD="$LOGGER --project $PROJECT --type $TYPE --version $VERSION --status $STATUS"

[ -n "$DESCRIPTION" ]    && CMD="$CMD --description '$DESCRIPTION'"
[ -n "$TSHIRT" ]          && CMD="$CMD --tshirt-size $TSHIRT"
[ -n "$SEVERITY" ]        && CMD="$CMD --severity $SEVERITY"
[ -n "$COMPLEXITY" ]      && CMD="$CMD --complexity $COMPLEXITY"
[ -n "$STARTED_AT" ]      && CMD="$CMD --started-at '$STARTED_AT'"
[ -n "$COMPLETED_AT" ]    && CMD="$CMD --completed-at '$COMPLETED_AT'"
[ -n "$CODER_MS" ]        && CMD="$CMD --coder-ms $CODER_MS"
[ -n "$TESTER_MS" ]       && CMD="$CMD --tester-ms $TESTER_MS"
[ "$TESTS_PASSED" -gt 0 ] && CMD="$CMD --tests-passed $TESTS_PASSED"
[ "$TESTS_FAILED" -gt 0 ] && CMD="$CMD --tests-failed $TESTS_FAILED"
[ "$DEPS" -gt 0 ]         && CMD="$CMD --deps $DEPS"
[ "$API_CHANGES" != "false" ] && CMD="$CMD --api-changes $API_CHANGES"

log "Logging pipeline run..."
log "Project: $PROJECT"
log "Type: $TYPE"
[ -n "$TSHIRT" ] && log "T-Shirt: $TSHIRT"
[ -n "$VERSION" ] && log "Version: $VERSION"
[ -n "$DESCRIPTION" ] && log "Description: $DESCRIPTION"

# Run
eval $CMD

log "Done!"
