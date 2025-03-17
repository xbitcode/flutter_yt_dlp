package com.example.flutter_yt_dlp

enum class DownloadState {
    PREPARING,
    DOWNLOADING,
    CONVERTING,
    MERGING,
    COMPLETED,
    CANCELED,
    FAILED
}
