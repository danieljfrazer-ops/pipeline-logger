#!/bin/bash
# Helper to log pipeline runs with auto-captured timestamps
# Usage: ./log-helper.sh --project llm-benchmarks --type FEATURE_BUILD --version 1.0.0

PROJECT=""
TYPE="FEATURE_BUILD"
VERSION=""
STATUS="SUCCESS"
DESCRIPTION=""
TSHIRT=""
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

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2;;
    --type) TYPE="$2"; shift 2;;
    --version) VERSION="$2"; shift 2;;
    --status) STATUS="$2"; shift 2;;
    --description) DESCRIPTION="$2"; shift 2;;
    --tshirt) TSHIRT="$2"; shift 2;;
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
    *) shift;;
  esac
done

CMD="npx tsx ~/projects/pipeline-logger/pipeline-logger-generic.ts --project $PROJECT --type $TYPE --version $VERSION --status $STATUS"

if [ -n "$DESCRIPTION" ]; then
  CMD="$CMD --description '$DESCRIPTION'"
fi

if [ -n "$TSHIRT" ]; then
  CMD="$CMD --tshirt-size $TSHIRT"
fi

if [ -n "$SEVERITY" ]; then
  CMD="$CMD --severity $SEVERITY"
fi

if [ -n "$COMPLEXITY" ]; then
  CMD="$CMD --complexity $COMPLEXITY"
fi

if [ -n "$STARTED_AT" ] && [ -n "$COMPLETED_AT" ]; then
  CMD="$CMD --started-at '$STARTED_AT' --completed-at '$COMPLETED_AT'"
fi

if [ -n "$CODER_MS" ]; then
  CMD="$CMD --coder-ms $CODER_MS"
fi

if [ -n "$TESTER_MS" ]; then
  CMD="$CMD --tester-ms $TESTER_MS"
fi

if [ "$TESTS_PASSED" -gt 0 ]; then
  CMD="$CMD --tests-passed $TESTS_PASSED"
fi

if [ "$TESTS_FAILED" -gt 0 ]; then
  CMD="$CMD --tests-failed $TESTS_FAILED"
fi

if [ "$DEPS" -gt 0 ]; then
  CMD="$CMD --deps $DEPS"
fi

if [ "$API_CHANGES" != "false" ]; then
  CMD="$CMD --api-changes $API_CHANGES"
fi

echo "Running: $CMD"
eval $CMD
