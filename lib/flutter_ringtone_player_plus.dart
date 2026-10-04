/// Plays system ringtones, alarms, notification sounds and custom audio.
library;

export 'src/playback_options.dart' show PlaybackOptions, SoundUsage;
export 'src/playback_state.dart' show PlaybackState;
export 'src/ringtone_exception.dart' show RingtoneErrorCode, RingtoneException;
export 'src/ringtone_player.dart' show RingtonePlayer;
export 'src/ringtone_source.dart'
    show
        AssetRingtoneSource,
        FileRingtoneSource,
        IosSystemSound,
        RingtoneSource,
        RingtoneType,
        SystemRingtoneSource;
