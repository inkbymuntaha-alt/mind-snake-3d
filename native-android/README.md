# Mind Snake 3D — Native Android
Kotlin + OpenGL ES 3.0; no Unity, Godot, third-party runtime engine, or external assets.

Open this directory in Android Studio or run gradle :app:assembleDebug. APK: app/build/outputs/apk/debug/app-debug.apk.

Thread ownership: Activity/touch code translates gestures only. Simulation state and GL resources belong to the GLSurfaceView renderer thread. Commands cross with queueEvent. Fixed 160ms simulation ticks use capped frame delta. Surface recreation rebuilds shader programs, VAOs and VBOs. Swipes and bottom arrow controls are supported; two turns can be buffered and direct reversals are rejected. High score uses SharedPreferences.

Clarity orbs reduce overload and award 10. Impulse orbs increase overload, award 25 and temporarily accelerate movement. Echo indicators appear above the overload threshold before converting to impulse orbs. Physical-device testing is required before release. CI debug APK is not Play Store signed.
