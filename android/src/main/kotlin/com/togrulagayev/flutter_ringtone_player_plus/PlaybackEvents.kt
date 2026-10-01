package com.togrulagayev.flutter_ringtone_player_plus

internal interface PlaybackListener {
    fun onStateChanged(state: PlatformPlaybackState)

    fun onError(error: FlutterError)
}

internal class PlaybackEvents : PlaybackStatesStreamHandler(), PlaybackListener {
    private var sink: PigeonEventSink<PlatformPlaybackState>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<PlatformPlaybackState>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override fun onStateChanged(state: PlatformPlaybackState) {
        sink?.success(state)
    }

    override fun onError(error: FlutterError) {
        sink?.error(error.code, error.message, error.details)
    }
}
