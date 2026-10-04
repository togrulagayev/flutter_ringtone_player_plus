import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_ringtone_player_plus/platform_interface.dart';
import 'package:flutter_ringtone_player_plus_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeRingtonePlayerPlatform extends RingtonePlayerPlatform
    with MockPlatformInterfaceMixin {
  final played = <(RingtoneSource, PlaybackOptions)>[];
  final states = StreamController<PlaybackState>.broadcast();
  RingtoneException? error;

  @override
  Future<void> play(RingtoneSource source, PlaybackOptions options) async {
    if (error case final error?) throw error;
    played.add((source, options));
  }

  @override
  Future<void> stop() async {}

  @override
  Stream<PlaybackState> get stateChanges => states.stream;
}

void main() {
  late FakeRingtonePlayerPlatform platform;

  setUp(() {
    platform = FakeRingtonePlayerPlatform();
    RingtonePlayerPlatform.instance = platform;
  });

  testWidgets('plays the selected sound with the chosen options', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.byKey(const ValueKey(DemoSound.ringtone)));
    await tester.tap(find.text('Loop until stopped'));
    await tester.tap(find.byKey(const ValueKey(SoundUsage.media)));
    await tester.pump();
    await tester.tap(find.text('Play'));
    await tester.pump();

    expect(platform.played.single, (
      const RingtoneSource.system(RingtoneType.ringtone),
      const PlaybackOptions(looping: true, usage: SoundUsage.media),
    ));
  });

  testWidgets('shows the playback state', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('State: idle'), findsOneWidget);

    platform.states.add(PlaybackState.playing);
    await tester.pump();

    expect(find.text('State: playing'), findsOneWidget);
  });

  testWidgets('shows errors from the player', (tester) async {
    platform.error = const RingtoneException(
      RingtoneErrorCode.sourceNotFound,
      'No alarm sound is available on this device',
    );
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Play'));
    await tester.pump();

    expect(find.textContaining('No alarm sound is available'), findsOneWidget);
  });
}
