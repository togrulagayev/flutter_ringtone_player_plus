protocol PlaybackListener: AnyObject {
  func onStateChanged(_ state: PlatformPlaybackState)
  func onError(_ error: PigeonError)
}

final class PlaybackEvents: PlaybackStatesStreamHandler, PlaybackListener {
  private var sink: PigeonEventSink<PlatformPlaybackState>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<PlatformPlaybackState>) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }

  func onStateChanged(_ state: PlatformPlaybackState) {
    sink?.success(state)
  }

  func onError(_ error: PigeonError) {
    sink?.error(code: error.code, message: error.message, details: error.details)
  }
}
