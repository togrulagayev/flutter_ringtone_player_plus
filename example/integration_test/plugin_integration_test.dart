import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const player = RingtonePlayer();
  const chime = RingtoneSource.asset('assets/sounds/chime.wav');
  late List<PlaybackState> states;
  late StreamSubscription<PlaybackState> subscription;

  setUp(() {
    states = [];
    subscription = player.stateChanges.listen(states.add);
  });

  tearDown(() async {
    await player.stop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await subscription.cancel();
  });

  Future<void> waitForStates(List<PlaybackState> expected) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (states.length < expected.length) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(states, expected);
  }

  testWidgets('plays each default system sound', (_) async {
    for (final type in RingtoneType.values) {
      await player.play(
        RingtoneSource.system(type),
        options: const PlaybackOptions(volume: 0.2, looping: true),
      );
    }

    await waitForStates([
      PlaybackState.playing,
      PlaybackState.stopped,
      PlaybackState.playing,
      PlaybackState.stopped,
      PlaybackState.playing,
    ]);
  });

  testWidgets('plays an asset to the end', (_) async {
    await player.play(chime);

    await waitForStates([PlaybackState.playing, PlaybackState.completed]);
  });

  testWidgets('plays a FLAC asset', (_) async {
    await player.play(const RingtoneSource.asset('assets/sounds/chime.flac'));

    await waitForStates([PlaybackState.playing, PlaybackState.completed]);
  });

  testWidgets('plays a file from the device', (_) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/chime.wav');
    final data = await rootBundle.load('assets/sounds/chime.wav');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    await player.play(RingtoneSource.file(file.uri.toString()));

    await waitForStates([PlaybackState.playing, PlaybackState.completed]);
  });

  testWidgets('loops until stopped', (_) async {
    await player.play(chime, options: const PlaybackOptions(looping: true));
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(states, [PlaybackState.playing]);

    await player.stop();

    await waitForStates([PlaybackState.playing, PlaybackState.stopped]);
  });

  testWidgets('a new sound replaces the current one', (_) async {
    await player.play(chime, options: const PlaybackOptions(looping: true));
    await player.play(chime);

    await waitForStates([
      PlaybackState.playing,
      PlaybackState.stopped,
      PlaybackState.playing,
      PlaybackState.completed,
    ]);
  });

  testWidgets('reports a missing asset', (_) async {
    await expectLater(
      player.play(const RingtoneSource.asset('assets/sounds/missing.wav')),
      throwsA(
        isA<RingtoneException>().having(
          (error) => error.code,
          'code',
          RingtoneErrorCode.sourceNotFound,
        ),
      ),
    );
  });

  testWidgets('reports a missing file', (_) async {
    await expectLater(
      player.play(RingtoneSource.file('/no/such/sound.wav')),
      throwsA(
        isA<RingtoneException>().having(
          (error) => error.code,
          'code',
          RingtoneErrorCode.sourceNotFound,
        ),
      ),
    );
  });
}
