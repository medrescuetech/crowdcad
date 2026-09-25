#!/usr/bin/env bash
set -euo pipefail
mkdir -p tmp
touch tmp/restart.txt
echo "Restart marker updated: $(date -Is)"
