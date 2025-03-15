package com.example.flutter_yt_dlp

class ProgressTracker(val totalSize: Long) {
    private var downloadedVideo: Long = 0
    private var downloadedAudio: Long = 0

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