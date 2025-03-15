package com.example.flutter_yt_dlp

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoInfoFetcher {
    private val TAG = "FlutterYtDlpPlugin"
    private val jsonParser = JsonParser()

    companion object {
        private val videoInfoCache = mutableMapOf<String, Map<String, Any>>()
    }

    fun fetchVideoInfo(call: MethodCall, result: MethodChannel.Result, module: com.chaquo.python.PyObject) {
        val url = call.argument<String>("url")!!
        if (videoInfoCache.containsKey(url)) {
            Log.i(TAG, "Returning cached video info for: $url")
            result.success(videoInfoCache[url])
            return
        }
        Log.i(TAG, "Fetching video info for: $url")
        val infoJson = module.callAttr("get_video_info", url).toString()
        val info = jsonParser.parseJsonMap(infoJson)
        videoInfoCache[url] = info
        Log.i(TAG, "Video info fetched and cached for $url")
        result.success(info)
    }

    fun fetchThumbnailUrl(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")!!
        val cachedInfo = videoInfoCache[url]
        if (cachedInfo != null) {
            Log.i(TAG, "Returning cached thumbnail URL for: $url")
            result.success(cachedInfo["thumbnail"])
        } else {
            Log.w(TAG, "No cached info for $url, fetching video info first")
            fetchVideoInfo(call, result, com.chaquo.python.Python.getInstance().getModule("yt_dlp_helper"))
        }
    }
}