package com.example.flutter_yt_dlp

import android.util.Log
import kotlin.concurrent.thread

class DownloadProcessor(
    private val channelManager: ChannelManager,
    private val downloadManager: DownloadManager
) {
    private val tag = "FlutterYtDlp"
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
            Log.i(tag, "Task $taskId: Starting download preparation for $url to $outputPath")
            sendStateEvent(taskId, DownloadState.PREPARING)

            when (format["type"] as? String ?: "unknown") {
                "combined" -> processCombinedDownload(taskId, format, outputPath, url, overwrite, module)
                "merge" -> processMergeDownload(taskId, format, outputPath, url, overwrite, module)
                "audio_only" -> processAudioOnlyDownload(taskId, format, outputPath, url, overwrite, module)
                else -> {
                    Log.e(tag, "Task $taskId: Unknown format type: ${format["type"]}")
                    throw IllegalArgumentException("Unknown format type: ${format["type"]}")
                }
            }
        } catch (e: Exception) {
            Log.e(tag, "Task $taskId: Download failed", e)
            sendStateEvent(taskId, DownloadState.FAILED)
        }
    }

    fun cancelDownload(taskId: String) {
        if (downloadManager.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Cancel requested")
            sendStateEvent(taskId, DownloadState.CANCELED)
        } else {
            Log.w(tag, "Task $taskId: Cancel ignored, download not active")
        }
    }

    private fun processCombinedDownload(
        taskId: String,
        format: Map<String, Any>,
        outputPath: String,
        url: String,
        overwrite: Boolean,
        module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val needsConversion = format["needsConversion"] as? Boolean ?: (ext != "mp4")
        val downloadAsRaw = format["downloadAsRaw"] as? Boolean ?: true
        val tempPath = if (needsConversion && !downloadAsRaw) "$outputPath.temp.$ext" else outputPath
        val totalSize = (format["size"] as Int).toLong()

        Log.d(tag, "Task $taskId: Downloading combined format $formatId")
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        fileProcessor.downloadFile(module, url, formatId, tempPath, taskId, overwrite) { downloaded, _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }

        if (!fileProcessor.isDownloadActive(taskId)) return // Early exit if canceled or failed

        if (needsConversion && !downloadAsRaw) {
            Log.i(tag, "Task $taskId: Converting to MP4")
            sendStateEvent(taskId, DownloadState.CONVERTING)
            fileProcessor.convertFile(taskId, tempPath, outputPath, "mp4")
            if (fileProcessor.isDownloadActive(taskId)) {
                Log.i(tag, "Task $taskId: Conversion completed")
                sendStateEvent(taskId, DownloadState.COMPLETED)
            }
        } else {
            Log.i(tag, "Task $taskId: Download completed (no conversion needed)")
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
    }

    private fun processMergeDownload(
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

        Log.d(tag, "Task $taskId: Downloading video and audio for merge")
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        downloadConcurrently(taskId, url, video, audio, videoPath, audioPath, overwrite, module, tracker)

        if (!fileProcessor.isDownloadActive(taskId)) return // Early exit if canceled or failed

        Log.i(tag, "Task $taskId: Merging video and audio")
        sendStateEvent(taskId, DownloadState.MERGING)
        fileProcessor.mergeFiles(videoPath, audioPath, outputPath)
        fileProcessor.cleanupFiles(videoPath, audioPath)

        if (fileProcessor.isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Merge completed")
            sendStateEvent(taskId, DownloadState.COMPLETED)
        }
    }

    private fun processAudioOnlyDownload(
        taskId: String,
        format: Map<String, Any>,
        outputPath: String,
        url: String,
        overwrite: Boolean,
        module: com.chaquo.python.PyObject
    ) {
        val formatId = format["formatId"] as String
        val ext = format["ext"] as String
        val needsConversion = format["needsConversion"] as? Boolean ?: (ext != "mp3")
        val downloadAsRaw = format["downloadAsRaw"] as? Boolean ?: true
        val tempPath = if (needsConversion && !downloadAsRaw) "$outputPath.temp.$ext" else outputPath
        val totalSize = (format["size"] as Int).toLong()

        Log.d(tag, "Task $taskId: Downloading audio-only format $formatId")
        sendStateEvent(taskId, DownloadState.DOWNLOADING)
        fileProcessor.downloadFile(module, url, formatId, tempPath, taskId, overwrite) { downloaded, _ ->
            sendProgressEvent(taskId, downloaded, totalSize)
        }

        if (!fileProcessor.isDownloadActive(taskId)) return // Early exit if canceled or failed

        if (needsConversion && !downloadAsRaw) {
            Log.i(tag, "Task $taskId: Converting to MP3")
            sendStateEvent(taskId, DownloadState.CONVERTING)
            fileProcessor.convertFile(taskId, tempPath, outputPath, "mp3")
            if (fileProcessor.isDownloadActive(taskId)) {
                Log.i(tag, "Task $taskId: Conversion completed")
                sendStateEvent(taskId, DownloadState.COMPLETED)
            }
        } else {
            Log.i(tag, "Task $taskId: Download completed (no conversion needed)")
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
            Log.d(tag, "Task $taskId: Downloading video format ${video["formatId"]}")
            fileProcessor.downloadFile(
                module, url, video["formatId"] as String, videoPath, taskId, overwrite
            ) { downloaded, _ ->
                tracker.updateVideoProgress(downloaded)
                sendProgressEvent(taskId, tracker.getCombinedDownloaded(), tracker.totalSize)
            }
        }
        val audioThread = thread {
            Log.d(tag, "Task $taskId: Downloading audio format ${audio["formatId"]}")
            fileProcessor.downloadFile(
                module, url, audio["formatId"] as String, audioPath, taskId, overwrite
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
            Log.d(tag, "Task $taskId: Progress update - $downloaded/$total bytes")
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
            Log.i(tag, "Task $taskId: State changed to ${state.name}")
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