import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sources describe themselves', () {
    expect(
      const RingtoneSource.system(RingtoneType.alarm).toString(),
      'RingtoneSource.system(alarm)',
    );
    expect(
      const RingtoneSource.system(
        RingtoneType.notification,
        iosSound: IosSystemSound.glass,
      ).toString(),
      'RingtoneSource.system(notification, iosSound: glass)',
    );
    expect(
      const RingtoneSource.asset('assets/bell.mp3').toString(),
      'RingtoneSource.asset(assets/bell.mp3)',
    );
    expect(
      const RingtoneSource.asset(
        'assets/bell.mp3',
        package: 'sounds',
      ).toString(),
      'RingtoneSource.asset(assets/bell.mp3, package: sounds)',
    );
    expect(
      RingtoneSource.file('/tmp/bell.wav').toString(),
      'RingtoneSource.file(/tmp/bell.wav)',
    );
  });

  test('equal sources have equal hash codes', () {
    expect(
      const RingtoneSource.system(RingtoneType.ringtone).hashCode,
      const RingtoneSource.system(RingtoneType.ringtone).hashCode,
    );
    expect(
      const RingtoneSource.asset('a.mp3', package: 'p').hashCode,
      const RingtoneSource.asset('a.mp3', package: 'p').hashCode,
    );
    expect(
      RingtoneSource.file('/a.mp3').hashCode,
      RingtoneSource.file('file:///a.mp3').hashCode,
    );
  });

  test('playback options compare by value', () {
    const options = PlaybackOptions(
      volume: 0.5,
      looping: true,
      usage: SoundUsage.media,
    );

    expect(
      options,
      const PlaybackOptions(
        volume: 0.5,
        looping: true,
        usage: SoundUsage.media,
      ),
    );
    expect(
      options.hashCode,
      const PlaybackOptions(
        volume: 0.5,
        looping: true,
        usage: SoundUsage.media,
      ).hashCode,
    );
    expect(options, isNot(const PlaybackOptions(volume: 0.5, looping: true)));
    expect(
      options.toString(),
      'PlaybackOptions(volume: 0.5, looping: true, usage: media)',
    );
  });

  test('exceptions include the code and the platform message', () {
    expect(
      const RingtoneException(RingtoneErrorCode.unavailable).toString(),
      'RingtoneException(unavailable)',
    );
    expect(
      const RingtoneException(
        RingtoneErrorCode.sourceNotFound,
        'Asset not found: assets/bell.mp3',
      ).toString(),
      'RingtoneException(sourceNotFound): Asset not found: assets/bell.mp3',
    );
  });
}
