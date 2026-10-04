## 1.0.0

First release: a maintained rewrite of `flutter_ringtone_player`.

- `RingtonePlayer` plays the device's default alarm, notification and ringtone
  sounds, Flutter assets and audio files, with looping, a perceptual volume
  scale and a `SoundUsage` for each sound.
- `stateChanges` reports when a sound starts, completes or is stopped, and
  failures throw a `RingtoneException` with a `RingtoneErrorCode`.
- Android: built on `MediaPlayer`, with looping and volume from API 24 and
  audio focus while a sound plays.
- iOS: built on `AVAudioPlayer`, with an audio session for each `SoundUsage`,
  interruption handling, a choice of built-in sounds through `IosSystemSound`,
  Swift Package Manager support and a privacy manifest.
- `package:flutter_ringtone_player_plus/flutter_ringtone_player.dart` provides
  the API of `flutter_ringtone_player`, so migrating takes one import change.
- Requires Dart 3.11 and Flutter 3.41 or newer.
