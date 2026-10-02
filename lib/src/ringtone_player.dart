import 'playback_options.dart';
import 'playback_state.dart';
import 'ringtone_exception.dart';
import 'ringtone_player_platform.dart';
import 'ringtone_source.dart';

/// Plays system sounds, Flutter assets and audio files.
///
/// One sound plays at a time: starting a new sound stops the current one.
/// Every instance controls the same underlying player.
///
/// While a sound plays, audio from other apps pauses, except for
/// notification sounds, which play over it. If another app takes over audio
/// playback for good, the sound stops.
class RingtonePlayer {
  /// Creates a player.
  const RingtonePlayer();

  static RingtonePlayerPlatform get _platform =>
      RingtonePlayerPlatform.instance;

  /// Plays [source] with the given [options].
  ///
  /// Completes once playback has started. Throws a [RingtoneException] if the
  /// sound cannot be played, and a [RangeError] if [PlaybackOptions.volume]
  /// is outside 0.0 to 1.0.
  Future<void> play(
    RingtoneSource source, {
    PlaybackOptions options = const PlaybackOptions(),
  }) async {
    final volume = options.volume;
    if (!(volume >= 0 && volume <= 1)) {
      throw RangeError.range(volume, 0, 1, 'volume');
    }
    await _platform.play(source, options);
  }

  /// Plays the default alarm sound, repeating until [stop] is called unless
  /// [looping] is false.
  Future<void> playAlarm({double volume = 1.0, bool looping = true}) => play(
    const RingtoneSource.system(RingtoneType.alarm),
    options: PlaybackOptions(volume: volume, looping: looping),
  );

  /// Plays the default notification sound once.
  Future<void> playNotification({double volume = 1.0}) => play(
    const RingtoneSource.system(RingtoneType.notification),
    options: PlaybackOptions(volume: volume),
  );

  /// Plays the default ringtone, repeating until [stop] is called unless
  /// [looping] is false.
  Future<void> playRingtone({double volume = 1.0, bool looping = true}) => play(
    const RingtoneSource.system(RingtoneType.ringtone),
    options: PlaybackOptions(volume: volume, looping: looping),
  );

  /// Stops the sound that is playing. Does nothing if nothing is playing.
  Future<void> stop() => _platform.stop();

  /// Events for sounds started by any [RingtonePlayer].
  ///
  /// Errors that happen after playback started arrive as
  /// [RingtoneException]s on this stream.
  Stream<PlaybackState> get stateChanges => _platform.stateChanges;
}
