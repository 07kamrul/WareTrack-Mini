#!/usr/bin/env bash
#
# Build one release APK per API environment.
#
# Usage:
#   ./scripts/build_all_apks.sh
#
# Edit the CONFIGS list below to change which environments are built and
# which app name / version each one uses. Format: API_ENV|APP_NAME|APP_VERSION
#
# Output: build/app/outputs/flutter-apk/<YYYYMMDD>_<API_ENV>_<APP_NAME>_<APP_VERSION>.apk

set -euo pipefail

# Every API environment is built with every app name (標準 and カスタマイズ1).
# Each base environment is paired with its "<base>Trial" counterpart, which
# reaches the same server through its /test route — see ApiEnvironment in
# lib/core/api_services/api_environment.dart. These names are the enum member
# names verbatim and are passed straight through as --dart-define=API_ENV.
API_ENVS=(
  demo440 demo440Trial
  demo395 demo395Trial
  jarocClient jarocClientTrial
  jarocDemo jarocDemoTrial
  jarocDev jarocDevTrial
)
APP_NAMES=(標準 カスタマイズ1)
# Must match the version registered on the API server ('Ver 1.0', with a space).
APP_VERSION="Ver 1.0"
# Android versionName / versionCode applied to every APK in this run.
# Bump BUILD_NUMBER for every new release so updates are not rejected as downgrades.
BUILD_NAME="${BUILD_NAME:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

# Base environments ship both app names; a trial environment only ever ships
# 標準, so カスタマイズ1 is skipped for every "<base>Trial" value.
CONFIGS=()
for env in "${API_ENVS[@]}"; do
  if [[ "$env" == *Trial ]]; then
    CONFIGS+=("$env|標準|$APP_VERSION")
  else
    for name in "${APP_NAMES[@]}"; do
      CONFIGS+=("$env|$name|$APP_VERSION")
    done
  fi
done

cd "$(dirname "$0")/.."

TODAY="$(date +%Y%m%d)"
BUILT=()

for config in "${CONFIGS[@]}"; do
  IFS='|' read -r API_ENV APP_NAME APP_VERSION <<< "$config"

  echo ""
  echo "=== Building $API_ENV ($APP_NAME $APP_VERSION) ==="

  flutter build apk --release \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --dart-define=API_ENV="$API_ENV" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=APP_VERSION="$APP_VERSION"

  # Mirrors appBuildApkDisplayName in android/app/build.gradle.kts, which is
  # what actually names the copied APK — keep this echo in sync with that.
  APK_DISPLAY_NAME="$APP_NAME"
  if [[ "$API_ENV" == *Trial ]]; then
    APK_DISPLAY_NAME="Trial$APP_NAME"
  fi
  BUILT+=("build/app/outputs/flutter-apk/${TODAY}_${API_ENV}_${APK_DISPLAY_NAME}_${APP_VERSION}.apk")
done

echo ""
echo "=== All builds finished ==="
for apk in "${BUILT[@]}"; do
  echo "  $apk"
done
