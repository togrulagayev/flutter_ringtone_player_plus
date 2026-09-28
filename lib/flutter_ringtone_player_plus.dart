import 'flutter_ringtone_player_plus_platform_interface.dart';

/// Plays system ringtones, alarms and notification sounds.
class FlutterRingtonePlayerPlus {
  /// Returns the host platform version.
  Future<String?> getPlatformVersion() {
    return FlutterRingtonePlayerPlusPlatform.instance.getPlatformVersion();
  }
}
