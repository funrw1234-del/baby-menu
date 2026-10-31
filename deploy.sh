#!/usr/bin/env bash
# Publishes scratchpad/site to GitHub Pages as funrw1234-del/baby-menu. The token never gets printed.
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
DST="C:/Users/Leonold/Desktop/GM/baby-menu-site"
OWNER=funrw1234-del
REPO=baby-menu
TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill | sed -n 's/^password=//p')
[ -n "$TOKEN" ] || { echo "no github token"; exit 1; }
API="https://api.github.com"
H1="Authorization: token $TOKEN"
H2="Accept: application/vnd.github+json"

mkdir -p "$DST"
cp "$SRC"/index.html "$SRC"/manifest.webmanifest "$SRC"/sw.js "$SRC"/icon-*.png "$DST"/
touch "$DST/.nojekyll"

# repo (create if missing)
code=$(curl -s -o /dev/null -w "%{http_code}" -H "$H1" -H "$H2" "$API/repos/$OWNER/$REPO")
if [ "$code" = "404" ]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" -H "$H1" -H "$H2" "$API/user/repos" \
    -d "{\"name\":\"$REPO\",\"description\":\"Меню малыша: план питания, дневник стула и продукты\",\"private\":false,\"has_issues\":false,\"has_wiki\":false,\"has_projects\":false}")
  echo "create repo: $code"
else
  echo "repo exists: $code"
fi

cd "$DST"
[ -d .git ] || { git init -q; git checkout -q -b main; }
git config user.name "Leonold"
git config user.email "kellyranevi@gazeta.pl"
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$REPO.git"
git add -A
if git diff --cached --quiet; then echo "nothing to commit"; else
git commit -q -m "$(cat <<'EOF'
Publish baby menu page (PWA)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
fi
git push -q -u origin main 2>&1 | grep -v -i token || true
echo "pushed: $(git rev-parse --short HEAD)"

# pages
code=$(curl -s -o /dev/null -w "%{http_code}" -H "$H1" -H "$H2" "$API/repos/$OWNER/$REPO/pages")
if [ "$code" = "404" ]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" -H "$H1" -H "$H2" "$API/repos/$OWNER/$REPO/pages" -d '{"source":{"branch":"main","path":"/"}}')
  echo "enable pages: $code"
else
  echo "pages already on: $code"
fi
curl -s -H "$H1" -H "$H2" "$API/repos/$OWNER/$REPO/pages" | grep -E '"(html_url|status)"' || true
