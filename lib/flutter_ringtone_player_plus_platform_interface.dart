import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ringtone_player_plus_method_channel.dart';

abstract class FlutterRingtonePlayerPlusPlatform extends PlatformInterface {
  /// Constructs a FlutterRingtonePlayerPlusPlatform.
  FlutterRingtonePlayerPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRingtonePlayerPlusPlatform _instance = MethodChannelFlutterRingtonePlayerPlus();

  /// The default instance of [FlutterRingtonePlayerPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterRingtonePlayerPlus].
  static FlutterRingtonePlayerPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterRingtonePlayerPlusPlatform] when
  /// they register themselves.
  static set instance(FlutterRingtonePlayerPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
