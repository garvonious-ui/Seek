package com.loucesario.seek.cards

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.compose.ui.graphics.toArgb
import com.loucesario.seek.SeekApplication

/**
 * Renders a verse card to an exact 1080x1920 PNG-able Bitmap using the Android
 * 2D canvas. This is the SINGLE source of truth — the preview and the exported
 * image both call [render], so they can never diverge (the iOS gotcha where the
 * preview looked right but the export didn't).
 */
object CardRenderer {
    const val W = 1080
    const val H = 1920

    /**
     * Scripture typeface — Lora, bundled in assets/fonts. Loaded once on first
     * card render. Falls back to Typeface.SERIF (Noto Serif) if the asset is
     * missing for any reason — defensive, shouldn't trigger in normal builds.
     */
    private val loraRegular: Typeface by lazy {
        runCatching {
            Typeface.createFromAsset(SeekApplication.instance.assets, "fonts/Lora-Regular.ttf")
        }.getOrElse { Typeface.create(Typeface.SERIF, Typeface.NORMAL) }
    }
    private val loraBold: Typeface by lazy {
        Typeface.create(loraRegular, Typeface.BOLD)
    }

    fun render(template: CardTemplate, verseText: String, reference: String): Bitmap {
        val bmp = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)

        // Vertical gradient background
        val bgPaint = Paint().apply {
            shader = LinearGradient(
                0f, 0f, 0f, H.toFloat(),
                template.topColor.toArgb(), template.bottomColor.toArgb(),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, W.toFloat(), H.toFloat(), bgPaint)

        val sidePadding = 120f
        val maxTextWidth = (W - 2 * sidePadding).toInt()
        val serif = loraRegular

        // Verse text — serif, auto-fit to a vertical budget
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = template.textColor.toArgb()
            typeface = serif
        }
        val heightBudget = 1120
        var size = 96f
        var layout = buildLayout(verseText, textPaint, maxTextWidth, size)
        while (size > 40f && layout.height > heightBudget) {
            size -= 4f
            layout = buildLayout(verseText, textPaint, maxTextWidth, size)
        }

        val verseTop = (H - layout.height) / 2f - 80f
        canvas.save()
        canvas.translate(sidePadding, verseTop)
        layout.draw(canvas)
        canvas.restore()

        // Reference below the verse
        val refPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = template.referenceColor.toArgb()
            typeface = loraBold
            textSize = 46f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(reference, W / 2f, verseTop + layout.height + 96f, refPaint)

        // Watermark
        val wmPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = template.textColor.toArgb()
            alpha = 110
            typeface = serif
            textSize = 40f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("Seek", W / 2f, (H - 96).toFloat(), wmPaint)

        return bmp
    }

    private fun buildLayout(text: String, paint: TextPaint, width: Int, size: Float): StaticLayout {
        paint.textSize = size
        return StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setLineSpacing(10f, 1.1f)
            .setIncludePad(false)
            .build()
    }
}
