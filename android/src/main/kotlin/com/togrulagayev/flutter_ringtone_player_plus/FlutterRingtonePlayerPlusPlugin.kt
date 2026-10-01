package com.togrulagayev.flutter_ringtone_player_plus

import io.flutter.embedding.engine.plugins.FlutterPlugin

class FlutterRingtonePlayerPlusPlugin : FlutterPlugin {
    private var player: RingtonePlayer? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val events = PlaybackEvents()
        PlaybackStatesStreamHandler.register(binding.binaryMessenger, events)
        val player = RingtonePlayer(binding.applicationContext, binding.flutterAssets, events)
        RingtonePlayerHostApi.setUp(binding.binaryMessenger, player)
        this.player = player
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        RingtonePlayerHostApi.setUp(binding.binaryMessenger, null)
        player?.dispose()
        player = null
    }
}
