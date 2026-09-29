import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RingtoneSource.file', () {
    test('keeps an absolute path as is', () {
      final source = RingtoneSource.file('/data/user/0/app/files/alarm.mp3');

      expect(
        (source as FileRingtoneSource).path,
        '/data/user/0/app/files/alarm.mp3',
      );
    });

    test('converts a file:// URI to a path', () {
      final source = RingtoneSource.file('file:///var/mobile/My%20Sound.m4a');

      expect((source as FileRingtoneSource).path, '/var/mobile/My Sound.m4a');
    });

    test('rejects a relative path', () {
      expect(
        () => RingtoneSource.file('sounds/alarm.mp3'),
        throwsArgumentError,
      );
    });
  });

  test('sources with the same values are equal', () {
    expect(
      const RingtoneSource.system(RingtoneType.alarm),
      const RingtoneSource.system(RingtoneType.alarm),
    );
    expect(
      const RingtoneSource.asset('assets/a.mp3', package: 'sounds'),
      const RingtoneSource.asset('assets/a.mp3', package: 'sounds'),
    );
    expect(RingtoneSource.file('/a.mp3'), RingtoneSource.file('file:///a.mp3'));
    expect(
      const RingtoneSource.asset('assets/a.mp3'),
      isNot(const RingtoneSource.asset('assets/a.mp3', package: 'sounds')),
    );
  });

  group('PlaybackOptions.usageFor', () {
    const options = PlaybackOptions();

    test('matches the system sound by default', () {
      expect(
        options.usageFor(const RingtoneSource.system(RingtoneType.alarm)),
        SoundUsage.alarm,
      );
      expect(
        options.usageFor(const RingtoneSource.system(RingtoneType.ringtone)),
        SoundUsage.ringtone,
      );
      expect(
        options.usageFor(
          const RingtoneSource.system(RingtoneType.notification),
        ),
        SoundUsage.notification,
      );
    });

    test('treats assets and files as notifications by default', () {
      expect(
        options.usageFor(const RingtoneSource.asset('assets/a.mp3')),
        SoundUsage.notification,
      );
      expect(
        options.usageFor(RingtoneSource.file('/a.mp3')),
        SoundUsage.notification,
      );
    });

    test('prefers an explicit usage', () {
      const alarmOptions = PlaybackOptions(usage: SoundUsage.alarm);

      expect(
        alarmOptions.usageFor(const RingtoneSource.asset('assets/a.mp3')),
        SoundUsage.alarm,
      );
    });
  });
}
