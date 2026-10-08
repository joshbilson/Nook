#!/usr/bin/env bash
# Build this Nook fork without an Apple Developer account and install it to /Applications.
# Usage: personal/build-install.sh [--sync]   (--sync merges upstream nook-browser/nook first)
#
# Why the extra steps:
# - Nook.entitlements needs a provisioning profile (push, AutoFill provider), so use Nook-CI.entitlements.
#   Absolute path: the override also reaches the Swift package targets, which resolve it relative to themselves.
# - Ad-hoc signing + hardened runtime makes dyld reject the embedded Sparkle.framework (library validation),
#   so everything is re-signed ad-hoc, inside-out, without --options runtime.
# - Sparkle auto-update would replace this fork with upstream release builds, so it's switched off.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [ "${1:-}" = --sync ]; then
  git remote get-url upstream >/dev/null 2>&1 ||
    git remote add upstream https://github.com/nook-browser/nook.git
  git fetch upstream
  git merge --no-edit upstream/develop
fi

entitlements="$root/Nook/Nook-CI.entitlements"

nice -n 10 xcodebuild -project Nook.xcodeproj -scheme Nook -configuration Release \
  -destination "platform=macOS,arch=arm64" -derivedDataPath build \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER= \
  CODE_SIGN_ENTITLEMENTS="$entitlements" \
  build 2>&1 | tee build-nook.log | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

app=/Applications/Nook.app
osascript -e 'quit app "Nook"' 2>/dev/null || true
rm -rf "$app"
ditto build/Build/Products/Release/Nook.app "$app"

find "$app/Contents/Frameworks" -depth \( -name "*.xpc" -o -name "*.app" -o -name "*.framework" \
  -o -name "*.dylib" -o -path "*/Versions/B/Autoupdate" \) -print0 |
  xargs -0 -n1 codesign --force --sign -
codesign --force --sign - --entitlements "$entitlements" "$app"
codesign --verify --deep --strict "$app"

defaults write com.gstudios.nook SUEnableAutomaticChecks -bool false
defaults write com.gstudios.nook SUAutomaticallyUpdate -bool false

echo "Installed $app"
