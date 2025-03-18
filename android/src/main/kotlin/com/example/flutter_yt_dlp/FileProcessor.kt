package com.example.flutter_yt_dlp

import android.util.Log
import com.arthenica.ffmpegkit.FFmpegKit
import java.io.File

class FileProcessor(
        private val channelManager: ChannelManager,
        private val downloadManager: DownloadManager
) {
    private val tag = "FlutterYtDlpPlugin"

    fun mergeFiles(videoPath: String, audioPath: String, outputPath: String) {
        val command = "-i \"$videoPath\" -i \"$audioPath\" -c:v copy -c:a aac \"$outputPath\""
        executeFfmpeg(command)
    }

    fun convertFile(taskId: String, tempPath: String, outputPath: String, targetFormat: String) {
        Log.i(tag, "Task $taskId: Converting to $targetFormat")
        val command =
                when (targetFormat) {
                    "mp4" -> "-i \"$tempPath\" -c:v copy -c:a aac \"$outputPath\""
                    "mp3" -> "-i \"$tempPath\" -c:a libmp3lame \"$outputPath\""
                    else -> throw IllegalArgumentException("Unsupported format: $targetFormat")
                }
        executeFfmpeg(command)
        deleteFile(tempPath)
    }

    fun cleanupFiles(vararg paths: String) {
        paths.forEach { deleteFile(it) }
    }

    fun calculateTotalSize(video: Map<String, Any>, audio: Map<String, Any>): Long {
        return (video["size"] as Int).toLong() + (audio["size"] as Int).toLong()
    }

    fun downloadFile(
            module: com.chaquo.python.PyObject,
            url: String,
            formatId: String,
            outputPath: String,
            taskId: String,
            overwrite: Boolean,
            onProgress: (Long, Long) -> Unit
    ) {
        Log.i(tag, "Task $taskId: Starting download for $url with format $formatId")
        module.callAttr(
                "download_format",
                url,
                formatId,
                outputPath,
                overwrite,
                createProgressCallback(taskId, onProgress)
        )
        Log.i(tag, "Task $taskId: Download call completed")
    }

    fun isDownloadActive(taskId: String): Boolean = downloadManager.isDownloadActive(taskId)

    private fun executeFfmpeg(command: String) {
        Log.i(tag, "FFmpeg command: $command")
        FFmpegKit.execute(command)
    }

    private fun deleteFile(path: String) {
        File(path).delete()
    }

    private fun createProgressCallback(taskId: String, onProgress: (Long, Long) -> Unit): Any {
        return object : Any() {
            @Suppress("unused")
            fun onProgress(downloaded: Long, total: Long) {
                if (isDownloadActive(taskId)) {
                    Log.i(tag, "Task $taskId: Progress - $downloaded/$total bytes")
                    onProgress(downloaded, total)
                } else {
                    Log.w(tag, "Task $taskId: Progress ignored, download inactive")
                }
            }
        }
    }
}
