package com.loucesario.seek.cards

/**
 * In-memory holder for the verse being turned into a card. Set this before
 * navigating to the card route — avoids URL-encoding verse text (which contains
 * spaces, colons, and punctuation) through nav path args.
 */
object CardDraft {
    var verseText: String = ""
    var reference: String = ""

    fun set(text: String, ref: String) {
        verseText = text
        reference = ref
    }
}
