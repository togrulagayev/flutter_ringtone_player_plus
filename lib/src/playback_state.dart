import 'ringtone_player.dart';

/// Playback events reported by [RingtonePlayer.stateChanges].
enum PlaybackState {
  /// A sound started playing.
  playing,

  /// A sound that does not loop reached its end.
  completed,

  /// A sound was stopped by [RingtonePlayer.stop], replaced by a new one, or
  /// interrupted by another app that took over audio playback.
  stopped,
}
