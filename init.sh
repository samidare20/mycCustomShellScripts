#!/usr/bin/env bash

set -euo pipefail

ZSHRC="${HOME}/.zshrc"

# Resolve absolute path to main.sh relative to this init.sh (for removing old entries)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/main.sh"

# Previously added variants to clean up (absolute, $HOME-anchored, and relative ./)
SUBPATH="${TARGET#${HOME}}"
OLD_LINE_ABS="[ -f \"${TARGET}\" ] && source \"${TARGET}\""
OLD_LINE_HOME="[ -f \"\\$HOME${SUBPATH}\" ] && source \"\\$HOME${SUBPATH}\""
OLD_LINE_REL='[ -f "./main.sh" ] && source "./main.sh"'

# Desired: use the absolute path of the CURRENT SHELL directory at install time
CURRENT_PWD="$(pwd -P)"
ABS_TARGET="${CURRENT_PWD}/main.sh"
if [[ -f "${ABS_TARGET}" ]]; then
  FINAL_TARGET="${ABS_TARGET}"
else
  # Fallback to script-dir main.sh if current PWD doesn't contain it
  FINAL_TARGET="${TARGET}"
fi

LINE_TO_ADD="[ -f \"${FINAL_TARGET}\" ] && source \"${FINAL_TARGET}\""

# Ensure ~/.zshrc exists
touch "${ZSHRC}"

# Remove previously added variants to avoid duplicates (use grep -F to avoid awk escape warnings)
if ! grep -Fvx -e "${OLD_LINE_ABS}" -e "${OLD_LINE_HOME}" -e "${OLD_LINE_REL}" -- "${ZSHRC}" > "${ZSHRC}.tmp"; then
  # If no lines were output (grep exit 1), still update to an empty file
  : > "${ZSHRC}.tmp"
fi
mv "${ZSHRC}.tmp" "${ZSHRC}"

# Append only if the exact relative line is not already present
if ! grep -Fqx "${LINE_TO_ADD}" "${ZSHRC}"; then
  printf '\n%s\n' "${LINE_TO_ADD}" >> "${ZSHRC}"
  echo "Added to ${ZSHRC}: ${LINE_TO_ADD}"
else
  echo "Already present in ${ZSHRC}"
fi
