package com.togrulagayev.flutter_ringtone_player_plus

import io.flutter.embedding.engine.plugins.FlutterPlugin

class FlutterRingtonePlayerPlusPlugin : FlutterPlugin {
    private var player: RingtonePlayer? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val player = RingtonePlayer(binding.applicationContext, binding.flutterAssets)
        RingtonePlayerHostApi.setUp(binding.binaryMessenger, player)
        this.player = player
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        RingtonePlayerHostApi.setUp(binding.binaryMessenger, null)
        player?.stop()
        player = null
    }
}
