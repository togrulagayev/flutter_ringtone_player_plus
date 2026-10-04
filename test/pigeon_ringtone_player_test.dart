import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_ringtone_player_plus/src/messages.g.dart';
import 'package:flutter_ringtone_player_plus/src/pigeon_ringtone_player.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHostApi extends Fake implements RingtonePlayerHostApi {
  final List<PlatformPlayRequest> requests = [];
  int stopCalls = 0;
  PlatformException? error;

  @override
  Future<void> play(PlatformPlayRequest request) async {
    if (error case final error?) throw error;
    requests.add(request);
  }

  @override
  Future<void> stop() async {
    if (error case final error?) throw error;
    stopCalls++;
  }
}

void main() {
  late FakeHostApi hostApi;
  late PigeonRingtonePlayer player;

  setUp(() {
    hostApi = FakeHostApi();
    player = PigeonRingtonePlayer(hostApi: hostApi);
  });

  group('play builds the request', () {
    test('for a system sound', () async {
      await player.play(
        const RingtoneSource.system(RingtoneType.alarm),
        const PlaybackOptions(looping: true),
      );

      expect(
        hostApi.requests.single,
        PlatformPlayRequest(
          sourceType: PlatformSourceType.system,
          ringtoneType: PlatformRingtoneType.alarm,
          gain: 1,
          looping: true,
          usage: PlatformSoundUsage.alarm,
        ),
      );
    });

    test('for a system sound with a chosen iOS sound', () async {
      await player.play(
        const RingtoneSource.system(
          RingtoneType.notification,
          iosSound: IosSystemSound.glass,
        ),
        const PlaybackOptions(),
      );

      expect(
        hostApi.requests.single,
        PlatformPlayRequest(
          sourceType: PlatformSourceType.system,
          ringtoneType: PlatformRingtoneType.notification,
          iosSound: PlatformIosSound.glass,
          gain: 1,
          looping: false,
          usage: PlatformSoundUsage.notification,
        ),
      );
    });

    test('for an asset from another package', () async {
      await player.play(
        const RingtoneSource.asset('assets/bell.mp3', package: 'sounds'),
        const PlaybackOptions(usage: SoundUsage.media),
      );

      expect(
        hostApi.requests.single,
        PlatformPlayRequest(
          sourceType: PlatformSourceType.asset,
          path: 'assets/bell.mp3',
          packageName: 'sounds',
          gain: 1,
          looping: false,
          usage: PlatformSoundUsage.media,
        ),
      );
    });

    test('for a file', () async {
      await player.play(
        RingtoneSource.file('file:///tmp/bell.wav'),
        const PlaybackOptions(),
      );

      expect(
        hostApi.requests.single,
        PlatformPlayRequest(
          sourceType: PlatformSourceType.file,
          path: '/tmp/bell.wav',
          gain: 1,
          looping: false,
          usage: PlatformSoundUsage.notification,
        ),
      );
    });
  });

  test('volume is squared into a gain', () async {
    for (final volume in [0.0, 0.1, 0.5, 1.0]) {
      await player.play(
        const RingtoneSource.system(RingtoneType.notification),
        PlaybackOptions(volume: volume),
      );
    }

    expect(hostApi.requests.map((request) => request.gain), [
      0.0,
      closeTo(0.01, 1e-9),
      0.25,
      1.0,
    ]);
  });

  group('platform errors become RingtoneExceptions', () {
    Future<RingtoneException> errorFor(String code) async {
      hostApi.error = PlatformException(code: code, message: 'details');
      try {
        await player.play(
          const RingtoneSource.system(RingtoneType.alarm),
          const PlaybackOptions(),
        );
      } on RingtoneException catch (error) {
        return error;
      }
      fail('play did not throw');
    }

    test('with a matching code', () async {
      expect(
        (await errorFor(errorSourceNotFound)).code,
        RingtoneErrorCode.sourceNotFound,
      );
      expect(
        (await errorFor(errorUnsupportedFormat)).code,
        RingtoneErrorCode.unsupportedFormat,
      );
      expect(
        (await errorFor(errorPlaybackFailed)).code,
        RingtoneErrorCode.playbackFailed,
      );
      expect(
        (await errorFor('channel-error')).code,
        RingtoneErrorCode.unavailable,
      );
    });

    test('keeping the platform message', () async {
      expect((await errorFor(errorPlaybackFailed)).message, 'details');
    });

    test('with playbackFailed for unknown codes', () async {
      expect(
        (await errorFor('something-else')).code,
        RingtoneErrorCode.playbackFailed,
      );
    });

    test('from stop as well', () async {
      hostApi.error = PlatformException(code: 'channel-error');

      await expectLater(
        player.stop(),
        throwsA(
          isA<RingtoneException>().having(
            (error) => error.code,
            'code',
            RingtoneErrorCode.unavailable,
          ),
        ),
      );
    });
  });

  test('stateChanges maps platform states and errors', () {
    final player = PigeonRingtonePlayer(
      hostApi: hostApi,
      platformStates: Stream.fromFutures([
        Future.value(PlatformPlaybackState.playing),
        Future.error(PlatformException(code: errorPlaybackFailed)),
        Future.value(PlatformPlaybackState.stopped),
      ]),
    );

    expect(
      player.stateChanges,
      emitsInOrder([
        PlaybackState.playing,
        emitsError(
          isA<RingtoneException>().having(
            (error) => error.code,
            'code',
            RingtoneErrorCode.playbackFailed,
          ),
        ),
        PlaybackState.stopped,
        emitsDone,
      ]),
    );
  });

  test('stateChanges reports a missing plugin as unavailable', () {
    final player = PigeonRingtonePlayer(
      hostApi: hostApi,
      platformStates: Stream.error(MissingPluginException('No implementation')),
    );

    expect(
      player.stateChanges,
      emitsError(
        isA<RingtoneException>().having(
          (error) => error.code,
          'code',
          RingtoneErrorCode.unavailable,
        ),
      ),
    );
  });
}
