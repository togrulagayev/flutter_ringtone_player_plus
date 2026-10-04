import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../playback_options.dart';
import '../ringtone_exception.dart';
import '../ringtone_player.dart';
import '../ringtone_source.dart';
import 'android_sounds.dart';
import 'ios_sounds.dart';

/// The `FlutterRingtonePlayer` API of the `flutter_ringtone_player` package,
/// running on [RingtonePlayer].
///
/// Unlike the original, calls complete once playback has started and throw a
/// [RingtoneException] when a sound cannot be played, and looping, volume and
/// [stop] also work on iOS.
class FlutterRingtonePlayer {
  /// Creates a player.
  const FlutterRingtonePlayer();

  static const _player = RingtonePlayer();

  static const _iosSounds = {
    1000: IosSystemSound.newMail,
    1001: IosSystemSound.mailSent,
    1003: IosSystemSound.receivedMessage,
    1004: IosSystemSound.sentMessage,
    1005: IosSystemSound.alarm,
    1006: IosSystemSound.lowPower,
    1007: IosSystemSound.triTone,
    1008: IosSystemSound.chime,
    1009: IosSystemSound.glass,
    1010: IosSystemSound.horn,
    1013: IosSystemSound.bell,
    1014: IosSystemSound.electronic,
  };

  /// Plays a sound.
  ///
  /// On Android, [fromFile] is used if set, then [fromAsset], then [android].
  /// On iOS, [ios] comes first, so a call can play an asset on Android and a
  /// built-in sound on iOS, as in the original package. Without [android],
  /// Android plays the default notification sound.
  ///
  /// [volume] is a linear gain from 0.0 to 1.0, as in the original package.
  /// [asAlarm] plays the sound as an alarm, so it is heard in silent mode.
  Future<void> play({
    AndroidSound? android,
    IosSound? ios,
    String? fromAsset,
    String? fromFile,
    double? volume,
    bool? looping,
    bool? asAlarm,
  }) async {
    final RingtoneSource source;
    if (ios != null && defaultTargetPlatform == TargetPlatform.iOS) {
      source = RingtoneSource.system(
        _ringtoneType(android),
        iosSound: _iosSounds[ios.value],
      );
    } else if (fromFile != null) {
      source = RingtoneSource.file(fromFile);
    } else if (fromAsset != null) {
      source = RingtoneSource.asset(fromAsset);
    } else if (android != null || ios != null) {
      source = RingtoneSource.system(
        _ringtoneType(android),
        iosSound: _iosSounds[ios?.value],
      );
    } else {
      throw ArgumentError('Specify android, ios, fromAsset or fromFile.');
    }
    await _player.play(
      source,
      options: PlaybackOptions(
        volume: volume == null ? 1.0 : math.sqrt(volume),
        looping: looping ?? false,
        usage: asAlarm == true ? SoundUsage.alarm : null,
      ),
    );
  }

  /// Plays the default alarm sound, looping by default.
  Future<void> playAlarm({
    double? volume,
    bool looping = true,
    bool asAlarm = true,
  }) => play(
    android: AndroidSounds.alarm,
    ios: IosSounds.alarm,
    volume: volume,
    looping: looping,
    asAlarm: asAlarm,
  );

  /// Plays the default notification sound.
  Future<void> playNotification({
    double? volume,
    bool? looping,
    bool asAlarm = false,
  }) => play(
    android: AndroidSounds.notification,
    ios: IosSounds.triTone,
    volume: volume,
    looping: looping,
    asAlarm: asAlarm,
  );

  /// Plays the default ringtone, looping by default.
  Future<void> playRingtone({
    double? volume,
    bool looping = true,
    bool asAlarm = false,
  }) => play(
    android: AndroidSounds.ringtone,
    ios: IosSounds.electronic,
    volume: volume,
    looping: looping,
    asAlarm: asAlarm,
  );

  /// Stops the sound that is playing.
  Future<void> stop() => _player.stop();

  static RingtoneType _ringtoneType(AndroidSound? sound) =>
      switch (sound?.value) {
        1 => RingtoneType.alarm,
        3 => RingtoneType.ringtone,
        _ => RingtoneType.notification,
      };
}
