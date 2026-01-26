# Sample Native App

Build with the following command:
```bash
xcodebuild -project sample-native-app.xcodeproj \
  -scheme sample-native-app \                                                                                                           -sdk iphonesimulator \
  -configuration Debug \
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

```ts
const instance = await limrun.iosInstances.create({
  wait: true,
  reuseIfExists: true,
  metadata: {
    labels: {
      name: 'sample-native-app',
    },
  },
  spec: {
    initialAssets: [
      {
        kind: 'App',
        source: 'AssetName',
        assetName: "sample-native-app.app.tar.gz",
      },
    ],
  },
});
```
