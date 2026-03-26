#!/usr/bin/env bash
# ruff-auto-format: Auto-format Python files after Write/Edit
set -euo pipefail

# Read tool call info from stdin JSON
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Skip if no file path found
[[ -z "$FILE" ]] && exit 0

# Convert path to Windows-native format for ruff (which is a native Windows binary).
# Handles both Unix-style (/c/Users/...) and mixed (C:\Users\...) paths.
if command -v cygpath &>/dev/null; then
  FILE="$(cygpath -w "$FILE")"
else
  # Fallback: replace backslashes with forward slashes
  FILE="${FILE//\\//}"
fi

# Skip non-Python files silently
[[ "$FILE" != *.py ]] && exit 0

# Check ruff is available
command -v ruff &>/dev/null || {
  echo "WARN: ruff not found. Install: pip install ruff" >&2
  exit 0
}

# Format and fix
ruff format "$FILE" 2>&1 || true
ruff check --fix "$FILE" 2>&1 || true

# Report remaining issues for Claude to fix
REMAINING=$(ruff check "$FILE" 2>&1) || true
if echo "$REMAINING" | grep -qvE "All checks passed|found 0 error"; then
  echo "ruff remaining issues in $FILE:" >&2
  echo "$REMAINING" >&2
  exit 2
fi
