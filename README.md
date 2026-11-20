# MIND SNAKE 3D

A free, offline-playable psychological 3D snake game for Android, built with Godot 4.7.2 (GDScript; no paid assets or third-party runtime services).

## Features
- Grid-based 3D snake with smoothed segment movement.
- Swipe input and on-screen directional controls.
- Clarity orbs reduce Overload; Impulse orbs increase score, speed and Overload.
- Echo hazards spawn as Overload rises.
- Camera FOV and micro-shake respond to the Mind State.
- Procedurally generated ambient synth tone shifts upward with Overload (no audio asset required).
- Menu, pause, game-over, restart and locally saved best score.
- Android portrait preset; UI scales with the viewport.

## Project layout
- `.github/workflows/android-build.yml`: automated Android APK build
- `scenes/main.tscn`: main 3D scene
- `scripts/`: modular GDScript systems
- `project.godot`: project settings and autoloads

## Open in Godot
1. Install Godot **4.7.2 stable** (standard, not .NET).
2. Import `project.godot`.
3. Press F5 to run the project.

## Android export locally
1. Install Android export templates matching Godot 4.7.2.
2. Configure Java 17 and Android SDK in Editor Settings.
3. Open Project → Export → Android and export `build/MindSnake-debug.apk`.

## GitHub Actions
Push to `main` or run the workflow manually. The workflow installs Java/Android SDK, downloads matching Godot export templates, runs a headless editor import/check, exports a debug APK, and uploads it as an artifact. This avoids installing the Android SDK on your own computer/phone; GitHub-hosted runners do the build.

The workflow builds a **debug APK** for testing. For store distribution, configure a private release keystore using GitHub Actions secrets and create a separate signed release pipeline. Never commit signing credentials.

## Controls
- Swipe up/down/left/right anywhere in the play area.
- Or use the four on-screen arrow buttons.
- Tap pause to pause; resume or restart from the pause panel.

## Notes
- No network permission, ads, analytics, accounts or paid dependencies.
- The game is designed for portrait Android. Desktop preview uses the same touch fallback buttons; keyboard controls can be added later.
