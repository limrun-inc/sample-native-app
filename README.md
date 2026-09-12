# Sample Native App

This is a sample iOS app that your coding agent in Linux can build and test using
Limrun with remote XCode & iOS simulator.

## Setup

First, you need to get an API key from [Limrun Console](https://console.limrun.com).

```bash
export LIM_API_KEY=lim_....
```

Install `lim` CLI.

```bash
npm install --global lim
```

That's it! Now, make sure to recognize the skills stored in `.agents/skills` folder
so you know how to use the `lim` CLI to build and test iOS apps.

## Local Builds

If you're on macOS with access to XCode, you can get a simulator build of this
project and upload to Limrun Asset Storage so that you can get simulators
with this app pre-installed.

Build with the following command:
```bash
xcodebuild -project sample-native-app.xcodeproj \
  -scheme sample-native-app \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build \
  build
```

Once completed, archive the `.app` folder.
```bash
tar -czf sample-native-app.app.tar.gz \
  -C build/Build/Products/Debug-iphonesimulator \
  sample-native-app.app
```

Push to Limrun Asset Storage.
```bash
lim push sample-native-app.app.tar.gz
```

Now you can use it in your iOS instances!

```bash
lim run ios --install-asset=sample-native-app.app.tar.gz
```

## XCTest launch validation

The `xctest` project builds the sample app and a UI test target. Its tests check
runner arguments and environment, UI app arguments and environment, and both
text and screenshot attachments. No hosted unit-test target is needed.

Build the products on remote Xcode:

```bash
lim xcode create --hard-timeout 30m
lim xcode run -- 'cd xctest && xcodegen generate && xcodebuild build-for-testing -project SampleNativeValidation.xcodeproj -scheme SampleNativeValidation -destination "generic/platform=iOS Simulator" -derivedDataPath build CODE_SIGNING_ALLOWED=NO'
lim xcode run --no-sync -- 'python3 xctest/configure-products.py xctest/build/Build/Products'
```

`configure-products.py` creates two enabled configurations with distinct UI app
environments. It uses the documented `.xctestrun` keys so the same built bundles
exercise both configurations. Pass the products tree to limulator's
`POST /xctest/run` endpoint. A complete run reports four passes: both test methods
in both configurations. The limrun repository's Limulator Integration workflow
accepts this repository's commit as `sample-native-ref` and handles the remote
build, product sync, test run, and sandbox cleanup.

The sample's usual screen stays unchanged unless launched with
`--limrun-app-value`; that argument makes the received values visible to XCTest.
