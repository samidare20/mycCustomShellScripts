#!/bin/bash

set -euo pipefail

# Color setup for terminal outputs (enabled only when stdout is a TTY)
if [[ -t 1 ]]; then
  COLOR_CYAN=$'\033[36m'
  COLOR_GREEN=$'\033[32m'
  COLOR_RED=$'\033[31m'
  COLOR_YELLOW=$'\033[33m'
  COLOR_BOLD=$'\033[1m'
  COLOR_RESET=$'\033[0m'
else
  COLOR_CYAN=""
  COLOR_GREEN=""
  COLOR_RED=""
  COLOR_YELLOW=""
  COLOR_BOLD=""
  COLOR_RESET=""
fi

# Usage:
#   ./CountProjectLine.sh [exclude_pattern]
#   ./CountProjectLine.sh -s
#
# Behavior:
# - No args: exclude Markdown (.md), count total lines of Git-tracked files,
#   append one line to the fixed log file ($HOME/line_count.log) in the format:
#   PATH - TIMESTAMP - VALUE (VALUE becomes "Empty" if zero), and print that exact line.
# - Arg 1: regex pattern to exclude (default: \\.md$)
# - -s | --show: print only log lines for the current working directory (no counting). Log path is fixed.

# Fixed log file path
LOG_FILE="$HOME/line_count.log"

# Show mode: print current directory once, then log content filtered by current directory (time - value) and exit
if [[ ${1:-} == "-s" || ${1:-} == "--show" ]]; then
  if [[ -n "$COLOR_RESET" ]]; then
    printf '%b\n' "${COLOR_BOLD}${COLOR_CYAN}${PWD}${COLOR_RESET}"
  else
    printf '%s\n' "$PWD"
  fi
  if [[ -f "$LOG_FILE" ]]; then
    if [[ -n "$COLOR_RESET" ]]; then
      awk -v p="$PWD" \
          -v c_time="$COLOR_GREEN" \
          -v c_inc="$COLOR_GREEN" \
          -v c_dec="$COLOR_RED" \
          -v c_empty="$COLOR_YELLOW" \
          -v c_reset="$COLOR_RESET" \
          -F ' - ' '
          $1==p{
            vStr=$3;
            v=(vStr=="Empty"?0:vStr+0);
            if (vStr=="Empty") {
              vc=c_empty;
            } else if (havePrev && v<prev){
              vc=c_dec;
            } else {
              vc=c_inc;
            }
            printf "%s%s%s - %s%s%s\n", c_time, $2, c_reset, vc, vStr, c_reset;
            prev=v; havePrev=1;
          }' "$LOG_FILE"
    else
      awk -v p="$PWD" -F ' - ' '$1 == p { print $2 " - " $3 }' "$LOG_FILE"
    fi
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
# Use NUL-separated pipeline to safely handle paths with spaces or special characters
COUNT=$(git ls-files -z \
  | { grep -zEv "$EXCLUDE_PATTERN" || true; } \
  | xargs -0 -r cat \
  | wc -l \
  | awk '{print $1}')

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# If count is zero, store as "Empty"; otherwise keep numeric count
if [[ "$COUNT" -eq 0 ]]; then
  RESULT_VALUE="Empty"
else
  RESULT_VALUE="$COUNT"
fi

# Prepare previous value for this path (if any)
if [[ -f "$LOG_FILE" ]]; then
  LAST_LINE=$(awk -v p="$PWD" -F ' - ' '$1==p{last=$0} END{print last}' "$LOG_FILE")
else
  LAST_LINE=""
fi

PREV_NUM=""
if [[ -n "${LAST_LINE}" ]]; then
  PREV_VAL=$(printf '%s\n' "$LAST_LINE" | awk -F ' - ' '{print $3}')
  if [[ "$PREV_VAL" == "Empty" ]]; then
    PREV_NUM=0
  else
    PREV_NUM="$PREV_VAL"
  fi
fi

LINE_OUTPUT_RAW="$PWD - $TIMESTAMP - $RESULT_VALUE"

# When printing to terminal, colorize: path bold-cyan, timestamp green, value green or yellow (Empty)
if [[ -t 1 && -n "$COLOR_RESET" ]]; then
  if [[ "$RESULT_VALUE" == "Empty" ]]; then
    VALUE_COLOR="$COLOR_YELLOW"
  else
    VALUE_COLOR="$COLOR_GREEN"
    if [[ -n "${PREV_NUM}" ]]; then
      if (( COUNT < PREV_NUM )); then
        VALUE_COLOR="$COLOR_RED"
      else
        VALUE_COLOR="$COLOR_GREEN"
      fi
    fi
  fi
  LINE_OUTPUT_COLORED="${COLOR_BOLD}${COLOR_CYAN}$PWD${COLOR_RESET} - ${COLOR_GREEN}$TIMESTAMP${COLOR_RESET} - ${VALUE_COLOR}$RESULT_VALUE${COLOR_RESET}"
else
  LINE_OUTPUT_COLORED="$LINE_OUTPUT_RAW"
fi

# LAST_LINE prepared above

if [[ -n "${LAST_LINE}" ]]; then
  LAST_VALUE=$(printf '%s\n' "$LAST_LINE" | awk -F ' - ' '{print $3}')
  if [[ "$LAST_VALUE" == "$RESULT_VALUE" ]]; then
    # Find line number of the last occurrence for this path and replace it with the new timestamp
    LINE_NO=$(awk -v p="$PWD" -F ' - ' '$1==p{n=NR} END{print n+0}' "$LOG_FILE")
    awk -v ln="$LINE_NO" -v nl="$LINE_OUTPUT_RAW" 'NR==ln{print nl; next} {print $0}' "$LOG_FILE" >"$LOG_FILE.tmp"
    mv "$LOG_FILE.tmp" "$LOG_FILE"
    printf '%s\n' "$LINE_OUTPUT_COLORED"
    exit 0
  fi
fi

# Append to log file if not updated
printf '%s\n' "$LINE_OUTPUT_RAW" >>"$LOG_FILE"

# Print exactly the written line to stdout
printf '%s\n' "$LINE_OUTPUT_COLORED"
