/// Why a sound could not be played.
enum RingtoneErrorCode {
  /// The asset or file does not exist or cannot be read.
  sourceNotFound,

  /// The platform cannot decode the audio format.
  unsupportedFormat,

  /// Playback failed for another reason reported by the platform.
  playbackFailed,

  /// The plugin is not available on this platform.
  unavailable,
}

/// Thrown when a sound cannot be played.
class RingtoneException implements Exception {
  /// Creates an exception with the given [code] and optional [message].
  const RingtoneException(this.code, [this.message]);

  /// The reason for the failure.
  final RingtoneErrorCode code;

  /// Details from the platform, if any.
  final String? message;

  @override
  String toString() => message == null
      ? 'RingtoneException(${code.name})'
      : 'RingtoneException(${code.name}): $message';
}
