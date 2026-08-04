#!/usr/bin/env bash
#
# Build a release APK.
#
# Usage:
#   ./scripts/build_apk.sh
#
# BUILD_NAME / BUILD_NUMBER (env vars) set the Android versionName / versionCode.
# Bump BUILD_NUMBER for every new release so updates are not rejected as downgrades.
#
# Output: build/app/outputs/flutter-apk/app-release.apk

set -euo pipefail

BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

cd "$(dirname "$0")/.."

flutter build apk --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

echo ""
echo "APK built: build/app/outputs/flutter-apk/app-release.apk"
