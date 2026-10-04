import 'flutter_ringtone_player.dart';

/// A built-in iOS sound identified by its system sound ID, as used by
/// [FlutterRingtonePlayer.play].
///
/// Only the IDs listed in [IosSounds] are played. Other IDs, and
/// [IosSounds.voicemail], which no longer exists on current iOS versions,
/// fall back to the default sound for the Android sound type of the call.
class IosSound {
  /// Creates a sound from its system sound ID.
  const IosSound(this.value) : assert(value >= 1000), assert(value <= 2000);

  /// The system sound ID.
  final int value;
}

/// The built-in iOS sounds.
abstract final class IosSounds {
  /// The "new mail" sound.
  static const IosSound newMail = IosSound(1000);

  /// The "mail sent" sound.
  static const IosSound mailSent = IosSound(1001);

  /// The voicemail sound. Not available on current iOS versions.
  static const IosSound voicemail = IosSound(1002);

  /// The "received message" sound.
  static const IosSound receivedMessage = IosSound(1003);

  /// The "sent message" sound.
  static const IosSound sentMessage = IosSound(1004);

  /// The alarm sound.
  static const IosSound alarm = IosSound(1005);

  /// The "low power" sound.
  static const IosSound lowPower = IosSound(1006);

  /// Tri-tone.
  static const IosSound triTone = IosSound(1007);

  /// Chime.
  static const IosSound chime = IosSound(1008);

  /// Glass.
  static const IosSound glass = IosSound(1009);

  /// Horn.
  static const IosSound horn = IosSound(1010);

  /// Bell.
  static const IosSound bell = IosSound(1013);

  /// Electronic.
  static const IosSound electronic = IosSound(1014);
}
