package com.loucesario.seek.data.local

import androidx.room.Embedded
import androidx.room.Relation
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity

/** A conversation with its ordered messages (cascade-deleted with the parent). */
data class ConversationWithMessages(
    @Embedded val conversation: ChatConversationEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "conversationId",
    )
    val messages: List<ChatMessageEntity>,
)
