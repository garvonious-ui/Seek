package com.loucesario.seek.cards

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.loucesario.seek.data.WeeklySummary

/**
 * Draws the shareable weekly recap ("Evening" — verse-led, dark), a port of the
 * iOS WeeklyShareCardView. Laid out in a 540-wide space and scaled off the
 * target width, so the 1080x1920 story export and the small thumbnail on the
 * recap screen are the same layout — one renderer, like [CardRenderer].
 */
object WeeklyCardRenderer {
    private val BACKGROUND = 0xFF1F2B22.toInt()
    private val CREAM = 0xFFF4EFE3.toInt()
    private val MUTED = 0xFFB9C2B5.toInt()
    private val GOLD = 0xFFCDA349.toInt()
    private val DOT_OFF = 0xFF5E6E60.toInt()
    private val FOOTER = 0xFF8E9A8B.toInt()

    private val sans: Typeface = Typeface.DEFAULT
    private val sansSemibold: Typeface by lazy {
        if (Build.VERSION.SDK_INT >= 28) Typeface.create(Typeface.DEFAULT, 600, false)
        else Typeface.create("sans-serif-medium", Typeface.NORMAL)
    }
    private val serif: Typeface get() = CardRenderer.loraRegular

    fun render(summary: WeeklySummary, width: Int = CardRenderer.W, height: Int = CardRenderer.H): Bitmap {
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        canvas.drawColor(BACKGROUND)
        val s = width / 540f
        val b = Blocks(s, width.toFloat())

        val header = b.column(8f, listOf(
            b.text("YOUR WEEK WITH SEEK", 12f, GOLD, sansSemibold, tracking = 2.2f),
            b.text(summary.dateRange, 15f, MUTED, sans),
        ))
        val footer = b.column(22f, listOfNotNull(
            b.column(12f, listOf(
                b.dots(summary.activeDays),
                b.text("${summary.daysActive} of 7 days in the Word", 16f, CREAM, sans),
            )),
            b.stats(listOf(
                Triple(summary.versesExplored, "verse", "verses"),
                Triple(summary.prayersSaved, "prayer", "prayers"),
                Triple(summary.cardsMade, "card", "cards"),
            )),
            summary.themes.takeIf { it.isNotEmpty() }?.let { themes ->
                b.text("On your heart: ${themes.joinToString(", ") { it.lowercase() }}", 14f, MUTED, sans)
            },
            b.paddedTop(10f, b.column(2f, listOf(
                b.text("Seek", 26f, GOLD, serif),
                b.text("askseekpray.app", 12f, FOOTER, sans),
            ))),
        ))

        // Between the paddings, two flexible spacers (min 24 each) share what's
        // left, centering the verse block. Long passages shrink to fit
        // (iOS minimumScaleFactor 0.7).
        val inner = height - (56 + 40) * s
        var verse = verseBlock(b, summary, 1f)
        for (step in 1..6) {
            if (header.height + verse.height + footer.height + 48 * s <= inner) break
            verse = verseBlock(b, summary, 1f - step * 0.05f)
        }
        val gap = maxOf(24 * s, (inner - header.height - verse.height - footer.height) / 2)

        header.draw(canvas, 56 * s)
        verse.draw(canvas, 56 * s + header.height + gap)
        footer.draw(canvas, height - 40 * s - footer.height)
        return bmp
    }

    private fun verseBlock(b: Blocks, summary: WeeklySummary, scale: Float): Block {
        val size = verseSize(summary.verseText) * scale
        return b.column(28f, listOf(
            b.rule(),
            b.text("THE VERSE THAT CARRIED YOUR WEEK", 11f, MUTED, sansSemibold, tracking = 2f),
            b.text("“${summary.verseText}”", size, CREAM, serif, lineSpacing = size * 0.4f),
            b.text(summary.verseReference, 15f, GOLD, sansSemibold, tracking = 0.6f),
            b.rule(),
        ))
    }

    /** Shrink long passages so the verse never crowds the stats. */
    private fun verseSize(text: String): Float = when {
        text.length < 110 -> 34f
        text.length < 180 -> 29f
        text.length < 260 -> 25f
        else -> 22f
    }

