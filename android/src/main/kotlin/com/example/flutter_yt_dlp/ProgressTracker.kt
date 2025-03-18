package com.example.flutter_yt_dlp

class ProgressTracker(val totalSize: Long) {
    @Volatile private var downloadedVideo: Long = 0
    @Volatile private var downloadedAudio: Long = 0

    @Synchronized
    fun updateVideoProgress(downloaded: Long) {
        downloadedVideo = downloaded
    }

    @Synchronized
    fun updateAudioProgress(downloaded: Long) {
        downloadedAudio = downloaded
    }

    // Returns the sum of downloaded video and audio bytes
    @Synchronized fun getCombinedDownloaded(): Long = downloadedVideo + downloadedAudio
}
