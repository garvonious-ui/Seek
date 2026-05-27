package com.loucesario.seek.data.local

import androidx.room.TypeConverter

/**
 * Room type converters. Dates are stored as epoch-millis [Long] (nullable as
 * Long?); String lists as a newline-joined blob (verse references / topics
 * never contain newlines).
 */
class Converters {
    @TypeConverter
    fun fromStringList(value: List<String>?): String? =
        value?.joinToString("\n")

    @TypeConverter
    fun toStringList(value: String?): List<String> =
        if (value.isNullOrEmpty()) emptyList() else value.split("\n")
}
