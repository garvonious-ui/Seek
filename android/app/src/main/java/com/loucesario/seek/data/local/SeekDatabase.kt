package com.loucesario.seek.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.local.entity.UserProfileEntity

@Database(
    entities = [
        UserProfileEntity::class,
        SavedCardEntity::class,
        ChatConversationEntity::class,
        ChatMessageEntity::class,
        FavoriteVerseEntity::class,
        SavedPrayerEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class SeekDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun savedCardDao(): SavedCardDao
    abstract fun favoriteVerseDao(): FavoriteVerseDao
    abstract fun savedPrayerDao(): SavedPrayerDao
    abstract fun chatDao(): ChatDao

    companion object {
        @Volatile
        private var INSTANCE: SeekDatabase? = null

        fun get(context: Context): SeekDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    SeekDatabase::class.java,
                    "seek.db",
                ).build().also { INSTANCE = it }
            }
    }
}
