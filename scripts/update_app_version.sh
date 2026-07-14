#!/usr/bin/env bash
# Usage: ./scripts/update_app_version.sh <version> <build_number> [force_update] [changelog]
#
# Updates the app_versions row in Supabase so all connected clients
# instantly see a new update is available.
#
# Prerequisites:
#   SUPABASE_URL and SUPABASE_SERVICE_KEY env vars set.
#
# Examples:
#   ./scripts/update_app_version.sh 1.1.0 3 false "Corrections de bugs et améliorations"
#   ./scripts/update_app_version.sh 1.2.0 4 true "Mise à jour de sécurité obligatoire"

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <version> <build_number> [force_update] [changelog]"
  exit 1
fi

VERSION="$1"
BUILD_NUMBER="$2"
FORCE_UPDATE="${3:-false}"
CHANGELOG="${4:-}"

: "${SUPABASE_URL:?Must set SUPABASE_URL}"
: "${SUPABASE_SERVICE_KEY:?Must set SUPABASE_SERVICE_KEY}"

PAYLOAD=$(cat <<EOF
{
  "version": "$VERSION",
  "build_number": $BUILD_NUMBER,
  "force_update": $FORCE_UPDATE,
  "changelog": $( [ -n "$CHANGELOG" ] && echo "\"$CHANGELOG\"" || echo null )
}
EOF
)

echo "Upserting app version: $VERSION (build $BUILD_NUMBER, force=$FORCE_UPDATE)"

curl -s -X POST "${SUPABASE_URL}/rest/v1/app_versions" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" \
  -d "$PAYLOAD" | head -c 200

echo ""
echo "Done."
