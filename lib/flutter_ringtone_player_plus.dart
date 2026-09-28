
import 'flutter_ringtone_player_plus_platform_interface.dart';

class FlutterRingtonePlayerPlus {
  Future<String?> getPlatformVersion() {
    return FlutterRingtonePlayerPlusPlatform.instance.getPlatformVersion();
  }
}
