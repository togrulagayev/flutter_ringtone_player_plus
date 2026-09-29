import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_ringtone_player_plus/platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeRingtonePlayerPlatform extends RingtonePlayerPlatform
    with MockPlatformInterfaceMixin {
  final List<(RingtoneSource, PlaybackOptions)> played = [];
  int stopCalls = 0;
  Stream<PlaybackState> states = const Stream.empty();

  @override
  Future<void> play(RingtoneSource source, PlaybackOptions options) async {
    played.add((source, options));
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Stream<PlaybackState> get stateChanges => states;
}

void main() {
  late FakeRingtonePlayerPlatform platform;
  const player = RingtonePlayer();

  setUp(() {
    platform = FakeRingtonePlayerPlatform();
    RingtonePlayerPlatform.instance = platform;
  });

  test('play forwards the source and options', () async {
    const source = RingtoneSource.asset('assets/bell.mp3');
    const options = PlaybackOptions(volume: 0.4, looping: true);

    await player.play(source, options: options);

    expect(platform.played, [(source, options)]);
  });

  test('play rejects a volume outside 0.0 to 1.0', () async {
    for (final volume in [-0.1, 1.1, double.nan]) {
      await expectLater(
        player.play(
          const RingtoneSource.system(RingtoneType.alarm),
          options: PlaybackOptions(volume: volume),
        ),
        throwsRangeError,
      );
    }
    expect(platform.played, isEmpty);
  });

  test('playAlarm loops the default alarm', () async {
    await player.playAlarm(volume: 0.5);

    expect(platform.played.single, (
      const RingtoneSource.system(RingtoneType.alarm),
      const PlaybackOptions(volume: 0.5, looping: true),
    ));
  });

  test('playNotification plays the default notification once', () async {
    await player.playNotification();

    expect(platform.played.single, (
      const RingtoneSource.system(RingtoneType.notification),
      const PlaybackOptions(),
    ));
  });

  test('playRingtone loops the default ringtone', () async {
    await player.playRingtone(looping: false);

    expect(platform.played.single, (
      const RingtoneSource.system(RingtoneType.ringtone),
      const PlaybackOptions(),
    ));
  });

  test('stop reaches the platform', () async {
    await player.stop();

    expect(platform.stopCalls, 1);
  });

  test('stateChanges comes from the platform', () {
    platform.states = Stream.fromIterable([
      PlaybackState.playing,
      PlaybackState.completed,
    ]);

    expect(
      player.stateChanges,
      emitsInOrder([PlaybackState.playing, PlaybackState.completed, emitsDone]),
    );
  });
}
