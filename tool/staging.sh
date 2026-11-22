#!/usr/bin/env bash
# Fail-closed wrapper for every staging operation. Never touches production.
#
#   tool/staging.sh verify                 # identity checks only
#   tool/staging.sh build                  # staging Flutter Web build
#   tool/staging.sh deploy <targets>       # e.g. firestore:indexes | auth,firestore:rules | functions | hosting
#   tool/staging.sh seed                   # synthetic tenant (needs SEED_*_PASSWORD)
#
# Every Firebase command passes --project explicitly; the .firebaserc
# default (production) is never used.
set -euo pipefail

readonly PROJECT=barberia-staging
readonly PROJECT_NUMBER=169151296960
readonly PRODUCTION=barbershop-ee9c0
readonly SHOP_ID=${SHOP_ID:-barberia-staging}
readonly ALLOWED_TARGETS=" auth firestore firestore:rules firestore:indexes functions hosting "

cd "$(dirname "$0")/.."
FLUTTER=(flutter)
command -v fvm >/dev/null && FLUTTER=(fvm flutter)

die() { echo "staging.sh: $*" >&2; exit 1; }

verify_identity() {
  [[ "$PROJECT" != "$PRODUCTION" ]] || die "staging project equals production"
  local listed
  listed=$(firebase projects:list --json) || die "firebase CLI is not authenticated"
  python3 -c '
import json, sys
projects = json.loads(sys.argv[1])["result"]
match = [p for p in projects if p["projectId"] == sys.argv[2]]
if not match or match[0]["projectNumber"] != sys.argv[3]:
    sys.exit(f"{sys.argv[2]} not accessible or project number != {sys.argv[3]}")
' "$listed" "$PROJECT" "$PROJECT_NUMBER" || die "identity check failed"
  echo "verified: $PROJECT (#$PROJECT_NUMBER)"
}

verify_build() {
  local js=build/web/main.dart.js
  [[ -f $js ]] || die "$js missing; run: tool/staging.sh build"
  grep -q "\"$PROJECT\"" "$js" || die "build does not target $PROJECT"
  ! grep -q "$PRODUCTION" "$js" || die "build references production ($PRODUCTION)"
  echo "verified: build/web targets $PROJECT only"
}

case "${1:-}" in
  verify)
    verify_identity
    ;;
  build)
    verify_identity
    "${FLUTTER[@]}" build web --release \
      --dart-define=FIREBASE_ENV=staging \
      --dart-define=SHOP_ID="$SHOP_ID"
    verify_build
    ;;
  deploy)
    targets=${2:-}
    [[ -n $targets ]] || die "usage: tool/staging.sh deploy <targets>"
    IFS=, read -ra parts <<<"$targets"
    for t in "${parts[@]}"; do
      [[ $ALLOWED_TARGETS == *" $t "* ]] || die "target '$t' not allowed"
    done
    verify_identity
    [[ ",$targets," != *",hosting,"* ]] || verify_build
    firebase deploy --only "$targets" --project "$PROJECT" --non-interactive
    ;;
  seed)
    verify_identity
    python3 backend/scripts/seed_staging.py --project "$PROJECT" \
      --confirm-project "$PROJECT" --shop "$SHOP_ID"
    ;;
  *)
    sed -n 2,9p "$0"; exit 2
    ;;
esac
