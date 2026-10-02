import Flutter

public class FlutterRingtonePlayerPlusPlugin: NSObject, FlutterPlugin {
  private let player: RingtonePlayer

  private init(player: RingtonePlayer) {
    self.player = player
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let events = PlaybackEvents()
    PlaybackStatesStreamHandler.register(with: registrar.messenger(), streamHandler: events)

    let player = RingtonePlayer(
      assetPath: { name, package in
        let key = package.map { registrar.lookupKey(forAsset: name, fromPackage: $0) }
          ?? registrar.lookupKey(forAsset: name)
        return Bundle.main.path(forResource: key, ofType: nil)
      },
      listener: events)
    RingtonePlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: player)
    registrar.publish(FlutterRingtonePlayerPlusPlugin(player: player))
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    RingtonePlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    player.dispose()
  }
}
