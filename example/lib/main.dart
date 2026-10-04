import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ringtone Player Plus',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const PlayerPage(),
    );
  }
}

enum DemoSound {
  alarm('Alarm'),
  notification('Notification'),
  ringtone('Ringtone'),
  asset('Asset'),
  file('File');

  const DemoSound(this.label);

  final String label;
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, this.player = const RingtonePlayer()});

  final RingtonePlayer player;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static const _chimeAsset = 'assets/sounds/chime.wav';

  late final StreamSubscription<PlaybackState> _states;
  DemoSound _sound = DemoSound.alarm;
  double _volume = 1;
  bool _looping = false;
  SoundUsage? _usage;
  PlaybackState? _state;
  String? _error;

  @override
  void initState() {
    super.initState();
    _states = widget.player.stateChanges.listen(
      (state) => setState(() {
        _state = state;
        _error = null;
      }),
      onError: (Object error) => setState(() => _error = '$error'),
    );
  }

  @override
  void dispose() {
    unawaited(_states.cancel());
    super.dispose();
  }

  Future<RingtoneSource> _source() async => switch (_sound) {
    DemoSound.alarm => const RingtoneSource.system(RingtoneType.alarm),
    DemoSound.notification => const RingtoneSource.system(
      RingtoneType.notification,
    ),
    DemoSound.ringtone => const RingtoneSource.system(RingtoneType.ringtone),
    DemoSound.asset => const RingtoneSource.asset(_chimeAsset),
    DemoSound.file => RingtoneSource.file(await _chimeFile()),
  };

  Future<String> _chimeFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/chime.wav');
    if (!await file.exists()) {
      final data = await rootBundle.load(_chimeAsset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  Future<void> _play() => _run(() async {
    await widget.player.play(
      await _source(),
      options: PlaybackOptions(
        volume: _volume,
        looping: _looping,
        usage: _usage,
      ),
    );
  });

  Future<void> _stop() => _run(widget.player.stop);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on RingtoneException catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ringtone Player Plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sound', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sound in DemoSound.values)
                ChoiceChip(
                  key: ValueKey(sound),
                  label: Text(sound.label),
                  selected: _sound == sound,
                  onSelected: (_) => setState(() => _sound = sound),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Volume ${(_volume * 100).round()}%',
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loop until stopped'),
            value: _looping,
            onChanged: (value) => setState(() => _looping = value),
          ),
          const SizedBox(height: 8),
          Text('Usage', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Default'),
                selected: _usage == null,
                onSelected: (_) => setState(() => _usage = null),
              ),
              for (final usage in SoundUsage.values)
                ChoiceChip(
                  key: ValueKey(usage),
                  label: Text(_capitalize(usage.name)),
                  selected: _usage == usage,
                  onSelected: (_) => setState(() => _usage = usage),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _play,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'State: ${_state?.name ?? 'idle'}',
            style: theme.textTheme.bodyLarge,
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

String _capitalize(String value) => value[0].toUpperCase() + value.substring(1);
