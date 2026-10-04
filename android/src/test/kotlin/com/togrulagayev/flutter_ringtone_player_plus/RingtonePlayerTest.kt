package com.togrulagayev.flutter_ringtone_player_plus

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [24, 35])
class RingtonePlayerTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private val mediaPlayers = mutableListOf<MediaPlayer>()
    private val listener = RecordingListener()
    private val audioManager = context.getSystemService(AudioManager::class.java)

    private val flutterAssets = object : FlutterPlugin.FlutterAssets {
        override fun getAssetFilePathByName(assetFileName: String) = "flutter_assets/$assetFileName"

        override fun getAssetFilePathByName(assetFileName: String, packageName: String) =
            "flutter_assets/packages/$packageName/$assetFileName"

        override fun getAssetFilePathBySubpath(assetSubpath: String) = "flutter_assets/$assetSubpath"

        override fun getAssetFilePathBySubpath(assetSubpath: String, packageName: String) =
            "flutter_assets/packages/$packageName/$assetSubpath"
    }

    private fun TestScope.newPlayer(
        ioDispatcher: CoroutineDispatcher = StandardTestDispatcher(testScheduler),
    ) = RingtonePlayer(context, flutterAssets, listener, ioDispatcher) {
        mock<MediaPlayer>().also { mediaPlayers += it }
    }

    private fun request(
        sourceType: PlatformSourceType,
        path: String? = null,
        ringtoneType: PlatformRingtoneType? = null,
        gain: Double = 1.0,
        looping: Boolean = false,
        usage: PlatformSoundUsage = PlatformSoundUsage.NOTIFICATION,
    ) = PlatformPlayRequest(
        sourceType = sourceType,
        ringtoneType = ringtoneType,
        path = path,
        gain = gain,
        looping = looping,
        usage = usage,
    )

    private fun fileRequest(usage: PlatformSoundUsage = PlatformSoundUsage.NOTIFICATION) = request(
        PlatformSourceType.FILE,
        path = File.createTempFile("sound", ".wav", context.cacheDir).path,
        usage = usage,
    )

    private fun MediaPlayer.finishPreparing() {
        val listener = argumentCaptor<MediaPlayer.OnPreparedListener>()
        verify(this).setOnPreparedListener(listener.capture())
        listener.firstValue.onPrepared(this)
    }

    private fun MediaPlayer.finishPlaying() {
        val listener = argumentCaptor<MediaPlayer.OnCompletionListener>()
        verify(this).setOnCompletionListener(listener.capture())
        listener.firstValue.onCompletion(this)
    }

    private suspend fun TestScope.startPlaying(
        player: RingtonePlayer,
        request: PlatformPlayRequest = fileRequest(),
    ): MediaPlayer {
        val playing = async { player.play(request) }
        runCurrent()
        val mediaPlayer = mediaPlayers.last()
        mediaPlayer.finishPreparing()
        playing.await()
        return mediaPlayer
    }

    private fun MediaPlayer.failWith(what: Int, extra: Int) {
        val listener = argumentCaptor<MediaPlayer.OnErrorListener>()
        verify(this).setOnErrorListener(listener.capture())
        listener.firstValue.onError(this, what, extra)
    }

    private suspend fun assertFlutterError(code: String, block: suspend () -> Unit) {
        try {
            block()
            fail("Expected a FlutterError with code $code")
        } catch (e: FlutterError) {
            assertEquals(code, e.code)
        }
    }

    @Test
    fun `plays a file with the requested options`() = runTest {
        val file = File.createTempFile("sound", ".wav", context.cacheDir)
        val player = newPlayer()

        val playing = async {
            player.play(
                request(
                    PlatformSourceType.FILE,
                    path = file.path,
                    gain = 0.25,
                    looping = true,
                    usage = PlatformSoundUsage.ALARM,
                ),
            )
        }
        runCurrent()

        val mediaPlayer = mediaPlayers.single()
        verify(mediaPlayer).setDataSource(file.path)
        verify(mediaPlayer).isLooping = true
        verify(mediaPlayer).setVolume(0.25f, 0.25f)
        val attributes = argumentCaptor<AudioAttributes>()
        verify(mediaPlayer).setAudioAttributes(attributes.capture())
        assertEquals(AudioAttributes.USAGE_ALARM, attributes.firstValue.usage)
        verify(mediaPlayer).prepareAsync()
        verify(mediaPlayer, never()).start()

        mediaPlayer.finishPreparing()
        playing.await()
        verify(mediaPlayer).start()
    }

    @Test
    fun `reports a missing file as source-not-found`() = runTest {
        val player = newPlayer()

        assertFlutterError(errorSourceNotFound) {
            player.play(request(PlatformSourceType.FILE, path = "/missing/sound.mp3"))
        }
        assertTrue(mediaPlayers.isEmpty())
    }

    @Test
    fun `reports a missing asset as source-not-found`() = runTest {
        val player = newPlayer()

        assertFlutterError(errorSourceNotFound) {
            player.play(request(PlatformSourceType.ASSET, path = "assets/missing.mp3"))
        }
        assertTrue(mediaPlayers.isEmpty())
    }

    @Test
    fun `plays the default alarm through its settings URI`() = runTest {
        Settings.System.putString(
            context.contentResolver,
            Settings.System.ALARM_ALERT,
            "content://media/internal/audio/media/1",
        )
        val player = newPlayer()

        val playing = async {
            player.play(
                request(PlatformSourceType.SYSTEM, ringtoneType = PlatformRingtoneType.ALARM),
            )
        }
        runCurrent()

        val mediaPlayer = mediaPlayers.single()
        verify(mediaPlayer).setDataSource(
            context,
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
        )
        mediaPlayer.finishPreparing()
        playing.await()
    }

    @Test
    fun `reports a missing default sound as source-not-found`() = runTest {
        val player = newPlayer()

        assertFlutterError(errorSourceNotFound) {
            player.play(
                request(PlatformSourceType.SYSTEM, ringtoneType = PlatformRingtoneType.RINGTONE),
            )
        }
    }

    @Test
    fun `fails and releases the player when preparing fails`() = runTest {
        val player = newPlayer()

        val playing = async { runCatching { player.play(fileRequest()) } }
        runCurrent()
        val mediaPlayer = mediaPlayers.single()
        mediaPlayer.failWith(MediaPlayer.MEDIA_ERROR_UNKNOWN, MediaPlayer.MEDIA_ERROR_UNSUPPORTED)

        val error = playing.await().exceptionOrNull() as FlutterError
        assertEquals(errorUnsupportedFormat, error.code)
        verify(mediaPlayer).release()
    }

    @Test
    fun `a new sound replaces the one that is still preparing`() = runTest {
        val player = newPlayer()

        val first = async { player.play(fileRequest()) }
        runCurrent()
        val second = async { player.play(fileRequest()) }
        runCurrent()

        first.await()
        verify(mediaPlayers[0]).release()
        mediaPlayers[1].finishPreparing()
        second.await()
        verify(mediaPlayers[1]).start()
    }

    @Test
    fun `stop releases the playing sound`() = runTest {
        val player = newPlayer()
        val playing = async { player.play(fileRequest()) }
        runCurrent()
        mediaPlayers.single().finishPreparing()
        playing.await()

        player.stop()

        verify(mediaPlayers.single()).release()
    }

    @Test
    fun `stop cancels a sound that is still being resolved`() = runTest {
        val io = ManualDispatcher()
        val player = newPlayer(io)

        val playing = async { player.play(fileRequest()) }
        runCurrent()
        player.stop()
        io.runQueued()
        runCurrent()

        playing.await()
        assertTrue(mediaPlayers.isEmpty())
    }

    @Test
    fun `reports playing, then completed, and releases the finished sound`() = runTest {
        val mediaPlayer = startPlaying(newPlayer())
        assertEquals(listOf(PlatformPlaybackState.PLAYING), listener.states)

        mediaPlayer.finishPlaying()

        assertEquals(
            listOf(PlatformPlaybackState.PLAYING, PlatformPlaybackState.COMPLETED),
            listener.states,
        )
        verify(mediaPlayer).release()
    }

    @Test
    fun `reports stopped only for a sound that started`() = runTest {
        val player = newPlayer()
        val preparing = async { player.play(fileRequest()) }
        runCurrent()
        player.stop()
        preparing.await()
        assertTrue(listener.states.isEmpty())

        startPlaying(player)
        player.stop()

        assertEquals(
            listOf(PlatformPlaybackState.PLAYING, PlatformPlaybackState.STOPPED),
            listener.states,
        )
    }

    @Test
    fun `a replaced sound reports stopped before the new one plays`() = runTest {
        val player = newPlayer()
        startPlaying(player)
        startPlaying(player)

        assertEquals(
            listOf(
                PlatformPlaybackState.PLAYING,
                PlatformPlaybackState.STOPPED,
                PlatformPlaybackState.PLAYING,
            ),
            listener.states,
        )
    }

    @Test
    fun `errors after playback started go to the event stream`() = runTest {
        val mediaPlayer = startPlaying(newPlayer())

        mediaPlayer.failWith(MediaPlayer.MEDIA_ERROR_UNKNOWN, MediaPlayer.MEDIA_ERROR_IO)

        assertEquals(errorSourceNotFound, listener.errors.single().code)
        verify(mediaPlayer).release()
    }

    @Test
    fun `takes audio focus while playing and gives it back on stop`() = runTest {
        val player = newPlayer()

        startPlaying(player, fileRequest(PlatformSoundUsage.NOTIFICATION))
        assertEquals(
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            shadowOf(audioManager).lastAudioFocusRequest.durationHint,
        )

        startPlaying(player, fileRequest(PlatformSoundUsage.ALARM))
        assertEquals(
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            shadowOf(audioManager).lastAudioFocusRequest.durationHint,
        )

        player.stop()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            assertEquals(
                shadowOf(audioManager).lastAudioFocusRequest.audioFocusRequest,
                shadowOf(audioManager).lastAbandonedAudioFocusRequest,
            )
        } else {
            assertEquals(
                shadowOf(audioManager).lastAudioFocusRequest.listener,
                shadowOf(audioManager).lastAbandonedAudioFocusListener,
            )
        }
    }

    @Test
    fun `stops when another app takes audio focus for good`() = runTest {
        val mediaPlayer = startPlaying(newPlayer())

        shadowOf(audioManager).lastAudioFocusRequest.listener
            .onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS)

        verify(mediaPlayer).release()
        assertEquals(PlatformPlaybackState.STOPPED, listener.states.last())
    }

    @Test
    fun `keeps playing through a transient focus loss`() = runTest {
        val mediaPlayer = startPlaying(newPlayer())

        shadowOf(audioManager).lastAudioFocusRequest.listener
            .onAudioFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)

        verify(mediaPlayer, never()).release()
        assertEquals(listOf(PlatformPlaybackState.PLAYING), listener.states)
    }

    @Test
    fun `maps each usage to audio attributes`() {
        val expected = mapOf(
            PlatformSoundUsage.ALARM to
                (AudioAttributes.USAGE_ALARM to AudioAttributes.CONTENT_TYPE_SONIFICATION),
            PlatformSoundUsage.NOTIFICATION to
                (AudioAttributes.USAGE_NOTIFICATION to AudioAttributes.CONTENT_TYPE_SONIFICATION),
            PlatformSoundUsage.RINGTONE to
                (AudioAttributes.USAGE_NOTIFICATION_RINGTONE to AudioAttributes.CONTENT_TYPE_SONIFICATION),
            PlatformSoundUsage.MEDIA to
                (AudioAttributes.USAGE_MEDIA to AudioAttributes.CONTENT_TYPE_MUSIC),
        )

        for ((usage, attributes) in expected) {
            val actual = RingtonePlayer.audioAttributes(usage)
            assertEquals(attributes.first, actual.usage)
            assertEquals(attributes.second, actual.contentType)
        }
    }

    @Test
    fun `maps MediaPlayer errors to error codes`() {
        assertEquals(errorUnsupportedFormat, RingtonePlayer.errorCodeFor(MediaPlayer.MEDIA_ERROR_UNSUPPORTED))
        assertEquals(errorUnsupportedFormat, RingtonePlayer.errorCodeFor(MediaPlayer.MEDIA_ERROR_MALFORMED))
        assertEquals(errorSourceNotFound, RingtonePlayer.errorCodeFor(MediaPlayer.MEDIA_ERROR_IO))
        assertEquals(errorPlaybackFailed, RingtonePlayer.errorCodeFor(MediaPlayer.MEDIA_ERROR_TIMED_OUT))
    }
}

private class ManualDispatcher : CoroutineDispatcher() {
    private val queue = ArrayDeque<Runnable>()

    override fun dispatch(context: CoroutineContext, block: Runnable) {
        queue.addLast(block)
    }

    fun runQueued() {
        while (queue.isNotEmpty()) queue.removeFirst().run()
    }
}

private class RecordingListener : PlaybackListener {
    val states = mutableListOf<PlatformPlaybackState>()
    val errors = mutableListOf<FlutterError>()

    override fun onStateChanged(state: PlatformPlaybackState) {
        states += state
    }

    override fun onError(error: FlutterError) {
        errors += error
    }
}
