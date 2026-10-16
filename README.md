# Metro Dash

A colorful, three-lane endless runner for iPhone, built entirely with SwiftUI and Canvas. Race down the tracks, collect coins, and beat your best score.

## How to play

- Tap **LET'S RUN** to start.
- Swipe left or right to change tracks.
- Swipe up (or tap) to jump over barriers; swipe down to slide under signs.
- Switch lanes to avoid trains and collect coins. One collision ends the run.
- Use the pause button to stop and resume. Your best score is saved on-device.

## Build and test

This project uses [Limrun](https://console.limrun.com) for remote Xcode builds and iOS simulator testing.

```bash
npm install --global lim
lim login
lim xcode build . --scheme sample-native-app
lim ios create --attach
lim xcode test . --scheme sample-native-app
```
