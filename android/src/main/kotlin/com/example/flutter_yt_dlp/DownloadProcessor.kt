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

    fun handleDownload(
            taskId: String,
            format: Map<String, Any>,
            outputPath: String,
            url: String,
            overwrite: Boolean
    ) {
        try {
            val python = com.chaquo.python.Python.getInstance()
            val module = python.getModule("yt_dlp_helper")
            Log.i(tag, "Task $taskId: Preparing download for $url to $outputPath")
            sendStateEvent(taskId, DownloadState.PREPARING)
            when (format["type"] as String) {
                "combined" ->
                        handleCombinedDownload(taskId, format, outputPath, url, overwrite, module)
                "merge" -> handleMergeDownload(taskId, format, outputPath, url, overwrite, module)
                "audio_only" ->
                        handleAudioOnlyDownload(taskId, format, outputPath, url, overwrite, module)
                else -> throw IllegalArgumentException("Unknown format type: ${format["type"]}")
            }
        } catch (e: Exception) {
            Log.e(tag, "Error in download task $taskId", e)
            sendStateEvent(taskId, DownloadState.FAILED)
        }
    }

    fun cancelDownload(taskId: String) {
        if (downloadManager.isDownloadActive(taskId)) {
            sendStateEvent(taskId, DownloadState.CANCELED)
        }
    }

    private fun handleCombinedDownload(
            taskId: String,
            format: Map<String, Any>,
            outputPath: String,
            url: String,
            overwrite: Boolean,
            module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val needsConversion = format["needsConversion"] as Boolean
        val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
        val tempPath =
                if (needsConversion && !downloadAsRaw) "$outputPath.temp.$ext" else outputPath
        val totalSize = (format["size"] as Int).toLong()
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        fileProcessor.downloadFile(module, url, formatId, tempPath, taskId, overwrite) {
                downloaded,
                _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }
        if (needsConversion && !downloadAsRaw && fileProcessor.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Converting to MP4")
            sendStateEvent(taskId, DownloadState.CONVERTING)
            fileProcessor.convertFile(taskId, tempPath, outputPath, "mp4")
            sendStateEvent(taskId, DownloadState.COMPLETED)
        } else if (fileProcessor.isDownloadActive(taskId)) {
            sendStateEvent(taskId, DownloadState.COMPLETED)
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
        val tracker = ProgressTracker(fileProcessor.calculateTotalSize(video, audio))
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        downloadConcurrently(
                taskId,
                url,
                video,
                audio,
                videoPath,
                audioPath,
                overwrite,
                module,
                tracker
        )
        if (fileProcessor.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Merging video and audio")
            sendStateEvent(taskId, DownloadState.MERGING)
            fileProcessor.mergeFiles(videoPath, audioPath, outputPath)
            fileProcessor.cleanupFiles(videoPath, audioPath)
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
    }

    private fun handleAudioOnlyDownload(
            taskId: String,
            format: Map<String, Any>,
            outputPath: String,
            url: String,
            overwrite: Boolean,
            module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val needsConversion = format["needsConversion"] as Boolean
        val downloadAsRaw = format["downloadAsRaw"] as Boolean? ?: true
        val tempPath =
                if (needsConversion && !downloadAsRaw) "$outputPath.temp.$ext" else outputPath
        val totalSize = (format["size"] as Int).toLong()
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        fileProcessor.downloadFile(module, url, formatId, tempPath, taskId, overwrite) {
                downloaded,
                _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }
        if (needsConversion && !downloadAsRaw && fileProcessor.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Converting to MP3")
            sendStateEvent(taskId, DownloadState.CONVERTING)
            fileProcessor.convertFile(taskId, tempPath, outputPath, "mp3")
            sendStateEvent(taskId, DownloadState.COMPLETED)
        } else if (fileProcessor.isDownloadActive(taskId)) {
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
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
            Log.i(tag, "Task $taskId: Downloading video")
            fileProcessor.downloadFile(
                    module,
                    url,
                    video["formatId"] as String,
                    videoPath,
                    taskId,
                    overwrite
            ) { downloaded, _ ->
                tracker.updateVideoProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }
        val audioThread = thread {
            Log.i(tag, "Task $taskId: Downloading audio")
            fileProcessor.downloadFile(
                    module,
                    url,
                    audio["formatId"] as String,
                    audioPath,
                    taskId,
                    overwrite
            ) { downloaded, _ ->
                tracker.updateAudioProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }
        videoThread.join()
        audioThread.join()
    }

    private fun sendProgressEvent(taskId: String, downloaded: Long, total: Long) {
        handler.post {
            channelManager.sendEvent(
                    mapOf(
                            "taskId" to taskId,
                            "type" to "progress",
                            "downloaded" to downloaded,
                            "total" to total
                    )
            )
        }
    }

    private fun sendStateEvent(taskId: String, state: DownloadState) {
        handler.post {
            channelManager.sendEvent(
                    mapOf(
                            "taskId" to taskId,
                            "type" to "state",
                            "state" to state.ordinal,
                            "stateName" to state.name
                    )
            )
        }
    }
}
