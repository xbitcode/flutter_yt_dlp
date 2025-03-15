package com.example.flutter_yt_dlp

class JsonParser {
    fun parseJsonList(json: String): List<Map<String, Any>> {
        val listType = object : com.fasterxml.jackson.core.type.TypeReference<List<Map<String, Any>>>() {}
        return com.fasterxml.jackson.databind.ObjectMapper().readValue(json, listType)
    }

    fun parseJsonMap(json: String): Map<String, Any> {
        val mapType = object : com.fasterxml.jackson.core.type.TypeReference<Map<String, Any>>() {}
        return com.fasterxml.jackson.databind.ObjectMapper().readValue(json, mapType)
    }
}