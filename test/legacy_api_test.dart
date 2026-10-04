import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_ringtone_player_plus/platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeRingtonePlayerPlatform extends RingtonePlayerPlatform
    with MockPlatformInterfaceMixin {
  final List<(RingtoneSource, PlaybackOptions)> played = [];
  int stopCalls = 0;

  @override
  Future<void> play(RingtoneSource source, PlaybackOptions options) async {
    played.add((source, options));
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Stream<PlaybackState> get stateChanges => const Stream.empty();
}

void main() {
  late FakeRingtonePlayerPlatform platform;
  const player = FlutterRingtonePlayer();

  setUp(() {
    platform = FakeRingtonePlayerPlatform();
    RingtonePlayerPlatform.instance = platform;
  });

  test('playAlarm loops the default alarm as an alarm', () async {
    await player.playAlarm();

    expect(platform.played.single, (
      const RingtoneSource.system(
        RingtoneType.alarm,
        iosSound: IosSystemSound.alarm,
      ),
      const PlaybackOptions(looping: true, usage: SoundUsage.alarm),
    ));
  });

  test('playNotification plays Tri-tone on iOS', () async {
    await player.playNotification();

    expect(platform.played.single, (
      const RingtoneSource.system(
        RingtoneType.notification,
        iosSound: IosSystemSound.triTone,
      ),
      const PlaybackOptions(),
    ));
  });

  test('playRingtone loops Electronic on iOS', () async {
    await player.playRingtone();

    expect(platform.played.single, (
      const RingtoneSource.system(
        RingtoneType.ringtone,
        iosSound: IosSystemSound.electronic,
      ),
      const PlaybackOptions(looping: true),
    ));
  });

  test('keeps the linear volume of the original package', () async {
    await player.playNotification(volume: 0.25);

    expect(platform.played.single.$2.volume, 0.5);
  });

  test('maps Android and iOS sounds to a system source', () async {
    await player.play(
      android: AndroidSounds.notification,
      ios: IosSounds.glass,
    );

    expect(
      platform.played.single.$1,
      const RingtoneSource.system(
        RingtoneType.notification,
        iosSound: IosSystemSound.glass,
      ),
    );
  });

  test('falls back to the default iOS sound for unknown IDs', () async {
    await player.play(android: AndroidSounds.alarm, ios: const IosSound(1023));
    await player.play(android: AndroidSounds.alarm, ios: IosSounds.voicemail);

    expect(platform.played.map((played) => played.$1), [
      const RingtoneSource.system(RingtoneType.alarm),
      const RingtoneSource.system(RingtoneType.alarm),
    ]);
  });

  test('prefers a file, then an asset, then system sounds', () async {
    await player.play(
      fromFile: '/sounds/a.mp3',
      fromAsset: 'assets/b.mp3',
      android: AndroidSounds.alarm,
    );
    await player.play(fromAsset: 'assets/b.mp3', android: AndroidSounds.alarm);

    expect(platform.played.map((played) => played.$1), [
      RingtoneSource.file('/sounds/a.mp3'),
      const RingtoneSource.asset('assets/b.mp3'),
    ]);
  });

  test('on iOS, a built-in sound takes precedence over an asset', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await player.play(fromAsset: 'assets/ringtone.wav', ios: IosSounds.glass);

    expect(
      platform.played.single.$1,
      const RingtoneSource.system(
        RingtoneType.notification,
        iosSound: IosSystemSound.glass,
      ),
    );
  });

  test('on Android, the same call plays the asset', () async {
    await player.play(fromAsset: 'assets/ringtone.wav', ios: IosSounds.glass);

    expect(
      platform.played.single.$1,
      const RingtoneSource.asset('assets/ringtone.wav'),
    );
  });

  test('asAlarm plays any source as an alarm', () async {
    await player.play(fromAsset: 'assets/b.mp3', asAlarm: true);

    expect(platform.played.single.$2.usage, SoundUsage.alarm);
  });

  test('play without a sound is an error', () async {
    await expectLater(player.play(), throwsArgumentError);
    expect(platform.played, isEmpty);
  });

  test('stop reaches the platform', () async {
    await player.stop();

    expect(platform.stopCalls, 1);
  });
}
