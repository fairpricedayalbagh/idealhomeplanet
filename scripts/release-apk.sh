#!/usr/bin/env bash
#
# release-apk.sh — Build Flutter APK and publish as a GitHub Release
#
# Prerequisites:
#   - flutter CLI on PATH
#   - gh CLI installed and authenticated (gh auth login)
#   - Run from the repo root
#
# Usage:
#   ./scripts/release-apk.sh                          # auto-increment build number
#   ./scripts/release-apk.sh --version 1.2.0          # set specific version
#   ./scripts/release-apk.sh --build-number 5         # set specific build number
#   ./scripts/release-apk.sh --notes "Bug fixes"      # custom release notes
#

set -euo pipefail

# ── Defaults ──
VERSION=""
BUILD_NUMBER=""
NOTES=""
MOBILE_DIR="apps/mobile"
PUBSPEC="$MOBILE_DIR/pubspec.yaml"

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)    VERSION="$2"; shift 2 ;;
    --build-number) BUILD_NUMBER="$2"; shift 2 ;;
    --notes)      NOTES="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ── Read current version from pubspec.yaml ──
CURRENT=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
CURRENT_VERSION=$(echo "$CURRENT" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT" | cut -d'+' -f2)

# Use provided or auto-increment
if [[ -z "$VERSION" ]]; then
  VERSION="$CURRENT_VERSION"
fi

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER=$((CURRENT_BUILD + 1))
fi

TAG="v${VERSION}+${BUILD_NUMBER}"
echo "══════════════════════════════════════"
echo "  Releasing: $TAG"
echo "  Version:   $VERSION"
echo "  Build:     $BUILD_NUMBER"
echo "══════════════════════════════════════"

# ── Step 1: Update pubspec.yaml version ──
echo ""
echo "→ Updating pubspec.yaml..."
sed -i "s/^version: .*/version: ${VERSION}+${BUILD_NUMBER}/" "$PUBSPEC"
echo "  Done: version: ${VERSION}+${BUILD_NUMBER}"

# ── Step 2: Build release APK ──
echo ""
echo "→ Building release APK..."
cd "$MOBILE_DIR"
flutter build apk --release --build-name="$VERSION" --build-number="$BUILD_NUMBER"
cd - > /dev/null

APK_PATH="$MOBILE_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: APK not found at $APK_PATH"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo "  APK built: $APK_PATH ($APK_SIZE)"

# ── Step 3: Git commit and tag ──
echo ""
echo "→ Committing version bump..."
git add "$PUBSPEC"
git commit -m "release: ${TAG}" || echo "  (no changes to commit)"

echo "→ Creating tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"

# ── Step 4: Push to remote ──
echo ""
echo "→ Pushing to origin..."
git push origin main --tags

# ── Step 5: Create GitHub Release ──
echo ""
echo "→ Creating GitHub Release..."

if [[ -z "$NOTES" ]]; then
  NOTES="Release $VERSION (build $BUILD_NUMBER)"
fi

gh release create "$TAG" "$APK_PATH" \
  --title "v${VERSION}" \
  --notes "$NOTES"

RELEASE_URL=$(gh release view "$TAG" --json url -q '.url')
echo ""
echo "══════════════════════════════════════"
echo "  Release published!"
echo "  Tag:  $TAG"
echo "  URL:  $RELEASE_URL"
echo "  APK:  $APK_SIZE"
echo "══════════════════════════════════════"
echo ""
echo "The app will pick up this update automatically."
