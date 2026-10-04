import 'package:meta/meta.dart';

/// A kind of default sound provided by the operating system.
enum RingtoneType {
  /// The default alarm sound.
  alarm,

  /// The default notification sound.
  notification,

  /// The default ringtone.
  ringtone,
}

/// A built-in iOS sound that [RingtoneSource.system] can play on iOS.
enum IosSystemSound {
  /// The "new mail" sound.
  newMail,

  /// The "mail sent" sound.
  mailSent,

  /// The "received message" sound.
  receivedMessage,

  /// The "sent message" sound.
  sentMessage,

  /// The alarm sound. The default for [RingtoneType.alarm].
  alarm,

  /// The "low power" sound.
  lowPower,

  /// Tri-tone. The default for [RingtoneType.notification].
  triTone,

  /// Chime.
  chime,

  /// Glass.
  glass,

  /// Horn.
  horn,

  /// Bell.
  bell,

  /// Electronic. The default for [RingtoneType.ringtone].
  electronic,
}

/// Where a sound comes from.
@immutable
sealed class RingtoneSource {
  const RingtoneSource();

  /// The device's default sound of the given [type].
  ///
  /// On Android, if the user has not set a default of that type, another
  /// sound available on the device is played. iOS does not expose the sounds
  /// the user picked in Settings, so a built-in sound is played there instead:
  /// [iosSound] if set, otherwise the default listed in [IosSystemSound].
  const factory RingtoneSource.system(
    RingtoneType type, {
    IosSystemSound? iosSound,
  }) = SystemRingtoneSource;

  /// An audio file bundled with the app as a Flutter asset, such as
  /// `assets/sounds/bell.mp3`.
  ///
  /// Set [package] when the asset belongs to another package.
  const factory RingtoneSource.asset(String name, {String? package}) =
      AssetRingtoneSource;

  /// An audio file on the device, given as an absolute path or a `file://`
  /// URI.
  factory RingtoneSource.file(String path) = FileRingtoneSource;
}

/// A [RingtoneSource] that plays one of the device's default sounds.
final class SystemRingtoneSource extends RingtoneSource {
  /// Creates a source for the default sound of the given [type].
  const SystemRingtoneSource(this.type, {this.iosSound});

  /// Which default sound to play.
  final RingtoneType type;

  /// The built-in sound to play on iOS, or null for the default of [type].
  final IosSystemSound? iosSound;

  @override
  bool operator ==(Object other) =>
      other is SystemRingtoneSource &&
      other.type == type &&
      other.iosSound == iosSound;

  @override
  int get hashCode => Object.hash(type, iosSound);

  @override
  String toString() => iosSound == null
      ? 'RingtoneSource.system(${type.name})'
      : 'RingtoneSource.system(${type.name}, iosSound: ${iosSound!.name})';
}

/// A [RingtoneSource] that plays a Flutter asset.
final class AssetRingtoneSource extends RingtoneSource {
  /// Creates a source for the asset [name], optionally from [package].
  const AssetRingtoneSource(this.name, {this.package});

  /// The asset path as declared in `pubspec.yaml`.
  final String name;

  /// The package that owns the asset, or null for the app's own assets.
  final String? package;

  @override
  bool operator ==(Object other) =>
      other is AssetRingtoneSource &&
      other.name == name &&
      other.package == package;

  @override
  int get hashCode => Object.hash(name, package);

  @override
  String toString() => package == null
      ? 'RingtoneSource.asset($name)'
      : 'RingtoneSource.asset($name, package: $package)';
}

/// A [RingtoneSource] that plays a file from the device's storage.
final class FileRingtoneSource extends RingtoneSource {
  /// Creates a source for [path], which may also be a `file://` URI.
  ///
  /// Throws an [ArgumentError] if [path] is not absolute.
  FileRingtoneSource(String path) : path = _normalize(path);

  /// The absolute path of the file.
  final String path;

  static String _normalize(String path) {
    final normalized = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    if (!normalized.startsWith('/')) {
      throw ArgumentError.value(
        path,
        'path',
        'Must be an absolute path or a file:// URI',
      );
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) =>
      other is FileRingtoneSource && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'RingtoneSource.file($path)';
}
