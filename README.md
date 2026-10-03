# flutter_ringtone_player_plus

[![CI](https://github.com/togrulagayev/flutter_ringtone_player_plus/actions/workflows/ci.yml/badge.svg)](https://github.com/togrulagayev/flutter_ringtone_player_plus/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> **Work in progress.** Not published on pub.dev yet. The API below may still change.

Play system ringtones, alarms, notification sounds and custom audio on Android
and iOS, with looping, volume and playback state.

## Usage

```dart
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';

const player = RingtonePlayer();

await player.playAlarm();
await player.playNotification(volume: 0.5);
await player.stop();
```

Play your own sound from an asset or a file, with the same options:

```dart
await player.play(
  const RingtoneSource.asset('assets/sounds/bell.mp3'),
  options: const PlaybackOptions(
    volume: 0.6,
    looping: true,
    usage: SoundUsage.alarm,
  ),
);
```

`player.stateChanges` reports when a sound starts, completes or is stopped.
Failures are thrown as `RingtoneException` with a `RingtoneErrorCode`.

## Why this package

[`flutter_ringtone_player`](https://pub.dev/packages/flutter_ringtone_player)
is a popular package for playing system sounds, but its last release was in
February 2025. Fixes merged after that were never published, and issues such as
Android API 36 support are still open.

`flutter_ringtone_player_plus` is a maintained rewrite: Kotlin and Swift
instead of Java and Objective-C, a type-safe platform channel, tests on every
layer, and a migration path from the original API.

## What gets fixed

Problems found in `flutter_ringtone_player` 4.0.0+4 that this package addresses:

| Problem in the original | Upstream issue |
| --- | --- |
| `play(fromFile: ...)` on its own throws *"Please specify the sound source"* | [#70](https://github.com/inway/flutter_ringtone_player/issues/70) |
| Platform calls are not awaited, so native errors are silently lost | – |
| Plain strings are thrown instead of typed exceptions | – |
| No way to know whether a sound is playing or has finished | [#74](https://github.com/inway/flutter_ringtone_player/issues/74) |
| Volume uses a linear scale, so most values sound the same | [#93](https://github.com/inway/flutter_ringtone_player/issues/93) |
| **Android:** outdated build configuration, no API 36 support | [#98](https://github.com/inway/flutter_ringtone_player/issues/98) |
| **Android:** the player can become `null` after an activity change (e.g. NFC reading) | [#100](https://github.com/inway/flutter_ringtone_player/issues/100) |
| **Android:** an unknown sound type replies twice to the channel and can crash the app | – |
| **Android:** `file://` URIs never resolve | – |
| **Android:** looping and volume are ignored below Android 9 | – |
| **Android:** playback is not released when the engine detaches | – |
| **iOS:** looping is not supported | [#89](https://github.com/inway/flutter_ringtone_player/issues/89) |
| **iOS:** `stop()` does not stop system sounds, and sounds are capped at 30 seconds | – |
| **iOS:** `fromFile` paths are looked up as Flutter assets | – |
| **iOS:** no Swift Package Manager support | – |

## Roadmap

- [x] Project setup: license, strict analysis, CI with secret scanning
- [x] Dart API: sound sources, playback options, typed errors, Pigeon channel
- [x] Android: Kotlin player with looping and volume on every API level
- [x] Android: audio focus, lifecycle handling, playback state
- [x] iOS: Swift player based on `AVAudioPlayer`, with playback state
- [x] iOS: interruptions, privacy manifest, Swift Package Manager and CocoaPods
- [ ] Example app and integration tests
- [ ] Compatibility layer and migration guide from `flutter_ringtone_player`
- [ ] Full CI: platform builds, pub.dev score check, coverage
- [ ] macOS and web support
- [ ] 1.0.0 release

## Credits

Based on the ideas and API of
[flutter_ringtone_player](https://github.com/inway/flutter_ringtone_player)
by InWay.pro, released under the MIT license.

## License

[MIT](LICENSE)
