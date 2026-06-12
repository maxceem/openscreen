#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="${OPENSCREEN_BUNDLE_ID:-com.siddharthvaddem.openscreen}"
APP_NAME="Openscreen"
USER_DATA_DIR="$HOME/Library/Application Support/openscreen"
RELEASE_APP="$ROOT_DIR/release/$(node -p "require('$ROOT_DIR/package.json').version")/mac/$APP_NAME.app"
REMOVE_INSTALLED_APP=false

usage() {
  cat <<USAGE
Usage: $0 [--remove-installed-app]

Stops Openscreen and resets macOS TCC permissions for $BUNDLE_ID.
By default this keeps recordings and project data in:
  $USER_DATA_DIR
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-installed-app)
      REMOVE_INSTALLED_APP=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

log() {
  printf '%s\n' "$1"
}

reset_tcc() {
  local service="$1"
  if command -v tccutil >/dev/null 2>&1; then
    log "Resetting TCC service $service for $BUNDLE_ID"
    tccutil reset "$service" "$BUNDLE_ID" >/dev/null 2>&1 || true
  fi
}

remove_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    log "Removing $target"
    rm -rf "$target"
  fi
}

log "Stopping running Openscreen processes"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -f "/$APP_NAME.app/Contents/" >/dev/null 2>&1 || true
pkill -f "openscreen-screencapturekit-helper" >/dev/null 2>&1 || true
pkill -f "openscreen-macos-cursor-helper" >/dev/null 2>&1 || true

reset_tcc "AudioCapture"
reset_tcc "ScreenCapture"
reset_tcc "Microphone"
reset_tcc "Camera"
reset_tcc "Accessibility"

log "Removing transient app state and caches"
remove_path "$HOME/Library/Caches/$BUNDLE_ID"
remove_path "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"
remove_path "$HOME/Library/HTTPStorages/$BUNDLE_ID"
remove_path "$HOME/Library/HTTPStorages/$BUNDLE_ID.binarycookies"
remove_path "$HOME/Library/WebKit/$BUNDLE_ID"

if [[ -d "$RELEASE_APP" ]]; then
  log "Clearing quarantine metadata from $RELEASE_APP"
  xattr -cr "$RELEASE_APP" 2>/dev/null || true
fi

if $REMOVE_INSTALLED_APP; then
  remove_path "/Applications/$APP_NAME.app"
  remove_path "$HOME/Applications/$APP_NAME.app"
fi

log "Done. Reopen the exact app bundle you want to test."
