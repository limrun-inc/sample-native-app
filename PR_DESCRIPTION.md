# Speedy Circles – Timed Tap iOS Game

## Summary

- Built a complete iOS game called **Speedy Circles** using SwiftUI
- Player selects a time interval (2s, 3s, or 5s) and taps colored circles before the timer runs out
- Score increments on each successful tap; circle shrinks, changes color, and moves to a new random position on each hit
- Game ends when the player misses a tap, displaying the final score and options to retry or return to the menu
- Smooth animations throughout: circle spawn/move (spring), color transitions, score countdown bar, and press feedback

## Features

- **Start Screen** – animated gradient icon, subtitle, interval picker (2s/3s/5s), and Start button
- **Gameplay** – HUD with live score + countdown timer; color-coded progress bar (green → orange → red); colorful gradient circle with radial shine effect; minimum circle size enforced (30pt radius); circle always within safe screen bounds
- **Game Over Screen** – large final score with gradient, "Play Again" and "Back to Menu" actions
- **Apple Design Guidelines** – `.ultraThinMaterial` HUD background, rounded rectangles, system colors, `contentTransition(.numericText())` for score updates, spring animations

## Gameplay Recording

https://github.com/user-attachments/assets/gameplay-demo.mp4

> _Recorded on Limrun cloud iOS simulator_

[gameplay-demo.mp4](gameplay-demo.mp4)
