// C:\Users\Abdullah\flutter_apps_temp\flutter_yt_dlp\android\src\main\kotlin\com\example\flutter_yt_dlp\FlutterYtDlpPlugin.kt
package com.example.flutter_yt_dlp

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.arthenica.ffmpegkit.FFmpegKit
import java.io.File
import java.util.UUID
import kotlin.concurrent.thread

class FlutterYtDlpPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private val activeDownloads = mutableMapOf<String, Boolean>()
    private val TAG = "FlutterYtDlpPlugin"

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        initializePython(binding)
        setupChannels(binding)
        Log.i(TAG, "Plugin attached to engine and initialized")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        Log.i(TAG, "Plugin detached from engine")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        try {
            val python = Python.getInstance()
            val module = python.getModule("yt_dlp_helper")
            when (call.method) {
                "getAllRawVideoWithSoundFormats" -> fetchFormats(call, result, module, "get_all_raw_video_with_sound_formats", false)
                "getRawVideoAndAudioFormatsForMerge" -> fetchFormats(call, result, module, "get_raw_video_and_audio_formats_for_merge", null)
                "getNonMp4VideoWithSoundFormatsForConversion" -> fetchFormats(call, result, module, "get_non_mp4_video_with_sound_formats_for_conversion", true)
                "getAllRawAudioOnlyFormats" -> fetchFormats(call, result, module, "get_all_raw_audio_only_formats", false)
                "getNonMp3AudioOnlyFormatsForConversion" -> fetchFormats(call, result, module, "get_non_mp3_audio_only_formats_for_conversion", true)
                "startDownload" -> startDownloadTask(call, result)
                "cancelDownload" -> cancelDownloadTask(call, result)
                "getThumbnailUrl" -> fetchThumbnailUrl(call, result, module)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in method call: ${call.method}", e)
            result.error("ERROR", "Failed to execute ${call.method}: ${e.message}", null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.i(TAG, "Event channel listening started")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.i(TAG, "Event channel listening canceled")
    }

    private fun initializePython(binding: FlutterPlugin.FlutterPluginBinding) {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(binding.applicationContext))
        }
    }

    private fun setupChannels(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "flutter_yt_dlp")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "flutter_yt_dlp/events")
        eventChannel.setStreamHandler(this)
    }

    private fun fetchFormats(
        call: MethodCall,
        result: MethodChannel.Result,
        module: com.chaquo.python.PyObject,
        methodName: String,
        needsConversion: Boolean?
    ) {
        val url = call.argument<String>("url")!!
        Log.i(TAG, "Fetching formats with method: $methodName for URL: $url")
        val formatsJson = module.callAttr(methodName, url).toString()
        val formats = parseJsonList(formatsJson).map { map ->
            map.toMutableMap().apply { if (needsConversion != null) put("needsConversion", needsConversion) }
        }
        Log.i(TAG, "Fetched ${formats.size} formats")
        result.success(formats)
    }

    private fun fetchThumbnailUrl(call: MethodCall, result: MethodChannel.Result, module: com.chaquo.python.PyObject) {
        val url = call.argument<String>("url")!!
        Log.i(TAG, "Fetching thumbnail URL for: $url")
        val thumbnailUrl = module.callAttr("get_thumbnail_url", url).toString()
        Log.i(TAG, "Thumbnail URL fetched: $thumbnailUrl")
        result.success(thumbnailUrl)
    }

    private fun parseJsonList(json: String): List<Map<String, Any>> {
        val listType = object : com.fasterxml.jackson.core.type.TypeReference<List<Map<String, Any>>>() {}
        return com.fasterxml.jackson.databind.ObjectMapper().readValue(json, listType)
    }

    private fun startDownloadTask(call: MethodCall, result: MethodChannel.Result) {
        val format = call.argument<Map<String, Any>>("format")!!
        val outputPath = call.argument<String>("outputPath")!!
        val url = call.argument<String>("url")!!
        val overwrite = call.argument<Boolean>("overwrite") ?: false
        val taskId = UUID.randomUUID().toString()
        activeDownloads[taskId] = true
        thread {
            handleDownload(taskId, format, outputPath, url, overwrite)
        }
        result.success(taskId)
    }

    private fun cancelDownloadTask(call: MethodCall, result: MethodChannel.Result) {
        val taskId = call.argument<String>("taskId")!!
        activeDownloads[taskId] = false
        sendStateEvent(taskId, DownloadState.CANCELED.ordinal)
        result.success(null)
    }

    private fun sendProgressEvent(taskId: String, downloaded: Long, total: Long) {
        handler.post {
            eventSink?.success(mapOf(
                "taskId" to taskId,
                "type" to "progress",
                "downloaded" to downloaded,
                "total" to total
            ))
        }
    }

    private fun sendStateEvent(taskId: String, state: Int) {
        handler.post {
            eventSink?.success(mapOf(
                "taskId" to taskId,
                "type" to "state",
                "state" to state
            ))
        }
    }

    private fun handleDownload(taskId: String, format: Map<String, Any>, outputPath: String, url: String, overwrite: Boolean) {
        try {
            val python = Python.getInstance()
            val module = python.getModule("yt_dlp_helper")
            Log.i(TAG, "Task $taskId: Preparing download for $url to $outputPath, overwrite: $overwrite")
            sendStateEvent(taskId, DownloadState.PREPARING.ordinal)

            val type = format["type"] as String?
            if (type == "merge") {
                handleMergeDownload(taskId, format, outputPath, url, overwrite, module)
            } else {
                handleSingleFormatDownload(taskId, format, outputPath, url, overwrite, module)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in download task $taskId", e)
            sendStateEvent(taskId, DownloadState.FAILED.ordinal)
        }
    }

    private fun handleMergeDownload(
        taskId: String,
        format: Map<String, Any>,
        outputPath: String,
        url: String,
        overwrite: Boolean,
        module: com.chaquo.python.PyObject
    ) {
        val video = format["video"] as Map<String, Any>
        val audio = format["audio"] as Map<String, Any>
        val videoPath = "$outputPath.video.${video["ext"]}"
        val audioPath = "$outputPath.audio.${audio["ext"]}"
        val progressTracker = ProgressTracker(calculateTotalSize(video, audio))

        if (!isDownloadActive(taskId)) return

        sendStateEvent(taskId, DownloadState.DOWNLOADING.ordinal)
        downloadConcurrently(taskId, url, video, audio, videoPath, audioPath, overwrite, module, progressTracker)

        if (!isDownloadActive(taskId)) {
            cleanupFiles(videoPath, audioPath)
            return
        }

        Log.i(TAG, "Task $taskId: Merging video and audio")
        sendStateEvent(taskId, DownloadState.MERGING.ordinal)
        mergeFiles(videoPath, audioPath, outputPath)
        cleanupFiles(videoPath, audioPath)

        if (isDownloadActive(taskId)) {
            Log.i(TAG, "Task $taskId: Download completed")
            sendStateEvent(taskId, DownloadState.COMPLETED.ordinal)
        }
    }

    private fun handleSingleFormatDownload(
        taskId: String,
        format: Map<String, Any>,
        outputPath: String,
        url: String,
        overwrite: Boolean,
        module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val needsConversion = format["needsConversion"] as Boolean? ?: false
        val tempPath = if (needsConversion) "$outputPath.temp.$ext" else outputPath
        val totalSize = (format["size"] as Int).toLong()

        if (!isDownloadActive(taskId)) return

        Log.i(TAG, "Task $taskId: Downloading single format")
        sendStateEvent(taskId, DownloadState.DOWNLOADING.ordinal)
        downloadFile(module, url, formatId, tempPath, taskId, overwrite) { downloaded, _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }

        if (!isDownloadActive(taskId)) {
            File(tempPath).delete()
            return
        }

        if (needsConversion) {
            convertFile(taskId, tempPath, outputPath)
        }

        if (isDownloadActive(taskId)) {
            Log.i(TAG, "Task $taskId: Download completed")
            sendStateEvent(taskId, DownloadState.COMPLETED.ordinal)
        }
    }

    private fun calculateTotalSize(video: Map<String, Any>, audio: Map<String, Any>): Long {
        val videoSize = (video["size"] as Int).toLong()
        val audioSize = (audio["size"] as Int).toLong()
        return videoSize + audioSize
    }

    private data class ProgressTracker(val totalSize: Long) {
        var downloadedVideo: Long = 0
        var downloadedAudio: Long = 0

        @Synchronized
        fun updateVideoProgress(downloaded: Long) {
            downloadedVideo = downloaded
        }

        @Synchronized
        fun updateAudioProgress(downloaded: Long) {
            downloadedAudio = downloaded
        }

        @Synchronized
        fun getCombinedDownloaded(): Long = downloadedVideo + downloadedAudio
    }

    private fun downloadConcurrently(
        taskId: String,
        url: String,
        video: Map<String, Any>,
        audio: Map<String, Any>,
        videoPath: String,
        audioPath: String,
        overwrite: Boolean,
        module: com.chaquo.python.PyObject,
        tracker: ProgressTracker
    ) {
        val videoThread = thread {
            Log.i(TAG, "Task $taskId: Downloading video concurrently")
            downloadFile(module, url, video["formatId"] as String, videoPath, taskId, overwrite) { downloaded, _ ->
                tracker.updateVideoProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }

        val audioThread = thread {
            Log.i(TAG, "Task $taskId: Downloading audio concurrently")
            downloadFile(module, url, audio["formatId"] as String, audioPath, taskId, overwrite) { downloaded, _ ->
                tracker.updateAudioProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }

        videoThread.join()
        audioThread.join()
    }

    private fun downloadFile(
        module: com.chaquo.python.PyObject,
        url: String,
        formatId: String,
        outputPath: String,
        taskId: String,
        overwrite: Boolean,
        onProgress: (Long, Long) -> Unit
    ) {
        module.callAttr("download_format", url, formatId, outputPath, overwrite, object : Any() {
            @Suppress("unused")
            fun onProgress(downloaded: Long, total: Long) {
                if (isDownloadActive(taskId)) {
                    onProgress(downloaded, total)
                }
            }
        })
    }

    private fun mergeFiles(videoPath: String, audioPath: String, outputPath: String) {
        FFmpegKit.execute("-i $videoPath -i $audioPath -c:v copy -c:a aac $outputPath")
    }

    private fun convertFile(taskId: String, tempPath: String, outputPath: String) {
        Log.i(TAG, "Task $taskId: Converting file")
        sendStateEvent(taskId, DownloadState.CONVERTING.ordinal)
        val outputExt = outputPath.substringAfterLast('.')
        val codec = if (outputExt == "mp3") "-c:a mp3" else "-c:v copy -c:a aac"
        FFmpegKit.execute("-i $tempPath $codec $outputPath")
        File(tempPath).delete()
    }

    private fun cleanupFiles(vararg paths: String) {
        paths.forEach { File(it).delete() }
    }

    private fun isDownloadActive(taskId: String): Boolean = activeDownloads[taskId] == true
}

enum class DownloadState {
    PREPARING, DOWNLOADING, MERGING, CONVERTING, COMPLETED, CANCELED, FAILED
}