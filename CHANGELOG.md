## Unreleased

- Project setup: MIT license, package metadata, strict analysis and CI with
  secret scanning.
- New API: `RingtonePlayer`, `RingtoneSource` (system, asset, file),
  `PlaybackOptions` with perceptual volume, looping and `SoundUsage`, a
  `PlaybackState` stream and typed `RingtoneException`s.
- Platform channel generated with Pigeon.
- Requires Dart 3.11 / Flutter 3.41 or newer.
- Android: native player built on `MediaPlayer`. Looping and volume work on
  every supported Android version, `file://` URIs and compressed assets are
  handled, and a missing default sound falls back to another sound on the
  device.
- Android: audio focus while a sound plays (other apps duck for notification
  sounds and pause otherwise), `stateChanges` events, and finished sounds
  release their player automatically.
