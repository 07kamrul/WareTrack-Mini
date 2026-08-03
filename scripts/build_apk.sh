#!/usr/bin/env bash
#
# Build a release APK for a specific API environment.
#
# Usage:
#   ./scripts/build_apk.sh <API_ENV> <APP_NAME> [APP_VERSION]
#
# Examples:
#   ./scripts/build_apk.sh demo440 標準
#   ./scripts/build_apk.sh jarocClient カスタマイズ1 "Ver 1.0"
#   BUILD_NAME=1.0.2 BUILD_NUMBER=3 ./scripts/build_apk.sh demo440 カスタマイズ1
#
# Valid API_ENV values (ApiEnvironment member names, see
# lib/core/api_services/api_environment.dart):
#   demo440, demo395, jarocClient, jarocDemo, jarocDev
#   demo440Trial, demo395Trial, jarocClientTrial, jarocDemoTrial, jarocDevTrial
#   (any "<base>Trial" value builds a trial APK against that base server's
#    /test route — separate applicationId, see build.gradle.kts)
#
# BUILD_NAME / BUILD_NUMBER (env vars) set the Android versionName / versionCode.
# IMPORTANT: every new APK installed over an existing one must use a HIGHER
# BUILD_NUMBER (versionCode) than the currently installed build, or Android will
# reject the update as a downgrade. Standard and Customized builds share one
# applicationId + one release keystore, so they update each other in place.
#
# Output: build/app/outputs/flutter-apk/<YYYYMMDD>_<API_ENV>_<APP_NAME>_<APP_VERSION>.apk
# (the Gradle task createConfiguredReleaseApk creates the renamed copy).

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <API_ENV> <APP_NAME> [APP_VERSION]" >&2
  exit 1
fi

API_ENV="$1"
APP_NAME="$2"
# Must match the version registered on the API server ('Ver 1.0', with a space).
APP_VERSION="${3:-Ver 1.0}"
# Android versionName / versionCode. Bump BUILD_NUMBER for every new release.
BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

BASE_API_ENVS=(demo440 demo395 jarocClient jarocDemo jarocDev)
VALID_API_ENVS=()
for base in "${BASE_API_ENVS[@]}"; do
  VALID_API_ENVS+=("$base" "${base}Trial")
done

if [[ ! " ${VALID_API_ENVS[*]} " == *" $API_ENV "* ]]; then
  echo "Unknown API_ENV: $API_ENV" >&2
  echo "Valid values: ${VALID_API_ENVS[*]}" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

flutter build apk --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --dart-define=API_ENV="$API_ENV" \
  --dart-define=APP_NAME="$APP_NAME" \
  --dart-define=APP_VERSION="$APP_VERSION"

TODAY="$(date +%Y%m%d)"
# Mirrors appBuildApkDisplayName in android/app/build.gradle.kts, which is
# what actually names the copied APK — keep this echo in sync with that.
APK_DISPLAY_NAME="$APP_NAME"
if [[ "$API_ENV" == *Trial ]]; then
  APK_DISPLAY_NAME="Trial$APP_NAME"
fi
APK_NAME="${TODAY}_${API_ENV}_${APK_DISPLAY_NAME}_${APP_VERSION}.apk"

echo ""
echo "APK built: build/app/outputs/flutter-apk/$APK_NAME"
