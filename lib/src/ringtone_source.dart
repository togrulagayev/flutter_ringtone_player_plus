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

/// Where a sound comes from.
@immutable
sealed class RingtoneSource {
  const RingtoneSource();

  /// The device's default sound of the given [type].
  ///
  /// iOS does not expose the sounds the user picked in Settings, so a
  /// built-in system sound of the same kind is played there instead.
  const factory RingtoneSource.system(RingtoneType type) = SystemRingtoneSource;

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
  const SystemRingtoneSource(this.type);

  /// Which default sound to play.
  final RingtoneType type;

  @override
  bool operator ==(Object other) =>
      other is SystemRingtoneSource && other.type == type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'RingtoneSource.system(${type.name})';
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
