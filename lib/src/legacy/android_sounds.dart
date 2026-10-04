import 'flutter_ringtone_player.dart';

/// A default Android sound, as used by [FlutterRingtonePlayer.play].
class AndroidSound {
  /// Creates a sound from its type: 1 for alarm, 2 for notification and 3
  /// for ringtone.
  const AndroidSound(this.value) : assert(value >= 1), assert(value <= 3);

  /// The sound type.
  final int value;
}

/// The default Android sounds.
abstract final class AndroidSounds {
  /// The default alarm sound.
  static const AndroidSound alarm = AndroidSound(1);

  /// The default notification sound.
  static const AndroidSound notification = AndroidSound(2);

  /// The default ringtone.
  static const AndroidSound ringtone = AndroidSound(3);
}
