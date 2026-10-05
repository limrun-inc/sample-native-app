# Night Runners Club

A three-lane endless runner for iOS, built with SwiftUI and a procedural 3D Metal scene. No downloaded models or textures are required: the city, subway tracks, character, hazards, and coins are generated from geometry at runtime.

## Play

Tap **Start Running**. Swipe left or right to change lanes, up to jump barriers, and down to slide under overhead gates. Trains must be avoided by switching lanes. Collect gold coins and travel as far as you can. On-screen controls provide the same actions. Pause at any time; after a collision, tap **Run It Back** to retry. Your best distance is saved on the device.

## Build and test

Use the repository's Limrun CLI workflow (see `.agents/skills/limrun-xcode/SKILL.md` and `.agents/skills/limrun-ios-simulator/SKILL.md`):

```bash
lim xcode build . --scheme sample-native-app
lim ios create --attach
lim xcode test . --scheme sample-native-app
```

Bundle ID: `com.limrun.sample-native`.
