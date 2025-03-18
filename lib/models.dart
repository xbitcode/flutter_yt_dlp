/// Represents the possible states of a download process.
enum DownloadState {
  /// The download is being prepared.
  preparing,

  /// The download is in progress.
  downloading,

  /// The downloaded file is being converted.
  converting,

  /// Video and audio streams are being merged.
  merging,

  /// The download has completed successfully.
  completed,

  /// The download was canceled by the user.
  canceled,

  /// The download failed due to an error.
  failed,
}
