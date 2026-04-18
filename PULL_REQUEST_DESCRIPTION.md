# Speedy Circles — iOS Game

A fast-paced tap game built in SwiftUI. Tap circles before the timer runs out to score points!

## Gameplay

https://github.com/limrun-inc/sample-native-app/releases/download/gameplay-demo-v1/speedy-circles-gameplay.mp4

## Features

- **Start Screen** — select a tap interval (2s / 3s / 5s), then press Start
- **Gameplay** — a colored circle appears at a random position; tap it before time runs out
  - Score increments on each successful tap
  - Circle **shrinks** (down to a minimum size), **changes color**, and **moves** to a new random position
  - Timer resets on each tap
  - Real-time score and countdown with a color-coded progress bar (green → orange → red)
- **Game Over** — when the timer expires, final score and a motivational message are shown
- **Play Again** — returns to the start screen with all settings preserved

## Implementation

- `ContentView.swift` — complete game in a single SwiftUI file using the `@Observable` macro
  - `GameViewModel` — owns all game state and timer logic
  - `StartView` — interval selector + start button
  - `GameView` — HUD (score + timer bar) + tappable circle with radial gradient and glow
  - `GameOverView` — final score card with dynamic rating message
- Smooth animations throughout: spring transitions for circle movement, `.easeInOut` for color/size changes, animated timer bar
- Keeps circle within safe screen bounds with a minimum enforced size
- Dark space-themed UI following Apple Design Guidelines

## Smoke Test Results

All 10 automated tests passed:
- Start screen elements present (startButton, interval buttons)
- Game screen shows score + timer on start
- Score increments on circle tap
- Multiple taps build score correctly
- Game over appears after timer expires
- "Play Again" returns to start screen
