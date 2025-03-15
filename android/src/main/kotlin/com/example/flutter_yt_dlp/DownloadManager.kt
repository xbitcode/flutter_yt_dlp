package com.example.flutter_yt_dlp

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import kotlin.concurrent.thread

class DownloadManager(
    var channelManager: ChannelManager,
    var downloadProcessor: DownloadProcessor?
) {
    private val activeDownloads = mutableMapOf<String, Boolean>()
    private val handler = Handler(Looper.getMainLooper())

    fun startDownload(call: MethodCall, result: MethodChannel.Result) {
        val format = call.argument<Map<String, Any>>("format")
            ?: return result.error("INVALID_FORMAT", "Format missing", null)
        val outputDir = call.argument<String>("outputDir")
            ?: return result.error("INVALID_DIR", "Output directory missing", null)
        val url = call.argument<String>("url")
            ?: return result.error("INVALID_URL", "URL missing", null)
        val overwrite = call.argument<Boolean>("overwrite") ?: false
        val overrideName = call.argument<String>("overrideName")
        val taskId = generateTaskId()

        thread {
            val title = fetchVideoTitle(url) ?: "unknown_video"
            val outputPath = generateOutputPath(outputDir, title, format, overrideName)
            beginDownload(taskId, format, outputPath, url, overwrite, result)
        }
    }

    fun cancelDownload(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId")
            ?: return result.error("INVALID_TASK", "Task ID missing", null)
        markDownloadCancelled(taskId)
        downloadProcessor?.sendStateEvent(taskId, DownloadState.CANCELED)
        handler.post { result.success(null) }
    }

    fun isDownloadActive(taskId: String): Boolean = activeDownloads[taskId] == true

    private fun generateTaskId(): String = UUID.randomUUID().toString()

    private fun beginDownload(
        taskId: String,
        format: Map<String, Any>,
        outputPath: String,
        url: String,
        overwrite: Boolean,
        result: MethodChannel.Result
    ) {
        activeDownloads[taskId] = true
        thread {
            downloadProcessor?.handleDownload(taskId, format, outputPath, url, overwrite)
        }
        handler.post { result.success(taskId) }
    }

    private fun markDownloadCancelled(taskId: String) {
        activeDownloads[taskId] = false
    }

    private fun fetchVideoTitle(url: String): String? {
        val python = com.chaquo.python.Python.getInstance()
        val module = python.getModule("yt_dlp_helper")
        val infoJson = module.callAttr("get_video_info", url).toString()
        val jsonParser = JsonParser()
        val info = jsonParser.parseJsonMap(infoJson)
        return info["title"] as? String
    }

    private fun generateOutputPath(
        outputDir: String,
        title: String,
        format: Map<String, Any>,
        overrideName: String?
    ): String {
        val sanitizedTitle = overrideName ?: title.replace("[^\\w\\s-]".toRegex(), "").trim()
        val suffix = generateQualitySuffix(format)
        val ext = determineExtension(format)
        return "$outputDir/${sanitizedTitle}_$suffix.$ext"
    }

    private fun generateQualitySuffix(format: Map<String, Any>): String {
        return if (format["type"] == "merge") {
            val video = format["video"] as Map<String, Any>
            val audio = format["audio"] as Map<String, Any>
            "${video["resolution"]}_${audio["bitrate"]}kbps"
        } else {
            val resolution = format["resolution"] as String
            val bitrate = format["bitrate"] as Int
            "${resolution}_${bitrate}kbps"
        }
    }

    private fun determineExtension(format: Map<String, Any>): String {
        return if (format["type"] == "merge") {
            "mp4"
        } else {
            val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
            val needsConversion = format["needsConversion"] as Boolean? ?: false
            val ext = format["ext"] as String
            if (!downloadAsRaw && needsConversion) {
                val isVideo = format["vcodec"] != "none" // Check if it's video with sound
                if (isVideo) "mp4" else "mp3"
            } else {
                ext
            }
        }
    }
}