import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'flutter_ringtone_player_plus',
    kotlinOut:
        'android/src/main/kotlin/com/togrulagayev/flutter_ringtone_player_plus/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.togrulagayev.flutter_ringtone_player_plus',
    ),
    swiftOut:
        'ios/flutter_ringtone_player_plus/Sources/flutter_ringtone_player_plus/Messages.g.swift',
  ),
)
const String errorSourceNotFound = 'source-not-found';
const String errorUnsupportedFormat = 'unsupported-format';
const String errorPlaybackFailed = 'playback-failed';

enum PlatformSourceType { system, asset, file }

enum PlatformRingtoneType { alarm, notification, ringtone }

enum PlatformSoundUsage { alarm, notification, ringtone, media }

enum PlatformPlaybackState { playing, completed, stopped }

class PlatformPlayRequest {
  PlatformPlayRequest({
    required this.sourceType,
    required this.gain,
    required this.looping,
    required this.usage,
  });

  PlatformSourceType sourceType;
  PlatformRingtoneType? ringtoneType;

  /// Asset name for [PlatformSourceType.asset], absolute file path for
  /// [PlatformSourceType.file].
  String? path;

  /// Package that owns the asset, if it is not the app itself.
  String? packageName;

  /// Linear amplitude between 0.0 and 1.0.
  double gain;
  bool looping;
  PlatformSoundUsage usage;
}

@HostApi()
abstract class RingtonePlayerHostApi {
  @async
  void play(PlatformPlayRequest request);

  void stop();
}

@EventChannelApi()
abstract class RingtonePlayerEventApi {
  PlatformPlaybackState playbackStates();
}
