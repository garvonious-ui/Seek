package com.loucesario.seek.cards

/**
 * In-memory holder for the verse being turned into a card. Set this before
 * navigating to the card route — avoids URL-encoding verse text (which contains
 * spaces, colons, and punctuation) through nav path args.
 */
object CardDraft {
    var verseText: String = ""
    var reference: String = ""
    /** AI interpretation of the verse (chat `context`); null for daily verse / prayer. */
    var context: String? = null

    fun set(text: String, ref: String, context: String? = null) {
        verseText = text
        reference = ref
        this.context = context
    }
}
