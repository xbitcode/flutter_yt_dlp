package com.example.flutter_yt_dlp

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import kotlin.concurrent.thread

class DownloadManager(private val channelManager: ChannelManager) {
    private lateinit var downloadProcessor: DownloadProcessor
    private val activeDownloads = mutableMapOf<String, Boolean>()
    private val handler = Handler(Looper.getMainLooper())

    fun setDownloadProcessor(processor: DownloadProcessor) {
        downloadProcessor = processor
    }

    fun startDownload(call: MethodCall, result: MethodChannel.Result) {
        val format =
                call.argument<Map<String, Any>>("format")
                        ?: return result.error("INVALID_FORMAT", "Format missing", null)
        val outputDir =
                call.argument<String>("outputDir")
                        ?: return result.error("INVALID_DIR", "Output directory missing", null)
        val url =
                call.argument<String>("url")
                        ?: return result.error("INVALID_URL", "URL missing", null)
        val overwrite = call.argument<Boolean>("overwrite") ?: false
        val overrideName = call.argument<String>("overrideName")

        thread {
            val title = fetchVideoTitle(url) ?: "unknown_video"
            val outputPath = generateOutputPath(outputDir, title, format, overrideName, overwrite)
            beginDownload(taskId = generateTaskId(), format, outputPath, url, overwrite, result)
        }
    }

    fun cancelDownload(call: MethodCall, result: MethodChannel.Result) {
        val taskId =
                call.argument<String>("taskId")
                        ?: return result.error("INVALID_TASK", "Task ID missing", null)
        activeDownloads[taskId] = false
        downloadProcessor.cancelDownload(taskId)
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
        thread { downloadProcessor.handleDownload(taskId, format, outputPath, url, overwrite) }
        handler.post { result.success(taskId) }
    }

    private fun fetchVideoTitle(url: String): String? {
        val python = com.chaquo.python.Python.getInstance()
        val module = python.getModule("yt_dlp_helper")
        val infoJson = module.callAttr("get_video_info", url).toString()
        return JsonParser().parseJsonMap(infoJson)["title"] as? String
    }

    private fun generateOutputPath(
            outputDir: String,
            title: String,
            format: Map<String, Any>,
            overrideName: String?,
            overwrite: Boolean
    ): String {
        val sanitizedTitle = (overrideName ?: title).replace("[^\\w\\s-]".toRegex(), "").trim()
        val suffix =
                when (format["type"] as String) {
                    "combined" -> "${format["resolution"]}_${format["bitrate"]}kbps"
                    "merge" -> {
                        val video = format["video"] as Map<String, Any>
                        val audio = format["audio"] as Map<String, Any>
                        "${video["resolution"]}_${audio["bitrate"]}kbps"
                    }
                    "audio_only" -> "${format["bitrate"]}kbps"
                    else -> throw IllegalArgumentException("Unknown format type: ${format["type"]}")
                }
        val ext = determineExtension(format)
        var filePath = "$outputDir/${sanitizedTitle}_$suffix.$ext"
        if (!overwrite) {
            filePath = getUniqueFilePath(filePath)
        }
        return filePath
    }

    private fun determineExtension(format: Map<String, Any>): String {
        return when (format["type"] as String) {
            "combined" -> {
                val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
                if (!downloadAsRaw && format["needsConversion"] as Boolean) "mp4"
                else format["ext"] as String
            }
            "merge" -> "mp4"
            "audio_only" -> {
                val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
                if (!downloadAsRaw && format["needsConversion"] as Boolean) "mp3"
                else format["ext"] as String
            }
            else -> throw IllegalArgumentException("Unknown format type: ${format["type"]}")
        }
    }

    private fun getUniqueFilePath(basePath: String): String {
        val file = File(basePath)
        val dir = file.parent
        val ext = file.extension
        val baseName = file.nameWithoutExtension.replace("_\\(\\d+\\)$".toRegex(), "")
        var counter = 1
        var path = basePath
        while (File(path).exists()) {
            path = "$dir/${baseName}_($counter).$ext"
            counter++
        }
        return path
    }
}
