import 'package:meta/meta.dart';

import 'ringtone_player.dart';
import 'ringtone_source.dart';

/// How the system treats a sound: which volume applies to it and whether it
/// is heard in silent mode.
enum SoundUsage {
  /// An alarm. It is heard even when the device is in silent mode.
  alarm,

  /// A notification. It is silenced in silent mode.
  notification,

  /// An incoming call. It is silenced in silent mode.
  ringtone,

  /// Media playback, controlled by the media volume.
  media,
}

/// Settings for a single [RingtonePlayer.play] call.
@immutable
class PlaybackOptions {
  /// Creates playback options.
  const PlaybackOptions({this.volume = 1.0, this.looping = false, this.usage});

  /// Loudness from 0.0 (silent) to 1.0 (full), relative to the device volume
  /// for [usage].
  ///
  /// The scale is perceptual rather than linear, so 0.5 sounds noticeably
  /// quieter than 1.0 instead of almost the same.
  final double volume;

  /// Whether the sound repeats until [RingtonePlayer.stop] is called.
  final bool looping;

  /// How the system treats the sound.
  ///
  /// Defaults to [SoundUsage.alarm] for [RingtoneType.alarm],
  /// [SoundUsage.ringtone] for [RingtoneType.ringtone] and
  /// [SoundUsage.notification] for everything else.
  final SoundUsage? usage;

  /// The [SoundUsage] that applies when playing [source]: [usage] if set,
  /// otherwise the default for that source.
  SoundUsage usageFor(RingtoneSource source) =>
      usage ??
      switch (source) {
        SystemRingtoneSource(type: RingtoneType.alarm) => SoundUsage.alarm,
        SystemRingtoneSource(type: RingtoneType.ringtone) =>
          SoundUsage.ringtone,
        _ => SoundUsage.notification,
      };

  @override
  bool operator ==(Object other) =>
      other is PlaybackOptions &&
      other.volume == volume &&
      other.looping == looping &&
      other.usage == usage;

  @override
  int get hashCode => Object.hash(volume, looping, usage);

  @override
  String toString() =>
      'PlaybackOptions(volume: $volume, looping: $looping, usage: ${usage?.name})';
}
