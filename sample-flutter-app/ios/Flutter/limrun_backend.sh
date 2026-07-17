#!/bin/sh
# Replacement for "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
# for building on a remote Xcode host (Limrun) that has no Flutter SDK and no
# network access inside the build sandbox.
#
# All Flutter artifacts are prebuilt on the developer machine (any OS,
# including Linux) by tool/prepare_ios_prebuilt.sh into ios/Flutter/prebuilt/:
#   - Flutter.framework  (prebuilt engine, simulator slice)
#   - flutter_assets/    (kernel snapshot + assets from `flutter build bundle`)
#
# This script mirrors what `flutter assemble debug_ios_bundle_flutter_assets`
# and `xcode_backend.sh embed_and_thin` do for a Debug simulator build:
#   build: stage Flutter.framework and assemble a stub App.framework
#   embed: copy both frameworks into the app bundle
set -e

PREBUILT="${SRCROOT}/Flutter/prebuilt"

case "$1" in
  build)
    if [ ! -d "${PREBUILT}/Flutter.framework" ] || [ ! -d "${PREBUILT}/flutter_assets" ]; then
      echo "error: ${PREBUILT} is missing. Run tool/prepare_ios_prebuilt.sh before building." >&2
      exit 1
    fi

    mkdir -p "${BUILT_PRODUCTS_DIR}"

    rm -rf "${BUILT_PRODUCTS_DIR}/Flutter.framework"
    cp -R "${PREBUILT}/Flutter.framework" "${BUILT_PRODUCTS_DIR}/Flutter.framework"

    APP_FW="${BUILT_PRODUCTS_DIR}/App.framework"
    rm -rf "${APP_FW}"
    mkdir -p "${APP_FW}"

    # Debug-mode App.framework binary is just a stub dylib; the Dart program
    # is run from the kernel blob in flutter_assets. Same trick flutter_tools
    # uses (see DebugUniversalFramework in flutter_tools).
    ARCH_FLAGS=""
    for arch in ${ARCHS}; do
      ARCH_FLAGS="${ARCH_FLAGS} -arch ${arch}"
    done
    if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then
      MIN_VERSION_FLAG="-mios-simulator-version-min=13.0"
    else
      MIN_VERSION_FLAG="-miphoneos-version-min=13.0"
    fi
    echo "static const int Moo = 88;" | xcrun clang -x c \
      ${ARCH_FLAGS} \
      ${MIN_VERSION_FLAG} \
      -dynamiclib \
      -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
      -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
      -fapplication-extension \
      -install_name '@rpath/App.framework/App' \
      -isysroot "${SDKROOT}" \
      -o "${APP_FW}/App" -

    cp "${SRCROOT}/Flutter/AppFrameworkInfo.plist" "${APP_FW}/Info.plist"
    cp -R "${PREBUILT}/flutter_assets" "${APP_FW}/flutter_assets"
    echo "Staged Flutter.framework and App.framework from ${PREBUILT}."
    ;;

  embed|embed_and_thin)
    FW_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    mkdir -p "${FW_DIR}"
    rsync -8 -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/App.framework" "${FW_DIR}"
    rsync -8 -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/Flutter.framework" "${FW_DIR}/"
    ;;

  *)
    echo "error: unknown limrun_backend.sh subcommand: $1" >&2
    exit 1
    ;;
esac
