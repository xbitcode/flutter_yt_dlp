import yt_dlp
import json
import os
import logging
from io import StringIO

# Configure logging with DEBUG level for detailed output
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class LogCapture(StringIO):
    """Captures yt-dlp output for logging."""
    def write(self, message):
        if message.strip():
            logger.debug(f"yt-dlp output: {message.strip()}")

def extract_format_info(format_data, video_duration=None):
    """Extracts format info from yt-dlp data, with duration-based size fallback."""
    # Base size from yt-dlp (exact or approximate)
    raw_size = format_data.get("filesize") or format_data.get("filesize_approx")
    try:
        size = int(raw_size)
    except (TypeError, ValueError):
        size = 0

    # Fallback: estimate via average bitrate × duration
    if size == 0 and video_duration:
        tbr = format_data.get("tbr")  # in Kbps
        if tbr:
            # (tbr kilobits per second → bytes per second) × duration (seconds)
            size = int((tbr * 1000 / 8) * video_duration)

    return {
        "formatId":  format_data.get("format_id", "unknown"),
        "ext":       format_data.get("ext", "unknown"),
        "resolution": (
            format_data.get("resolution", "unknown")
            if format_data.get("vcodec", "none") != "none"
            else "audio only"
        ),
        "bitrate":  int(format_data.get("tbr", 0) or 0),
        "size":     size,
        "vcodec":   format_data.get("vcodec", "none"),
        "acodec":   format_data.get("acodec", "none"),
    }


def get_video_info(url):
    """Fetches video metadata and formats."""
    ydl_opts = {
        "quiet":     True,
        "cachedir":  False,
        # "format":  "bestvideo+bestaudio/best",
        "user_agent":"Mozilla/6.0 (compatible; MyDownloader/1.0)",
        "logger":    logger,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            duration = info.get("duration")  # in seconds
            video_info = {
                "title":     info.get("title", "unknown_video"),
                "thumbnail": info.get("thumbnail"),
                "formats":   [
                    extract_format_info(fmt, video_duration=duration)
                    for fmt in info.get("formats", [])
                ],
            }
            logger.info(f"Fetched info for {url}: {len(video_info['formats'])} formats")
            return json.dumps(video_info)
    except Exception as e:
        logger.error(f"Error fetching info for {url}: {e}")
        return json.dumps({
            "title":     "unknown_video",
            "thumbnail": None,
            "formats":   []
        })

def download_format(url, format_id, output_path, overwrite, progress_callback):
    """Downloads a specific format with progress updates."""
    log_capture = LogCapture()

    def progress_hook(d):
        status = d.get("status")
        if status == "downloading":
            downloaded = int(d.get("downloaded_bytes", 0))  # Convert to int
            total = int(d.get("total_bytes", d.get("total_bytes_estimate", 0) or 0))  # Convert to int
            if total > 0:
                logger.info(f"Progress for {url}: {downloaded}/{total} bytes")
                progress_callback.onProgress(downloaded, total)
        elif status == "finished":
            total = int(d.get("total_bytes", d.get("total_bytes_estimate", 0) or 0))  # Convert to int
            logger.info(f"Download finished for {url}: {total} bytes")
            progress_callback.onProgress(total, total)
        elif status == "error":
            logger.error(f"Download error for {url}: {d.get('error')}")

    ydl_opts = {
        "format": format_id,
        "outtmpl": output_path,
        "progress_hooks": [progress_hook],
        #"force_overwrites": overwrite,
        "noprogress": False,
        "quiet": True,              # Allow yt-dlp output for debugging
        "logger": logger,
        "verbose": False,             # Enable verbose output for debugging
        "cachedir": False,
        "logtostderr": True,         # Ensure logs go to stderr
        "errfile": log_capture,      # Capture errors
        "outfile": log_capture,      # Capture output
        "user_agent": "Mozilla/6.0 (compatible; MyDownloader/1.0)",
        "concurrent_fragments": 128,   # Download up to 16 fragments in parallel
    }
    
    # ydl_opts = {
    #     "format": format_id,
    #     "outtmpl": output_path,
    #     "progress_hooks": [progress_hook],
    #     "force_overwrites": overwrite,
    #     "noprogress": False,
    #     "quiet": False,  # Allow yt-dlp output for debugging
    #     "logger": logger,
    #     "verbose": True,  # Enable verbose output for debugging
    #     "logtostderr": True,  # Ensure logs go to stderr
    #     "errfile": log_capture,  # Capture errors
    #     "outfile": log_capture,  # Capture output
    # }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            logger.info(f"Starting download: {url} format {format_id} to {output_path}")
            ydl.download([url])
            logger.info(f"Download completed for {url}")
    except Exception as e:
        logger.error(f"Download failed for {url}: {str(e)}")
        raise
