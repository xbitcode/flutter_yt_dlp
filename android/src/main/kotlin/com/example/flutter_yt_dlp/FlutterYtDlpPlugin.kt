package com.example.flutter_yt_dlp

import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class FlutterYtDlpPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private companion object {
        const val TAG = "FlutterYtDlpPlugin"
    }
    private lateinit var channelManager: ChannelManager
    private lateinit var methodHandler: MethodHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initializePython(binding)
        setupChannels(binding)
        Log.i(TAG, "Plugin attached and initialized")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channelManager.clearHandlers()
        Log.i(TAG, "Plugin detached")
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        channelManager.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        channelManager.setEventSink(null)
    }

    private fun initializePython(binding: FlutterPlugin.FlutterPluginBinding) {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(binding.applicationContext))
            Log.i(TAG, "Python runtime started")
        }
    }

    private fun setupChannels(binding: FlutterPlugin.FlutterPluginBinding) {
        channelManager = ChannelManager(binding)
        val downloadManager = DownloadManager(channelManager, null)
        val downloadProcessor = DownloadProcessor(channelManager, downloadManager)
        downloadManager.downloadProcessor = downloadProcessor
        methodHandler = MethodHandler(channelManager, downloadManager, downloadProcessor)
        channelManager.setMethodHandler(methodHandler)
        channelManager.setStreamHandler(this)
        Log.i(TAG, "Channels configured")
    }
}
