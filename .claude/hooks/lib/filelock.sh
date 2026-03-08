#!/bin/bash
# Portable file locking for shell hooks.
# Uses mkdir (atomic on all POSIX systems) — works on macOS and Linux.
# Source this file, then use acquire_lock/release_lock around critical sections.
#
# Usage:
#   source "$(dirname "$0")/lib/filelock.sh"
#   if acquire_lock "$STATUS_FILE"; then
#     # ... read-modify-write ...
#     release_lock "$STATUS_FILE"
#   fi

acquire_lock() {
  local target="$1"
  local lockdir="${target}.lock"
  local max_attempts="${2:-25}"  # 25 * 0.2s = 5s timeout
  local i=0

  # Clean stale locks (older than 30 seconds)
  if [ -d "$lockdir" ]; then
    local lock_age
    lock_age="$(find "$lockdir" -maxdepth 0 -mmin +0.5 2>/dev/null)"
    if [ -n "$lock_age" ]; then
      rm -rf "$lockdir" 2>/dev/null
    fi
  fi

  while ! mkdir "$lockdir" 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge "$max_attempts" ]; then
      return 1  # lock acquisition failed
    fi
    sleep 0.2
  done

  # Record PID for diagnostics
  echo $$ > "$lockdir/pid" 2>/dev/null
  return 0
}

release_lock() {
  local target="$1"
  rm -rf "${target}.lock" 2>/dev/null
}
