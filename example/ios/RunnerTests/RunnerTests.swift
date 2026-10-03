import AVFoundation
import XCTest

@testable import flutter_ringtone_player_plus

@MainActor
final class RingtonePlayerTests: XCTestCase {
  private var listener: RecordingListener!
  private var assets: [String: String] = [:]
  private var player: RingtonePlayer!

  override func setUp() async throws {
    listener = RecordingListener()
    assets = [:]
    player = RingtonePlayer(assetPath: { [unowned self] name, _ in self.assets[name] }, listener: listener)
  }

  override func tearDown() async throws {
    player.dispose()
  }

  func testPlaysAFileAndReportsCompletion() async throws {
    let completed = expectation(description: "completed")
    listener.onCompleted = { completed.fulfill() }

    try await player.play(request: fileRequest(makeWav(seconds: 0.2)))
    XCTAssertEqual(listener.states, [.playing])

    await fulfillment(of: [completed], timeout: 3)
    XCTAssertEqual(listener.states, [.playing, .completed])
  }

  func testStopReportsStopped() async throws {
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))
    try player.stop()

    XCTAssertEqual(listener.states, [.playing, .stopped])
  }

  func testANewSoundReplacesTheCurrentOne() async throws {
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))

    XCTAssertEqual(listener.states, [.playing, .stopped, .playing])
  }

  func testPlaysAnAsset() async throws {
    assets["assets/bell.wav"] = makeWav(seconds: 1).path

    try await player.play(request: PlatformPlayRequest(
      sourceType: .asset, path: "assets/bell.wav", gain: 1, looping: false, usage: .notification))

    XCTAssertEqual(listener.states, [.playing])
  }

  func testPlaysEachSystemSound() async throws {
    for type in [PlatformRingtoneType.alarm, .notification, .ringtone] {
      try await player.play(request: PlatformPlayRequest(
        sourceType: .system, ringtoneType: type, gain: 0.1, looping: false, usage: .notification))
    }

    XCTAssertEqual(listener.states, [.playing, .stopped, .playing, .stopped, .playing])
  }

  func testMissingFileIsSourceNotFound() async {
    await assertPigeonError(errorSourceNotFound) {
      try await self.player.play(request: self.fileRequest(URL(fileURLWithPath: "/missing/sound.wav")))
    }
  }

  func testMissingAssetIsSourceNotFound() async {
    await assertPigeonError(errorSourceNotFound) {
      try await self.player.play(request: PlatformPlayRequest(
        sourceType: .asset, path: "assets/missing.wav", gain: 1, looping: false, usage: .notification))
    }
  }

  func testUndecodableFileIsUnsupportedFormat() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).wav")
    try Data("not audio".utf8).write(to: url)

    await assertPigeonError(errorUnsupportedFormat) {
      try await self.player.play(request: self.fileRequest(url))
    }
  }

  func testAnInterruptionStopsTheSound() async throws {
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))

    postSessionNotification(
      AVAudioSession.interruptionNotification,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
    await drainMainQueue()

    XCTAssertEqual(listener.states, [.playing, .stopped])
  }

  func testTheEndOfAnInterruptionChangesNothing() async throws {
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))

    postSessionNotification(
      AVAudioSession.interruptionNotification,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue])
    await drainMainQueue()

    XCTAssertEqual(listener.states, [.playing])
  }

  func testAMediaServicesResetStopsTheSound() async throws {
    try await player.play(request: fileRequest(makeWav(seconds: 1), looping: true))

    postSessionNotification(AVAudioSession.mediaServicesWereResetNotification)
    await drainMainQueue()

    XCTAssertEqual(listener.states, [.playing, .stopped])
  }

  func testSessionConfigurationForEachUsage() {
    XCTAssertEqual(RingtonePlayer.sessionConfiguration(for: .alarm).category, .playback)
    XCTAssertEqual(RingtonePlayer.sessionConfiguration(for: .media).category, .playback)
    XCTAssertEqual(RingtonePlayer.sessionConfiguration(for: .ringtone).category, .soloAmbient)
    XCTAssertEqual(RingtonePlayer.sessionConfiguration(for: .notification).category, .ambient)
  }

  private func postSessionNotification(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
    NotificationCenter.default.post(name: name, object: AVAudioSession.sharedInstance(), userInfo: userInfo)
  }

  private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async { continuation.resume() }
    }
  }

  private func fileRequest(_ url: URL, looping: Bool = false) -> PlatformPlayRequest {
    PlatformPlayRequest(sourceType: .file, path: url.path, gain: 1, looping: looping, usage: .notification)
  }

  private func assertPigeonError(
    _ code: String, file: StaticString = #filePath, line: UInt = #line,
    _ block: () async throws -> Void
  ) async {
    do {
      try await block()
      XCTFail("Expected a PigeonError with code \(code)", file: file, line: line)
    } catch let error as PigeonError {
      XCTAssertEqual(error.code, code, file: file, line: line)
    } catch {
      XCTFail("Unexpected error \(error)", file: file, line: line)
    }
  }
}

private final class RecordingListener: PlaybackListener {
  var states: [PlatformPlaybackState] = []
  var errors: [PigeonError] = []
  var onCompleted: (() -> Void)?

  func onStateChanged(_ state: PlatformPlaybackState) {
    states.append(state)
    if state == .completed { onCompleted?() }
  }

  func onError(_ error: PigeonError) {
    errors.append(error)
  }
}

private func makeWav(seconds: Double, sampleRate: UInt32 = 8_000) -> URL {
  let sampleCount = UInt32(Double(sampleRate) * seconds)
  var data = Data()
  func append<T: FixedWidthInteger>(_ value: T) {
    withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
  }
  data.append(contentsOf: Array("RIFF".utf8))
  append(UInt32(36 + sampleCount * 2))
  data.append(contentsOf: Array("WAVEfmt ".utf8))
  append(UInt32(16))
  append(UInt16(1))
  append(UInt16(1))
  append(sampleRate)
  append(sampleRate * 2)
  append(UInt16(2))
  append(UInt16(16))
  data.append(contentsOf: Array("data".utf8))
  append(sampleCount * 2)
  data.append(Data(count: Int(sampleCount) * 2))

  let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).wav")
  try! data.write(to: url)
  return url
}
