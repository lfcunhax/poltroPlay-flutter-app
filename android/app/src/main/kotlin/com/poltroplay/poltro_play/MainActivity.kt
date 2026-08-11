package com.poltroplay

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import android.net.Uri
import com.google.android.gms.common.images.WebImage
import androidx.mediarouter.media.MediaRouter
import androidx.mediarouter.media.MediaRouteSelector
import com.google.android.gms.cast.CastMediaControlIntent

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "PoltroPlayCast"
    private val CHANNEL = "com.poltroplay/cast"
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var methodChannel: MethodChannel? = null
    private var castInitError: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Tentar inicializar o Cast
        try {
            castContext = CastContext.getSharedInstance(this)
            sessionManager = castContext?.sessionManager
            Log.d(TAG, "CastContext inicializado com sucesso!")
        } catch (e: Exception) {
            castInitError = e.message ?: "Erro desconhecido ao inicializar Cast"
            Log.e(TAG, "Erro ao inicializar CastContext: ${e.message}", e)
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showCastDialog" -> {
                    if (castInitError != null) {
                        result.success(mapOf("error" to castInitError))
                        return@setMethodCallHandler
                    }
                    val dialogResult = showCastPicker()
                    result.success(dialogResult)
                }
                "loadMedia" -> {
                    val url = call.argument<String>("url")
                    val title = call.argument<String>("title")
                    val posterUrl = call.argument<String>("posterUrl")
                    if (url != null) {
                        loadMediaOnCast(url, title ?: "PoltroPlay", posterUrl)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "URL is required", null)
                    }
                }
                "isConnected" -> {
                    val connected = sessionManager?.currentCastSession?.isConnected == true
                    result.success(connected)
                }
                "disconnect" -> {
                    sessionManager?.endCurrentSession(true)
                    result.success(true)
                }
                "pause" -> {
                    sessionManager?.currentCastSession?.remoteMediaClient?.pause()
                    result.success(true)
                }
                "play" -> {
                    sessionManager?.currentCastSession?.remoteMediaClient?.play()
                    result.success(true)
                }
                "stop" -> {
                    sessionManager?.currentCastSession?.remoteMediaClient?.stop()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Ouvir mudanças de sessão Cast
        if (sessionManager != null) {
            sessionManager?.addSessionManagerListener(object : SessionManagerListener<CastSession> {
                override fun onSessionStarted(session: CastSession, sessionId: String) {
                    Log.d(TAG, "Sessão Cast iniciada: ${session.castDevice?.friendlyName}")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSessionStarted", mapOf(
                            "deviceName" to (session.castDevice?.friendlyName ?: "TV")
                        ))
                    }
                }

                override fun onSessionEnded(session: CastSession, error: Int) {
                    Log.d(TAG, "Sessão Cast encerrada")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSessionEnded", null)
                    }
                }

                override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSessionStarted", mapOf(
                            "deviceName" to (session.castDevice?.friendlyName ?: "TV")
                        ))
                    }
                }

                override fun onSessionStarting(session: CastSession) {}
                override fun onSessionStartFailed(session: CastSession, error: Int) {
                    Log.e(TAG, "Falha ao iniciar sessão Cast, erro: $error")
                }
                override fun onSessionEnding(session: CastSession) {}
                override fun onSessionResuming(session: CastSession, sessionId: String) {}
                override fun onSessionResumeFailed(session: CastSession, error: Int) {}
                override fun onSessionSuspended(session: CastSession, reason: Int) {}
            }, CastSession::class.java)
        }
    }

    private fun showCastPicker(): Map<String, Any?> {
        try {
            val router = MediaRouter.getInstance(this)
            val selector = MediaRouteSelector.Builder()
                .addControlCategory(CastMediaControlIntent.categoryForCast(
                    CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
                ))
                .build()

            // Verificar quantos dispositivos estão disponíveis
            val routes = router.getRoutes()
            val castRoutes = routes.filter { route ->
                route.matchesSelector(selector) && !route.isDefault
            }

            Log.d(TAG, "Total de rotas: ${routes.size}, Cast routes: ${castRoutes.size}")

            if (castRoutes.isEmpty()) {
                // Iniciar scan ativo
                router.addCallback(selector, object : MediaRouter.Callback() {
                    override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
                        Log.d(TAG, "Dispositivo encontrado: ${route.name}")
                        runOnUiThread {
                            methodChannel?.invokeMethod("onDeviceFound", mapOf(
                                "name" to route.name
                            ))
                        }
                    }
                }, MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN)

                return mapOf(
                    "success" to false,
                    "message" to "Procurando dispositivos na rede Wi-Fi... Nenhum encontrado ainda.",
                    "routeCount" to routes.size,
                    "castRouteCount" to 0
                )
            }

            // Abrir o seletor nativo do Android
            val intent = androidx.mediarouter.app.MediaRouteChooserDialogFragment()
            intent.routeSelector = selector
            intent.show(supportFragmentManager, "cast_dialog")

            return mapOf("success" to true, "castRouteCount" to castRoutes.size)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao abrir seletor: ${e.message}", e)
            return mapOf("success" to false, "message" to "Erro: ${e.message}")
        }
    }

    private fun loadMediaOnCast(url: String, title: String, posterUrl: String?) {
        val session = sessionManager?.currentCastSession ?: return
        val remoteMediaClient = session.remoteMediaClient ?: return

        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(MediaMetadata.KEY_TITLE, title)
            putString(MediaMetadata.KEY_SUBTITLE, "PoltroPlay")
            if (posterUrl != null) {
                addImage(WebImage(Uri.parse(posterUrl)))
            }
        }

        val contentType = if (url.contains(".m3u8")) "application/x-mpegurl" else "video/mp4"

        val mediaInfo = MediaInfo.Builder(url)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType(contentType)
            .setMetadata(metadata)
            .build()

        val loadRequest = MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(true)
            .build()

        remoteMediaClient.load(loadRequest)
    }
}
