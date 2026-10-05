# Sample Native App

This is a simple SwiftUI todo app that your coding agent in Linux can build and test using
Limrun with remote Xcode & iOS simulator. Add tasks, mark them done, filter by status,
and delete them. Tasks are stored on-device and survive app restarts.

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

Build it, attach a simulator, and add a task:

```bash
lim xcode build .
lim ios create --attach
lim ios set-text "Buy groceries" --ax-unique-id todoInput
lim ios tap-element --ax-unique-id addTodoButton
lim ios element-tree --json | rg "Buy groceries"
```

The list displays the new task. Tap its circle to complete it, use the All / Active / Done
filters to browse tasks, or tap its trash button to delete it.

| Element | Identifier |
| --- | --- |
| Remaining count | `remainingCount` |
| Task field | `todoInput` |
| Add button | `addTodoButton` |
| Filters | `filterAll`, `filterActive`, `filterDone` |

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

## Run the UI test

```bash
lim xcode test . --scheme sample-native-app
```

The UI tests cover adding, completing, filtering, deleting, and saving tasks across launches.
