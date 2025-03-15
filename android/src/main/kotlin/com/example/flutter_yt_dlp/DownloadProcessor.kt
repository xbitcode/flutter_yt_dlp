package com.example.flutter_yt_dlp

import android.util.Log
import kotlin.concurrent.thread

class DownloadProcessor(
    private val channelManager: ChannelManager,
    private val downloadManager: DownloadManager
) {
    private val tag = "FlutterYtDlpPlugin"
    private val fileProcessor = FileProcessor(channelManager, downloadManager)
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    fun handleDownload(taskId: String, format: Map<String, Any>, outputPath: String, url: String, overwrite: Boolean) {
        try {
            val python = com.chaquo.python.Python.getInstance()
            val module = python.getModule("yt_dlp_helper")
            Log.i(tag, "Task $taskId: Preparing download for $url to $outputPath")
            sendStateEvent(taskId, DownloadState.PREPARING)
            if (isMergeFormat(format)) {
                handleMergeDownload(taskId, format, outputPath, url, overwrite, module)
            } else {
                handleSingleFormatDownload(taskId, format, outputPath, url, overwrite, module)
            }
        } catch (e: Exception) {
            Log.e(tag, "Error in download task $taskId", e)
            sendStateEvent(taskId, DownloadState.FAILED)
        }
    }

    fun sendProgressEvent(taskId: String, downloaded: Long, total: Long) {
        handler.post {
            channelManager.getEventSink()?.success(createProgressMap(taskId, downloaded, total))
        }
    }

    fun sendStateEvent(taskId: String, state: DownloadState) {
        handler.post {
            channelManager.getEventSink()?.success(createStateMap(taskId, state))
        }
    }

    private fun handleMergeDownload(
        taskId: String, format: Map<String, Any>, outputPath: String,
        url: String, overwrite: Boolean, module: com.chaquo.python.PyObject
    ) {
        val video = format["video"] as Map<String, Any>
        val audio = format["audio"] as Map<String, Any>
        val videoPath = "$outputPath.video.${video["ext"]}"
        val audioPath = "$outputPath.audio.${audio["ext"]}"
        val tracker = ProgressTracker(fileProcessor.calculateTotalSize(video, audio))
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        downloadConcurrently(taskId, url, video, audio, videoPath, audioPath, overwrite, module, tracker)
        if (fileProcessor.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Merging video and audio")
            sendStateEvent(taskId, DownloadState.MERGING)
            fileProcessor.mergeFiles(videoPath, audioPath, outputPath)
            fileProcessor.cleanupFiles(videoPath, audioPath)
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
    }

    private fun handleSingleFormatDownload(
        taskId: String, format: Map<String, Any>, outputPath: String,
        url: String, overwrite: Boolean, module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
        val needsConversion = format["needsConversion"] as Boolean? ?: false
        val tempPath = determineTempPath(needsConversion, downloadAsRaw, outputPath, ext)
        val totalSize = (format["size"] as Int).toLong()
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        fileProcessor.downloadFile(module, url, formatId, tempPath, taskId, overwrite) { downloaded, _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }
        if (shouldConvert(downloadAsRaw, needsConversion, taskId)) {
            Log.i(tag, "Task $taskId: Converting file")
            sendStateEvent(taskId, DownloadState.CONVERTING)
            fileProcessor.convertFile(taskId, tempPath, outputPath)
            sendStateEvent(taskId, DownloadState.COMPLETED)
        } else if (fileProcessor.isDownloadActive(taskId)) {
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
    }

    private fun downloadConcurrently(
        taskId: String, url: String, video: Map<String, Any>, audio: Map<String, Any>,
        videoPath: String, audioPath: String, overwrite: Boolean, module: com.chaquo.python.PyObject,
        tracker: ProgressTracker
    ) {
        val videoThread = thread {
            Log.i(tag, "Task $taskId: Downloading video concurrently")
            fileProcessor.downloadFile(module, url, video["formatId"] as String, videoPath, taskId, overwrite) { downloaded, _ ->
                tracker.updateVideoProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }
        val audioThread = thread {
            Log.i(tag, "Task $taskId: Downloading audio concurrently")
            fileProcessor.downloadFile(module, url, audio["formatId"] as String, audioPath, taskId, overwrite) { downloaded, _ ->
                tracker.updateAudioProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }
        videoThread.join()
        audioThread.join()
    }

    private fun isMergeFormat(format: Map<String, Any>): Boolean = format["type"] == "merge"

    private fun determineTempPath(needsConversion: Boolean, downloadAsRaw: Boolean, outputPath: String, ext: String): String =
        if (needsConversion && !downloadAsRaw) "$outputPath.temp.$ext" else outputPath

    private fun shouldConvert(downloadAsRaw: Boolean, needsConversion: Boolean, taskId: String): Boolean =
        !downloadAsRaw && needsConversion && fileProcessor.isDownloadActive(taskId)

    private fun createProgressMap(taskId: String, downloaded: Long, total: Long): Map<String, Any> = mapOf(
        "taskId" to taskId,
        "type" to "progress",
        "downloaded" to downloaded,
        "total" to total
    )

    private fun createStateMap(taskId: String, state: DownloadState): Map<String, Any> = mapOf(
        "taskId" to taskId,
        "type" to "state",
        "state" to state.ordinal,
        "stateName" to state.name // Add state name to the event map
    )
}