package com.example.flutter_yt_dlp

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoInfoFetcher {
    private val tag = "FlutterYtDlpPlugin"
    private val jsonParser = JsonParser()
    private val cache = mutableMapOf<String, Map<String, Any>>()

    fun fetchVideoInfo(
            call: MethodCall,
            result: MethodChannel.Result,
            module: com.chaquo.python.PyObject
    ) {
        val url =
                call.argument<String>("url")
                        ?: return result.error("INVALID_URL", "URL missing", null)
        if (cache.containsKey(url)) {
            Log.i(tag, "Returning cached video info for: $url")
            return result.success(cache[url])
        }
        Log.i(tag, "Fetching video info for: $url")
        val infoJson = module.callAttr("get_video_info", url).toString()
        val info = jsonParser.parseJsonMap(infoJson)
        cache[url] = info
        result.success(info)
    }

    fun fetchThumbnailUrl(call: MethodCall, result: MethodChannel.Result) {
        val url =
                call.argument<String>("url")
                        ?: return result.error("INVALID_URL", "URL missing", null)
        cache[url]?.let {
            Log.i(tag, "Returning cached thumbnail for: $url")
            result.success(it["thumbnail"])
        }
                ?: run {
                    Log.w(tag, "No cached info for $url, fetching anew")
                    fetchVideoInfo(
                            call,
                            result,
                            com.chaquo.python.Python.getInstance().getModule("yt_dlp_helper")
                    )
                }
    }
}
