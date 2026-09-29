import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pigeon_ringtone_player.dart';
import 'playback_options.dart';
import 'playback_state.dart';
import 'ringtone_source.dart';

/// The interface that platform implementations of this plugin extend.
///
/// Tests can replace [instance] with a fake to avoid calling native code.
abstract class RingtonePlayerPlatform extends PlatformInterface {
  /// Constructs a platform implementation.
  RingtonePlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static RingtonePlayerPlatform _instance = PigeonRingtonePlayer();

  /// The implementation in use, [PigeonRingtonePlayer] by default.
  static RingtonePlayerPlatform get instance => _instance;

  /// Sets the implementation. It must extend [RingtonePlayerPlatform].
  static set instance(RingtonePlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Plays [source] with [options], stopping the sound that is playing.
  Future<void> play(RingtoneSource source, PlaybackOptions options);

  /// Stops the sound that is playing, if any.
  Future<void> stop();

  /// Playback events for sounds started through this interface.
  Stream<PlaybackState> get stateChanges;
}
