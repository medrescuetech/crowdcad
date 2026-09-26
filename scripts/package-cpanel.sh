#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f .next/standalone/server.js ]; then
  echo "Missing .next/standalone/server.js. Run 'npm run build' first." >&2
  exit 1
fi

rm -rf dist-cpanel
mkdir -p dist-cpanel/.next

# Next.js standalone output includes the minimal production node_modules tree.
cp -a .next/standalone/. dist-cpanel/
cp -a .next/static dist-cpanel/.next/static

if [ -d public ]; then
  cp -a public dist-cpanel/public
fi

# Include small deployment helpers; these do not contain secrets or source app code.
mkdir -p dist-cpanel/scripts
for helper in scripts/verify-cpanel-bundle.sh scripts/restart-cpanel.sh scripts/install-cpanel.sh; do
  if [ -f "$helper" ]; then cp -a "$helper" dist-cpanel/scripts/; fi
done
for doc in CPANEL_DEPLOYMENT.md CPANEL_QUICKSTART.md; do
  if [ -f "$doc" ]; then cp -a "$doc" dist-cpanel/; fi
done

# cPanel/Passenger-friendly restart marker directory.
mkdir -p dist-cpanel/tmp

cat > dist-cpanel/CPANEL_RUNTIME.txt <<'RUNTIME'
CrowdCAD cPanel runtime bundle

Application root: directory containing server.js
Application startup file: server.js
Node version: 20.x recommended
Application mode: Production

Runtime environment variables (set in cPanel, not in the repository):
  HOSTNAME=0.0.0.0
  NODE_ENV=production
  NEXT_TELEMETRY_DISABLED=1
  DISABLE_TELEMETRY=true

Optional contact-form SMTP variables:
  SMTP_HOST=
  SMTP_PORT=587
  SMTP_USER=
  SMTP_PASS=
  CONTACT_FROM=
  CONTACT_TO=

Important:
NEXT_PUBLIC_* Firebase values are compiled into the bundle by GitHub Actions.
Changing those only in cPanel will NOT update the browser bundle; change the
GitHub repository variables and rebuild the artifact.
RUNTIME

# Prevent accidental inclusion of source maps that may expose source code unless desired.
find dist-cpanel -type f -name '*.map' -delete || true

echo "cPanel bundle created at: $ROOT/dist-cpanel"
du -sh dist-cpanel
