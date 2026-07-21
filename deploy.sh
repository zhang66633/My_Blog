#!/bin/bash
set -e

echo "========================================="
echo "  Blog Deploy - Cloudflare + GitHub Pages"
echo "========================================="

# 1. Git commit & push
echo ""
echo "[1/3] Git push..."
CHANGED=$(git diff --name-only)
UNTRACKED=$(git ls-files --others --exclude-standard)

if [ -z "$CHANGED" ] && [ -z "$UNTRACKED" ]; then
  echo "  -> No changes, skipping git commit"
else
  git add -A
  git commit -m "deploy: $(date '+%Y-%m-%d %H:%M')"
  echo "  -> Committed"
fi

BRANCH=$(git branch --show-current)
git push origin "$BRANCH"
echo "  -> Pushed to origin/$BRANCH"
echo "  -> GitHub Pages Actions will auto-deploy"

# 2. Cloudflare Pages deploy
echo ""
echo "[2/3] Cloudflare Pages deploy..."
npx wrangler pages deploy . --project-name=blog --commit-dirty=true --branch="$BRANCH"

# 3. Done
echo ""
echo "[3/3] Done!"
echo "  -> Cloudflare:  https://blog-52h.pages.dev"
echo "  -> GitHub:      https://zhang66633.github.io/My_Blog/"
echo ""
