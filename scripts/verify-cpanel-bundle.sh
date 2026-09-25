#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
fail=0
check_file(){ if [ ! -f "$ROOT/$1" ]; then echo "MISSING file: $1" >&2; fail=1; else echo "OK file: $1"; fi; }
check_dir(){ if [ ! -d "$ROOT/$1" ]; then echo "MISSING dir:  $1" >&2; fail=1; else echo "OK dir:  $1"; fi; }
check_file server.js
check_file package.json
check_dir node_modules
check_dir .next
check_dir .next/static
check_dir public
check_dir tmp
if [ "$fail" -ne 0 ]; then
  echo "Bundle verification FAILED." >&2
  exit 1
fi
printf '\nBundle verification passed.\n'
printf 'Node: '; node --version 2>/dev/null || echo '(node not in PATH)'
printf 'Size: '; du -sh "$ROOT" 2>/dev/null | awk '{print $1}' || true
