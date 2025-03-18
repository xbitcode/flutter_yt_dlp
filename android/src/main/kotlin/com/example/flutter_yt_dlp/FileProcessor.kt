package com.example.flutter_yt_dlp

import android.util.Log
import com.arthenica.ffmpegkit.FFmpegKit
import java.io.File

class FileProcessor(
    private val channelManager: ChannelManager,
    private val downloadManager: DownloadManager
) {
    private val tag = "FlutterYtDlp"

    fun mergeFiles(videoPath: String, audioPath: String, outputPath: String) {
        val command = "-i \"$videoPath\" -i \"$audioPath\" -c:v copy -c:a aac \"$outputPath\""
        Log.i(tag, "Merging files: $videoPath + $audioPath -> $outputPath")
        executeFfmpeg(command)
    }

    fun convertFile(taskId: String, tempPath: String, outputPath: String, targetFormat: String) {
        val command = when (targetFormat) {
            "mp4" -> "-i \"$tempPath\" -c:v copy -c:a aac \"$outputPath\""
            "mp3" -> "-i \"$tempPath\" -c:a libmp3lame \"$outputPath\""
            else -> throw IllegalArgumentException("Unsupported format: $targetFormat")
        }
        Log.i(tag, "Task $taskId: Converting $tempPath to $outputPath ($targetFormat)")
        executeFfmpeg(command) // Correct method name
        deleteFile(tempPath)
    }

    fun cleanupFiles(vararg paths: String) {
        paths.forEach { path ->
            Log.d(tag, "Cleaning up temporary file: $path")
            deleteFile(path)
        }
    }

    fun calculateTotalSize(video: Map<String, Any>, audio: Map<String, Any>): Long {
        val total = (video["size"] as Int).toLong() + (audio["size"] as Int).toLong()
        Log.d(tag, "Calculated total size: $total bytes")
        return total
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
        Log.i(tag, "Task $taskId: Downloading $url (format: $formatId) to $outputPath")
        module.callAttr(
            "download_format",
            url,
            formatId,
            outputPath,
            overwrite,
            createProgressCallback(taskId, onProgress)
        )
        if (isDownloadActive(taskId)) {
            Log.i(tag, "Task $taskId: Download completed successfully")
        } else {
            Log.w(tag, "Task $taskId: Download interrupted")
        }
    }

    fun isDownloadActive(taskId: String): Boolean = downloadManager.isDownloadActive(taskId)

    private fun executeFfmpeg(command: String) { // Corrected method name
        Log.d(tag, "Executing FFmpeg: $command")
        val session = FFmpegKit.execute(command)
        if (session.returnCode.isValueSuccess) {
            Log.i(tag, "FFmpeg command executed successfully")
        } else {
            Log.e(tag, "FFmpeg command failed with return code: ${session.returnCode}")
            throw RuntimeException("FFmpeg execution failed")
        }
    }

    private fun deleteFile(path: String) {
        val file = File(path)
        if (file.exists()) {
            file.delete()
            Log.d(tag, "Deleted file: $path")
        } else {
            Log.w(tag, "File not found for deletion: $path")
        }
    }

    private fun createProgressCallback(taskId: String, onProgress: (Long, Long) -> Unit): Any {
        return object : Any() {
            @Suppress("unused")
            fun onProgress(downloaded: Long, total: Long) {
                if (isDownloadActive(taskId)) {
                    Log.d(tag, "Task $taskId: Download progress - $downloaded/$total bytes")
                    onProgress(downloaded, total)
                } else {
                    Log.w(tag, "Task $taskId: Progress callback ignored, download inactive")
                }
            }
        }
    }
}