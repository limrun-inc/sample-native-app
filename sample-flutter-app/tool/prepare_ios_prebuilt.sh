#!/bin/sh
# Prepare all Flutter artifacts needed for a Debug simulator build on a
# remote Xcode host without a Flutter SDK (e.g. Limrun). Run from the Flutter
# project root on any OS with a Flutter SDK (Linux works).
#
#   ./tool/prepare_ios_prebuilt.sh
#
# Then build remotely with:
#
#   lim xcode build . --include "^ios/Flutter/prebuilt/"
set -e

cd "$(dirname "$0")/.."

FLUTTER_BIN="$(command -v flutter)"
FLUTTER_ROOT="$(dirname "$(dirname "${FLUTTER_BIN}")")"

flutter precache --ios
flutter build bundle --debug --target-platform ios

ENGINE_DIR="${FLUTTER_ROOT}/bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator"
PREBUILT="ios/Flutter/prebuilt"

rm -rf "${PREBUILT}"
mkdir -p "${PREBUILT}"
cp -R "${ENGINE_DIR}/Flutter.framework" "${PREBUILT}/Flutter.framework"
cp -R build/flutter_assets "${PREBUILT}/flutter_assets"

echo "Prebuilt Flutter artifacts staged in ${PREBUILT}."
