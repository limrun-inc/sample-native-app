# Sample Native App

This is a sample iOS app that your coding agent in Linux can build and test using
Limrun with remote XCode & iOS simulator.

## Setup

First, you need to get an API key from [Limrun Console](https://console.limrun.com).

```bash
export LIM_API_KEY=lim_....
```

Run the following script which will install dependencies and `lim` CLI.

```bash
./setup-development.sh
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