    /** A laid-out piece of the card: its height, and how to draw it from a top edge. */
    private class Block(val height: Float, val draw: Canvas.(top: Float) -> Unit)

    /** Block builders; sizes are in 540-wide units, scaled by [s] to pixels. */
    private class Blocks(private val s: Float, width: Float) {
        private val left = 48 * s
        private val contentWidth = (width - 2 * left).toInt().coerceAtLeast(1)
        private val center = width / 2

        fun column(spacing: Float, blocks: List<Block>): Block {
            val gap = spacing * s
            val height = blocks.sumOf { it.height.toDouble() }.toFloat() + gap * (blocks.size - 1).coerceAtLeast(0)
            return Block(height) { top ->
                var y = top
                blocks.forEach { block -> block.draw(this, y); y += block.height + gap }
            }
        }

        fun paddedTop(padding: Float, block: Block): Block =
            Block(padding * s + block.height) { top -> block.draw(this, top + padding * s) }

        /** Centered, wrapping text across the content width. */
        fun text(
            value: String,
            size: Float,
            color: Int,
            typeface: Typeface,
            tracking: Float = 0f,
            lineSpacing: Float = 0f,
        ): Block {
            val layout = StaticLayout.Builder
                .obtain(value, 0, value.length, paint(size, color, typeface, tracking), contentWidth)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setLineSpacing(lineSpacing * s, 1f)
                .setIncludePad(false)
                .build()
            return Block(layout.height.toFloat()) { top ->
                save()
                translate(left, top)
                layout.draw(this)
                restore()
            }
        }

        fun rule(): Block {
            val thickness = maxOf(1f, s)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = GOLD }
            return Block(thickness) { top -> drawRect(center - 24 * s, top, center + 24 * s, top + thickness, paint) }
        }

        /** Mon…Sun: gold dots for active days, outlined for the rest. */
        fun dots(active: List<Boolean>): Block {
            val d = 14 * s
            val gap = 10 * s
            val stroke = 1.5f * s
            val on = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = GOLD }
            val off = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = DOT_OFF
                style = Paint.Style.STROKE
                strokeWidth = stroke
            }
            return Block(d) { top ->
                var x = center - (active.size * d + (active.size - 1) * gap) / 2
                active.forEach { isActive ->
                    // Stroke inside the dot's bounds, like SwiftUI's strokeBorder.
                    if (isActive) drawCircle(x + d / 2, top + d / 2, d / 2, on)
                    else drawCircle(x + d / 2, top + d / 2, (d - stroke) / 2, off)
                    x += d + gap
                }
            }
        }

        /** "23 verses · 4 prayers · 2 cards" — serif numbers, sans labels, items centered vertically. */
        fun stats(values: List<Triple<Int, String, String>>): Block {
            val number = paint(22f, CREAM, serif)
            val label = paint(15f, MUTED, sans)
            val separator = listOf("·" to paint(15f, DOT_OFF, sans))
            val items = values.flatMapIndexed { i, (value, singular, plural) ->
                val stat = listOf("$value" to number, " ${if (value == 1) singular else plural}" to label)
                if (i == 0) listOf(stat) else listOf(separator, stat)
            }
            val gap = 14 * s
            val ascents = items.map { runs -> runs.maxOf { -it.second.fontMetrics.ascent } }
            val heights = items.mapIndexed { i, runs -> ascents[i] + runs.maxOf { it.second.fontMetrics.descent } }
            val widths = items.map { runs -> runs.sumOf { (text, paint) -> paint.measureText(text).toDouble() }.toFloat() }
            val rowHeight = heights.max()
            return Block(rowHeight) { top ->
                var x = center - (widths.sum() + gap * (items.size - 1)) / 2
                items.forEachIndexed { i, runs ->
                    val baseline = top + (rowHeight - heights[i]) / 2 + ascents[i]
                    var runX = x
                    runs.forEach { (text, paint) ->
                        drawText(text, runX, baseline, paint)
                        runX += paint.measureText(text)
                    }
                    x += widths[i] + gap
                }
            }
        }

        private fun paint(size: Float, color: Int, typeface: Typeface, tracking: Float = 0f) =
            TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = size * s
                this.color = color
                this.typeface = typeface
                letterSpacing = tracking / size // SwiftUI tracking (points) → ems
            }
    }
}
