import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PlayerPage());
  }
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  final RingtonePlayer _player = const RingtonePlayer();

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on RingtoneException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_ringtone_player_plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<PlaybackState>(
            stream: _player.stateChanges,
            builder: (context, snapshot) => Text(
              'State: ${snapshot.data?.name ?? 'idle'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _run(context, _player.playAlarm),
            child: const Text('Alarm'),
          ),
          FilledButton(
            onPressed: () => _run(context, _player.playNotification),
            child: const Text('Notification'),
          ),
          FilledButton(
            onPressed: () => _run(context, _player.playRingtone),
            child: const Text('Ringtone'),
          ),
          OutlinedButton(
            onPressed: () => _run(context, _player.stop),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
