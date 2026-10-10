package com.loucesario.seek.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.local.entity.SyncTombstoneEntity
import com.loucesario.seek.data.local.entity.UserProfileEntity

@Database(
    entities = [
        UserProfileEntity::class,
        SavedCardEntity::class,
        ChatConversationEntity::class,
        ChatMessageEntity::class,
        FavoriteVerseEntity::class,
        SavedPrayerEntity::class,
        SyncTombstoneEntity::class,
    ],
    version = 2,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class SeekDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun savedCardDao(): SavedCardDao
    abstract fun favoriteVerseDao(): FavoriteVerseDao
    abstract fun savedPrayerDao(): SavedPrayerDao
    abstract fun chatDao(): ChatDao
    abstract fun syncDao(): SyncDao

    companion object {
        @Volatile
        private var INSTANCE: SeekDatabase? = null

        fun get(context: Context): SeekDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    SeekDatabase::class.java,
                    "seek.db",
                ).addMigrations(MIGRATION_1_2).build().also { INSTANCE = it }
            }
    }
}

/**
 * v2 — cloud sync. Every synced table gets a needsSync flag (existing rows start
 * dirty, which is what uploads them on the first sync) and deletes waiting to be
 * pushed live in sync_tombstone.
 */
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        for (table in listOf("saved_card", "chat_conversation", "chat_message", "favorite_verse", "saved_prayer")) {
            db.execSQL("ALTER TABLE `$table` ADD COLUMN `needsSync` INTEGER NOT NULL DEFAULT 1")
        }
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS `sync_tombstone` (`id` TEXT NOT NULL, `remoteTable` TEXT NOT NULL, " +
                "`deletedAt` INTEGER NOT NULL, PRIMARY KEY(`id`))"
        )
    }
}
