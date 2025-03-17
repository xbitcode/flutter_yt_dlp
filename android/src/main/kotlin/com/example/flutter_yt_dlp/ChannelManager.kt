package com.example.flutter_yt_dlp

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class ChannelManager(binding: FlutterPlugin.FlutterPluginBinding) {
    private val methodChannel = MethodChannel(binding.binaryMessenger, "flutter_yt_dlp")
    private val eventChannel = EventChannel(binding.binaryMessenger, "flutter_yt_dlp/events")
    private var eventSink: EventChannel.EventSink? = null

    fun setMethodHandler(handler: MethodChannel.MethodCallHandler) {
        methodChannel.setMethodCallHandler(handler)
    }

    fun setStreamHandler(handler: EventChannel.StreamHandler) {
        eventChannel.setStreamHandler(handler)
    }

    fun clearHandlers() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
    }

    fun sendEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }
}
