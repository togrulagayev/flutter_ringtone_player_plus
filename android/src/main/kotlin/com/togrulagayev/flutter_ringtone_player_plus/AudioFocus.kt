package com.togrulagayev.flutter_ringtone_player_plus

import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build

internal class AudioFocus(
    private val audioManager: AudioManager,
    private val onLoss: () -> Unit,
) {
    private val listener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS) onLoss()
    }
    private var request: AudioFocusRequest? = null
    private var held = false

    fun request(usage: PlatformSoundUsage, attributes: AudioAttributes) {
        abandon()
        val gain = focusGainFor(usage)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(gain)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener(listener)
                .build()
            this.request = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(listener, streamFor(usage), gain)
        }
        held = true
    }

    fun abandon() {
        if (!held) return
        held = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            request?.let { audioManager.abandonAudioFocusRequest(it) }
            request = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(listener)
        }
    }

    companion object {
        fun focusGainFor(usage: PlatformSoundUsage): Int = when (usage) {
            PlatformSoundUsage.NOTIFICATION -> AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            else -> AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
        }

        private fun streamFor(usage: PlatformSoundUsage): Int = when (usage) {
            PlatformSoundUsage.ALARM -> AudioManager.STREAM_ALARM
            PlatformSoundUsage.NOTIFICATION -> AudioManager.STREAM_NOTIFICATION
            PlatformSoundUsage.RINGTONE -> AudioManager.STREAM_RING
            PlatformSoundUsage.MEDIA -> AudioManager.STREAM_MUSIC
        }
    }
}
