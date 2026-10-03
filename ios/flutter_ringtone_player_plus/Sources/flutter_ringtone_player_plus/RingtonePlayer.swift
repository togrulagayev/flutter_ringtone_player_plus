import AVFoundation

final class RingtonePlayer: NSObject, RingtonePlayerHostApi {
  static let systemSoundsDirectory: URL = {
    var root = ""
    #if targetEnvironment(simulator)
      // The simulator sees the Mac's file system; iOS system files live under SIMULATOR_ROOT.
      root = ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] ?? ""
    #endif
    return URL(fileURLWithPath: root + "/System/Library/Audio/UISounds")
  }()

  private let assetPath: (String, String?) -> String?
  private let listener: PlaybackListener
  private let session: AVAudioSession
  private var player: AVAudioPlayer?

  init(
    assetPath: @escaping (String, String?) -> String?,
    listener: PlaybackListener,
    session: AVAudioSession = .sharedInstance()
  ) {
    self.assetPath = assetPath
    self.listener = listener
    self.session = session
    super.init()

    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: session)
    center.addObserver(
      self, selector: #selector(handleMediaServicesReset(_:)),
      name: AVAudioSession.mediaServicesWereResetNotification, object: session)
  }

  func play(request: PlatformPlayRequest) async throws {
    let url = try resolve(request)
    release(notifyStopped: true, deactivateSession: false)

    let player: AVAudioPlayer
    do {
      player = try AVAudioPlayer(contentsOf: url)
    } catch {
      deactivateSession()
      throw PigeonError(code: errorUnsupportedFormat, message: error.localizedDescription, details: nil)
    }
    player.numberOfLoops = request.looping ? -1 : 0
    player.volume = Float(request.gain)
    player.delegate = self

    do {
      let configuration = Self.sessionConfiguration(for: request.usage)
      try session.setCategory(configuration.category, mode: .default, options: configuration.options)
      try session.setActive(true)
    } catch {
      deactivateSession()
      throw PigeonError(code: errorPlaybackFailed, message: error.localizedDescription, details: nil)
    }

    guard player.play() else {
      deactivateSession()
      throw PigeonError(code: errorPlaybackFailed, message: "AVAudioPlayer could not start playback", details: nil)
    }
    self.player = player
    listener.onStateChanged(.playing)
  }

  func stop() throws {
    release(notifyStopped: true)
  }

  func dispose() {
    release(notifyStopped: false)
  }

  private func release(notifyStopped: Bool, deactivateSession shouldDeactivate: Bool = true) {
    guard let player else { return }
    self.player = nil
    player.delegate = nil
    player.stop()
    if shouldDeactivate { deactivateSession() }
    if notifyStopped { listener.onStateChanged(.stopped) }
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      AVAudioSession.InterruptionType(rawValue: rawType) == .began
    else { return }
    DispatchQueue.main.async { [weak self] in self?.release(notifyStopped: true) }
  }

  @objc private func handleMediaServicesReset(_ notification: Notification) {
    DispatchQueue.main.async { [weak self] in self?.release(notifyStopped: true) }
  }

  private func deactivateSession() {
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func resolve(_ request: PlatformPlayRequest) throws -> URL {
    switch request.sourceType {
    case .system:
      guard let type = request.ringtoneType else {
        throw PigeonError(code: errorPlaybackFailed, message: "Missing ringtone type", details: nil)
      }
      let url = Self.systemSoundsDirectory.appendingPathComponent(Self.systemSoundFile(for: type))
      return try readableFile(url.path, notFound: "System sound \(url.lastPathComponent) is not available")
    case .asset:
      guard let name = request.path, let path = assetPath(name, request.packageName) else {
        throw PigeonError(code: errorSourceNotFound, message: "Asset not found: \(request.path ?? "")", details: nil)
      }
      return try readableFile(path, notFound: "Asset not found: \(name)")
    case .file:
      let path = request.path ?? ""
      return try readableFile(path, notFound: "Cannot read file \(path)")
    }
  }

  private func readableFile(_ path: String, notFound message: String) throws -> URL {
    guard FileManager.default.isReadableFile(atPath: path) else {
      throw PigeonError(code: errorSourceNotFound, message: message, details: nil)
    }
    return URL(fileURLWithPath: path)
  }

  static func systemSoundFile(for type: PlatformRingtoneType) -> String {
    switch type {
    case .alarm: return "alarm.caf"
    case .notification: return "sms-received1.caf"
    case .ringtone: return "sms-received6.caf"
    }
  }

  static func sessionConfiguration(
    for usage: PlatformSoundUsage
  ) -> (category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) {
    switch usage {
    case .alarm, .media: return (.playback, [])
    case .ringtone: return (.soloAmbient, [])
    case .notification: return (.ambient, [])
    }
  }
}

extension RingtonePlayer: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self, player === self.player else { return }
      self.player = nil
      self.deactivateSession()
      if flag {
        self.listener.onStateChanged(.completed)
      } else {
        self.listener.onError(
          PigeonError(code: errorUnsupportedFormat, message: "The audio could not be decoded", details: nil))
      }
    }
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    DispatchQueue.main.async { [weak self] in
      guard let self, player === self.player else { return }
      self.player = nil
      self.deactivateSession()
      self.listener.onError(
        PigeonError(code: errorUnsupportedFormat, message: error?.localizedDescription, details: nil))
    }
  }
}
