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

## Drive the app

The first screen has a name field and a button. Build it, attach a simulator, and drive it:

```bash
lim xcode build .
lim ios create --attach
lim ios set-text "Ada" --ax-unique-id nameField
lim ios tap-element --ax-unique-id greetButton
lim ios element-tree --json | grep "Hello, Ada!"
lim ios app-log com.limrun.sample-native --tail 50 | grep '\[sample\]'
```

The heading changes to `Hello, Ada!` and the app logs `[sample] greeted Ada`.

| Element | Identifier |
| --- | --- |
| Heading | `greeting` |
| Name field | `nameField` |
| Say hello button | `greetButton` |

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

## Run the tests

The scheme has a unit test target, with XCTest and Swift Testing cases, and a UI test target.

```bash
lim xcode test . --scheme sample-native-app
```

The command builds the tests, runs them on the simulator, and prints one line per test case.
It exits non-zero when a test fails.

### Keep a result bundle with coverage

Add `--result-bundle` to download Xcode's `.xcresult` bundle and `--coverage` to collect line
coverage. Both need `lim` 0.53.0 or later.

```bash
lim xcode test . --scheme sample-native-app --result-bundle Tests.xcresult --coverage
```

To rerun one test class, skip the build. The command reuses the last test build, so it takes
no path or scheme:

```bash
lim xcode test --without-building \
  --only-testing sample-native-appTests/GreeterTests \
  --result-bundle Greeter.xcresult --coverage
```

Read a bundle on a Mac with the tools that ship with Xcode:

```bash
# Test counts and failures
xcrun xcresulttool get test-results summary --path Tests.xcresult

# Line coverage per target and file
xcrun xccov view --report Tests.xcresult

# The screenshot that the UI test attaches
xcrun xcresulttool export attachments --path Tests.xcresult --output-path attachments
```

See [Run XCTest suites](https://docs.limrun.com/docs/testing/xctest) for every option.
