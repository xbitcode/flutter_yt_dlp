import yt_dlp
import json
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _extract_format_info(f):
    return {
        "formatId": f.get("format_id", "unknown"),
        "ext": f.get("ext", "unknown"),
        "resolution": (
            f.get("resolution", "unknown")
            if f.get("vcodec", "none") != "none"
            else "audio only"
        ),
        "bitrate": int(f.get("tbr", 0)),
        "size": int(f.get("filesize", 0) or f.get("filesize_approx", 0) or 0),
    }


def get_all_raw_video_with_sound_formats(url):
    ydl_opts = {"quiet": True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = [
                f
                for f in info["formats"]
                if f.get("vcodec", "none") != "none"
                and f.get("acodec", "none") != "none"
            ]
            if not formats:
                logger.warning(f"No raw video with sound formats found for {url}")
            result = json.dumps([_extract_format_info(f) for f in formats])
            logger.info(f"Fetched {len(formats)} raw video+sound formats for {url}")
            return result
    except Exception as e:
        logger.error(f"Error fetching raw video+sound formats for {url}: {str(e)}")
        return json.dumps([])


def get_raw_video_and_audio_formats_for_merge(url):
    ydl_opts = {"quiet": True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            video_formats = [
                f
                for f in info["formats"]
                if f.get("vcodec", "none") != "none"
                and f.get("acodec", "none") == "none"
            ]
            audio_formats = sorted(
                [
                    f
                    for f in info["formats"]
                    if f.get("vcodec", "none") == "none"
                    and f.get("acodec", "none") != "none"
                ],
                key=lambda x: x.get("tbr", 0),
                reverse=True,
            )
            if not audio_formats or not video_formats:
                logger.warning(f"No mergeable video or audio formats found for {url}")
                return json.dumps([])
            best_audio = audio_formats[0]
            result = json.dumps(
                [
                    {
                        "video": _extract_format_info(v),
                        "audio": _extract_format_info(best_audio),
                    }
                    for v in video_formats
                ]
            )
            logger.info(f"Fetched {len(video_formats)} merge formats for {url}")
            return result
    except Exception as e:
        logger.error(f"Error fetching merge formats for {url}: {str(e)}")
        return json.dumps([])


def get_non_mp4_video_with_sound_formats_for_conversion(url):
    ydl_opts = {"quiet": True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = [
                f
                for f in info["formats"]
                if f.get("vcodec", "none") != "none"
                and f.get("acodec", "none") != "none"
                and f.get("ext", "") != "mp4"
            ]
            if not formats:
                logger.warning(f"No non-MP4 video+sound formats found for {url}")
            result = json.dumps([_extract_format_info(f) for f in formats])
            logger.info(f"Fetched {len(formats)} non-MP4 video+sound formats for {url}")
            return result
    except Exception as e:
        logger.error(f"Error fetching non-MP4 video+sound formats for {url}: {str(e)}")
        return json.dumps([])


def get_all_raw_audio_only_formats(url):
    ydl_opts = {"quiet": True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = [
                f
                for f in info["formats"]
                if f.get("vcodec", "none") == "none"
                and f.get("acodec", "none") != "none"
            ]
            if not formats:
                logger.warning(f"No raw audio-only formats found for {url}")
            result = json.dumps([_extract_format_info(f) for f in formats])
            logger.info(f"Fetched {len(formats)} raw audio-only formats for {url}")
            return result
    except Exception as e:
        logger.error(f"Error fetching raw audio-only formats for {url}: {str(e)}")
        return json.dumps([])


def get_non_mp3_audio_only_formats_for_conversion(url):
    ydl_opts = {"quiet": True}
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = [
                f
                for f in info["formats"]
                if f.get("vcodec", "none") == "none"
                and f.get("acodec", "none") != "none"
                and f.get("ext", "") != "mp3"
            ]
            if not formats:
                logger.warning(f"No non-MP3 audio-only formats found for {url}")
            result = json.dumps([_extract_format_info(f) for f in formats])
            logger.info(f"Fetched {len(formats)} non-MP3 audio-only formats for {url}")
            return result
    except Exception as e:
        logger.error(f"Error fetching non-MP3 audio-only formats for {url}: {str(e)}")
        return json.dumps([])


def download_format(url, format_id, output_path, overwrite, progress_callback):
    def hook(d):
        if d["status"] == "downloading":
            downloaded = d.get("downloaded_bytes", 0)
            total = d.get("total_bytes", 0) or d.get("total_bytes_estimated", 0) or 0
            progress_callback.onProgress(downloaded, total)
        elif d["status"] == "finished":
            total = d.get("total_bytes", 0) or d.get("total_bytes_estimated", 0) or 0
            progress_callback.onProgress(total, total)

    ydl_opts = {
        "format": format_id,
        "outtmpl": output_path,
        "progress_hooks": [hook],
        "force_overwrites": overwrite,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            logger.info(
                f"Starting download for {url} with format {format_id} to {output_path}"
            )
            ydl.download([url])
            logger.info(f"Download completed for {url} to {output_path}")
    except Exception as e:
        logger.error(f"Download failed for {url}: {str(e)}")
        raise
