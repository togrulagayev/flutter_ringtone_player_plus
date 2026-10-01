package com.togrulagayev.flutter_ringtone_player_plus

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext

internal class RingtonePlayer(
    private val context: Context,
    private val flutterAssets: FlutterPlugin.FlutterAssets,
    private val listener: PlaybackListener,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val createMediaPlayer: () -> MediaPlayer = ::MediaPlayer,
) : RingtonePlayerHostApi {

    private val audioFocus = AudioFocus(context.getSystemService(AudioManager::class.java)) { stop() }
    private var mediaPlayer: MediaPlayer? = null
    private var pendingStart: CancellableContinuation<Unit>? = null
    private var started = false
    private var requestId = 0

    override suspend fun play(request: PlatformPlayRequest) {
        val id = ++requestId
        val source = withContext(ioDispatcher) { resolve(request) }
        if (id != requestId) {
            source.close()
            return
        }
        release()

        val attributes = audioAttributes(request.usage)
        val player = createMediaPlayer()
        mediaPlayer = player
        try {
            player.setAudioAttributes(attributes)
            source.applyTo(player, context)
            player.isLooping = request.looping
            player.setVolume(request.gain.toFloat(), request.gain.toFloat())
        } catch (e: Exception) {
            release()
            throw when (e) {
                is IOException, is SecurityException -> FlutterError(errorSourceNotFound, e.message)
                else -> e
            }
        } finally {
            source.close()
        }

        suspendCancellableCoroutine { continuation ->
            pendingStart = continuation
            continuation.invokeOnCancellation { release() }
            player.setOnPreparedListener {
                pendingStart = null
                audioFocus.request(request.usage, attributes)
                it.start()
                started = true
                listener.onStateChanged(PlatformPlaybackState.PLAYING)
                continuation.resume(Unit)
            }
            player.setOnCompletionListener {
                release(notifyStopped = false)
                listener.onStateChanged(PlatformPlaybackState.COMPLETED)
            }
            player.setOnErrorListener { _, what, extra ->
                val error = FlutterError(errorCodeFor(extra), "MediaPlayer error ($what, $extra)")
                val pending = pendingStart
                pendingStart = null
                release(notifyStopped = false)
                if (pending != null) pending.resumeWithException(error) else listener.onError(error)
                true
            }
            player.prepareAsync()
        }
    }

    override fun stop() {
        requestId++
        release()
    }

    fun dispose() {
        requestId++
        release(notifyStopped = false)
    }

    private fun release(notifyStopped: Boolean = true) {
        pendingStart?.let {
            pendingStart = null
            it.resume(Unit)
        }
        val player = mediaPlayer ?: return
        mediaPlayer = null
        player.release()
        audioFocus.abandon()
        if (started) {
            started = false
            if (notifyStopped) listener.onStateChanged(PlatformPlaybackState.STOPPED)
        }
    }

    private fun resolve(request: PlatformPlayRequest): Source = when (request.sourceType) {
        PlatformSourceType.SYSTEM -> Source.Content(defaultSoundUri(requireNotNull(request.ringtoneType)))
        PlatformSourceType.ASSET -> openAsset(requireNotNull(request.path), request.packageName)
        PlatformSourceType.FILE -> {
            val file = File(requireNotNull(request.path))
            if (!file.canRead()) {
                throw FlutterError(errorSourceNotFound, "Cannot read file ${file.path}")
            }
            Source.Path(file.path)
        }
    }

    private fun defaultSoundUri(type: PlatformRingtoneType): Uri {
        val ringtoneManagerType = when (type) {
            PlatformRingtoneType.ALARM -> RingtoneManager.TYPE_ALARM
            PlatformRingtoneType.NOTIFICATION -> RingtoneManager.TYPE_NOTIFICATION
            PlatformRingtoneType.RINGTONE -> RingtoneManager.TYPE_RINGTONE
        }
        if (RingtoneManager.getActualDefaultRingtoneUri(context, ringtoneManagerType) != null) {
            return RingtoneManager.getDefaultUri(ringtoneManagerType)
        }
        return RingtoneManager.getValidRingtoneUri(context)
            ?: throw FlutterError(errorSourceNotFound, "No ${type.name.lowercase()} sound is available on this device")
    }

    private fun openAsset(name: String, packageName: String?): Source {
        val assetPath = if (packageName == null) {
            flutterAssets.getAssetFilePathByName(name)
        } else {
            flutterAssets.getAssetFilePathByName(name, packageName)
        }
        return try {
            Source.Asset(context.assets.openFd(assetPath))
        } catch (e: FileNotFoundException) {
            // openFd fails for assets that are stored compressed in the APK.
            Source.Path(copyAssetToCache(assetPath).path)
        }
    }

    private fun copyAssetToCache(assetPath: String): File {
        val input = try {
            context.assets.open(assetPath)
        } catch (e: FileNotFoundException) {
            throw FlutterError(errorSourceNotFound, "Asset not found: $assetPath")
        }
        val file = File(context.cacheDir, "flutter_ringtone_player_plus/$assetPath")
        file.parentFile?.mkdirs()
        input.use { stream -> file.outputStream().use { stream.copyTo(it) } }
        return file
    }

    private sealed interface Source {
        fun applyTo(player: MediaPlayer, context: Context)

        fun close() {}

        class Content(private val uri: Uri) : Source {
            override fun applyTo(player: MediaPlayer, context: Context) =
                player.setDataSource(context, uri)
        }

        class Path(private val path: String) : Source {
            override fun applyTo(player: MediaPlayer, context: Context) =
                player.setDataSource(path)
        }

        class Asset(private val descriptor: AssetFileDescriptor) : Source {
            override fun applyTo(player: MediaPlayer, context: Context) =
                player.setDataSource(descriptor)

            override fun close() = descriptor.close()
        }
    }

    companion object {
        fun audioAttributes(usage: PlatformSoundUsage): AudioAttributes =
            AudioAttributes.Builder()
                .setUsage(
                    when (usage) {
                        PlatformSoundUsage.ALARM -> AudioAttributes.USAGE_ALARM
                        PlatformSoundUsage.NOTIFICATION -> AudioAttributes.USAGE_NOTIFICATION
                        PlatformSoundUsage.RINGTONE -> AudioAttributes.USAGE_NOTIFICATION_RINGTONE
                        PlatformSoundUsage.MEDIA -> AudioAttributes.USAGE_MEDIA
                    },
                )
                .setContentType(
                    if (usage == PlatformSoundUsage.MEDIA) {
                        AudioAttributes.CONTENT_TYPE_MUSIC
                    } else {
                        AudioAttributes.CONTENT_TYPE_SONIFICATION
                    },
                )
                .build()

        fun errorCodeFor(extra: Int): String = when (extra) {
            MediaPlayer.MEDIA_ERROR_UNSUPPORTED, MediaPlayer.MEDIA_ERROR_MALFORMED -> errorUnsupportedFormat
            MediaPlayer.MEDIA_ERROR_IO -> errorSourceNotFound
            else -> errorPlaybackFailed
        }
    }
}
