#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: bash scripts/install-cpanel.sh /home/USER/crowdcad" >&2
  exit 2
fi
if [ ! -f "$SOURCE/server.js" ] || [ ! -d "$SOURCE/.next/static" ]; then
  echo "Run this script from an extracted CrowdCAD cPanel runtime ZIP." >&2
  exit 2
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd -P)"
if [ "$TARGET" = "$SOURCE" ] || [ "$TARGET" = / ] || [ "$TARGET" = "${HOME:-/nonexistent}" ]; then
  echo "Choose a separate cPanel application directory." >&2
  exit 2
fi
if [ -e "$TARGET/server.js" ]; then
  BACKUP="$(dirname "$TARGET")/crowdcad-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$BACKUP" -C "$TARGET" .
  echo "Backup: $BACKUP"
fi
# Remove old generated assets after a successful backup to avoid stale Next files.
rm -rf "$TARGET/.next"
cp -a "$SOURCE/." "$TARGET/"
mkdir -p "$TARGET/tmp"
bash "$TARGET/scripts/verify-cpanel-bundle.sh" "$TARGET"
touch "$TARGET/tmp/restart.txt"
echo "Installed in $TARGET. Set the cPanel Node.js application startup file to server.js and restart it."
