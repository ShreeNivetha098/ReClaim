#!/usr/bin/env bash
# Builds one of the two web sites from this codebase.
#   tool/build_web.sh admin   -> build/web      (reclaim-c4695.web.app, admin dashboard)
#   tool/build_web.sh app     -> build/web_app  (reclaim-app.web.app, student and staff app)
# Deploy afterwards with: firebase deploy --only hosting:<admin|app> --project reclaim-c4695
set -euo pipefail
cd "$(dirname "$0")/.."

case "${1:-}" in
  admin)
    flutter build web --release --dart-define-from-file=firebase_web.json
    ;;
  app)
    out="$PWD/build/web_app"
    flutter build web --release --dart-define-from-file=firebase_web.json \
      --dart-define=APP=user --output "$out"
    # web/index.html and web/manifest.json are written for the admin site.
    sed -i '' -e 's/ReClaim Admin/ReClaim/g' \
      -e 's/ReClaim admin dashboard for campus lost and found/Report, find and claim lost items on the PSG Tech campus/' \
      "$out/index.html" "$out/manifest.json"
    ;;
  *)
    echo "usage: tool/build_web.sh admin|app" >&2
    exit 1
    ;;
esac

# Deploy targets live in .firebaserc, which is not in git; recreate them on a fresh clone.
if ! grep -q '"reclaim-app"' .firebaserc 2>/dev/null; then
  firebase target:apply hosting admin reclaim-c4695 --project reclaim-c4695
  firebase target:apply hosting app reclaim-app --project reclaim-c4695
fi
