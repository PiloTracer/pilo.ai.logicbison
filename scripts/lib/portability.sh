#!/usr/bin/env bash
# portability.sh — host-portability helpers shared by Agent OS scripts.
#
# Purpose: resolve an interpreter by *executing* it, never by `command -v`
# alone. On Windows `python3` frequently resolves to the Microsoft Store
# App Execution Alias stub: a real file on PATH, so an existence check
# succeeds while running it prints a store advert and exits non-zero.
# Python's own docs state the `python3` command on Windows "is intended to
# catch accidental uses of the typical POSIX command ... but is not meant to
# be widely used or recommended".
#
# Sourced by scripts/*.sh. No side effects; safe under `set -euo pipefail`.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/portability.sh"
#   PY="$(portable_find_python)" || { echo "no python" >&2; exit 3; }

# portable_find_python — print the first interpreter that ACTUALLY RUNS.
# Probes `python3`, `python`, `py` (Windows launcher, needs `-3`) and
# `py -3`. Prints the command line to use; exit 1 when none works.
portable_find_python() {
  local c
  for c in python3 python py; do
    if [ "$c" = "py" ]; then
      if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
        printf 'py -3\n'
        return 0
      fi
      continue
    fi
    if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys" >/dev/null 2>&1; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

# portable_require_python — same, but exits 3 with a clear diagnostic.
# Call in scripts that cannot function without an interpreter.
portable_require_python() {
  local found
  found="$(portable_find_python)" || {
    echo "FATAL: no working Python interpreter found." >&2
    echo "       Tried python3, python, py -3. Install Python 3.9+ and ensure" >&2
    echo "       it runs (a Microsoft Store alias stub does not count)." >&2
    exit 3
  }
  printf '%s\n' "$found"
}

# portable_require_bash — Agent OS scripts are bash-3.2 clean by design so
# they also run on stock macOS (which ships bash 3.2 at /bin/bash).
portable_require_bash() {
  local major="${BASH_VERSINFO[0]:-0}"
  if [ "$major" -lt 3 ]; then
    echo "FATAL: bash >= 3.2 required (found ${BASH_VERSION:-unknown})." >&2
    exit 3
  fi
}
