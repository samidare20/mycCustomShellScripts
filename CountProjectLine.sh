#!/bin/bash

set -euo pipefail

# Usage:
#   ./CountProjectLine.sh [exclude_pattern]
#   ./CountProjectLine.sh -s
#
# Behavior:
# - No args: exclude Markdown (.md), count total lines of Git-tracked files,
#   append one line to the fixed log file ($HOME/line_count.log) including current working directory
#   (if the count is 0, the value is recorded as "Empty"), and print that exact line.
# - Arg 1: regex pattern to exclude (default: \\.md$)
# - -s | --show: print only log lines for the current working directory (no counting). Log path is fixed.

# Fixed log file path
LOG_FILE="$HOME/line_count.log"

# Show mode: print log content filtered by current directory and exit
if [[ ${1:-} == "-s" || ${1:-} == "--show" ]]; then
  if [[ -f "$LOG_FILE" ]]; then
    # Use fixed-string match to avoid regex issues; include directory delimiters around PWD
    grep -F " - $PWD - " "$LOG_FILE" || true
  fi
  exit 0
fi

EXCLUDE_PATTERN=${1:-"\\.md$"}

# Ensure inside a Git repository; otherwise print a notice and exit.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a Git repository. Exiting." >&2
  exit 1
fi

# Ensure log file directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Compute total line count of tracked files excluding the pattern
COUNT=$(git ls-files \
  | { grep -Ev "$EXCLUDE_PATTERN" || true; } \
  | xargs -r cat \
  | wc -l \
  | awk '{print $1}')

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# If count is zero, store as "Empty"; otherwise keep numeric count
if [[ "$COUNT" -eq 0 ]]; then
  RESULT_VALUE="Empty"
else
  RESULT_VALUE="$COUNT"
fi

LINE_OUTPUT="$TIMESTAMP - $PWD - $RESULT_VALUE"

# Append to log file
printf '%s\n' "$LINE_OUTPUT" >>"$LOG_FILE"

# Print exactly the appended line to stdout
printf '%s\n' "$LINE_OUTPUT"
