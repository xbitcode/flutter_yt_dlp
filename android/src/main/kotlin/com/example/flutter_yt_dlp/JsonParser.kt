package com.example.flutter_yt_dlp

import com.fasterxml.jackson.databind.ObjectMapper

class JsonParser {
    private val mapper = ObjectMapper()

    fun parseJsonList(json: String): List<Map<String, Any>> {
        return mapper.readValue(
                json,
                mapper.typeFactory.constructCollectionType(List::class.java, Map::class.java)
        )
    }

    fun parseJsonMap(json: String): Map<String, Any> {
        return mapper.readValue(
                json,
                mapper.typeFactory.constructMapType(
                        Map::class.java,
                        String::class.java,
                        Any::class.java
                )
        )
    }
}
