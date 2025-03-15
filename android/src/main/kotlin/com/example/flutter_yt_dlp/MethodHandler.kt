package com.example.flutter_yt_dlp

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MethodHandler(private val channelManager: ChannelManager) : MethodChannel.MethodCallHandler {
    private val tag = "FlutterYtDlpPlugin"
    private val videoInfoFetcher = VideoInfoFetcher()
    private val downloadManager: DownloadManager

    init {
        val tempDownloadManager = DownloadManager(channelManager, null)
        val downloadProcessor = DownloadProcessor(channelManager, tempDownloadManager)
        tempDownloadManager.downloadProcessor = downloadProcessor
        downloadManager = tempDownloadManager
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        thread {
            try {
                val python = com.chaquo.python.Python.getInstance()
                val module = python.getModule("yt_dlp_helper")
                when (call.method) {
                    "getVideoInfo" -> videoInfoFetcher.fetchVideoInfo(call, result, module)
                    "startDownload" -> downloadManager.startDownload(call, result)
                    "cancelDownload" -> downloadManager.cancelDownload(call, result)
                    "getThumbnailUrl" -> videoInfoFetcher.fetchThumbnailUrl(call, result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(tag, "Error in method call: ${call.method}", e)
                result.error("ERROR", "Failed to execute ${call.method}: ${e.message}", null)
            }
        }
    }
}