#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(node -p "require('$ROOT_DIR/package.json').version")"
APP_PATH="${1:-$ROOT_DIR/release/$VERSION/mac/Openscreen.app}"
ENTITLEMENTS="$ROOT_DIR/macos.entitlements"

find_codesign_identity() {
  local identities
  identities="$(security find-identity -v -p codesigning)"

  if [[ -n "${OPENSCREEN_CODESIGN_IDENTITY:-}" ]]; then
    if grep -Fq "$OPENSCREEN_CODESIGN_IDENTITY" <<<"$identities"; then
      printf '%s\n' "$OPENSCREEN_CODESIGN_IDENTITY"
      return 0
    fi

    echo "Code signing identity not found: $OPENSCREEN_CODESIGN_IDENTITY" >&2
    return 1
  fi

  local identity
  identity="$(awk -F '"' '/"Apple Development: / { print $2; exit }' <<<"$identities")"
  if [[ -n "$identity" ]]; then
    printf '%s\n' "$identity"
    return 0
  fi

  identity="$(awk -F '"' '/"Mac Developer: / { print $2; exit }' <<<"$identities")"
  if [[ -n "$identity" ]]; then
    printf '%s\n' "$identity"
    return 0
  fi

  identity="$(awk -F '"' '/"/ && !/valid identities found/ { print $2; exit }' <<<"$identities")"
  if [[ -n "$identity" ]]; then
    printf '%s\n' "$identity"
    return 0
  fi

  echo "No valid code signing identities found." >&2
  return 1
}

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

IDENTITY="$(find_codesign_identity)"

echo "Clearing quarantine metadata: $APP_PATH"
xattr -cr "$APP_PATH" 2>/dev/null || true

echo "Signing $APP_PATH"
echo "Identity: $IDENTITY"
codesign \
  --force \
  --deep \
  --sign "$IDENTITY" \
  --options runtime \
  --timestamp=none \
  --entitlements "$ENTITLEMENTS" \
  "$APP_PATH"

echo "Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=2 "$APP_PATH"
