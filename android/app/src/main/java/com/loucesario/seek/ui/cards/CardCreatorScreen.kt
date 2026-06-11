package com.loucesario.seek.ui.cards

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.loucesario.seek.cards.CardDraft
import com.loucesario.seek.cards.CardExport
import com.loucesario.seek.cards.CardRenderer
import com.loucesario.seek.cards.CardTemplate
import com.loucesario.seek.cards.CardTemplates
import com.loucesario.seek.ui.theme.SeekColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardCreatorScreen(onBack: () -> Unit, vm: CardCreatorViewModel = viewModel()) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }

    val verseText = CardDraft.verseText
    val reference = CardDraft.reference
    val verseContext = CardDraft.context?.takeIf { it.isNotBlank() }
    var template by remember { mutableStateOf(CardTemplates.all.first()) }
    var includeInterpretation by remember { mutableStateOf(false) }

    val activeInterpretation = if (includeInterpretation) verseContext else null

    // Single renderer drives the preview; recomputed when template or the
    // interpretation toggle changes.
    val bitmap = remember(template.id, verseText, reference, activeInterpretation) {
        CardRenderer.render(template, verseText, reference, activeInterpretation)
    }

    Scaffold(
        containerColor = SeekColors.Background,
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            TopAppBar(
                title = { Text("Create card", color = SeekColors.TextPrimary) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back", tint = SeekColors.TextPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SeekColors.Background),
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.fillMaxSize().padding(inner).padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Preview (true rendered bitmap, 9:16)
            androidx.compose.foundation.Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "Card preview",
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .weight(1f)
                    .aspectRatio(9f / 16f)
                    .clip(RoundedCornerShape(16.dp)),
            )

            Spacer(Modifier.height(12.dp))

            // Template picker
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                items(CardTemplates.all) { t -> TemplateSwatch(t, selected = t.id == template.id) { template = t } }
            }

            // Interpretation toggle — only when the card came from a chat verse.
            if (verseContext != null) {
                Spacer(Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Column(Modifier.weight(1f)) {
                        Text("Include interpretation", fontSize = 15.sp, color = SeekColors.TextPrimary)
                        Text(
                            verseContext,
                            fontSize = 12.sp,
                            color = SeekColors.TextSecondary,
                            maxLines = 2,
                            overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis,
                        )
                    }
                    Switch(
                        checked = includeInterpretation,
                        onCheckedChange = { includeInterpretation = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = SeekColors.Surface,
                            checkedTrackColor = SeekColors.Sage,
                        ),
                    )
                }
            }

            Spacer(Modifier.height(16.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = {
                        context.startActivity(Intent.createChooser(CardExport.shareIntent(context, bitmap), "Share verse card"))
                    },
                    modifier = Modifier.weight(1f).height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                ) { Text("Share", color = SeekColors.TextPrimary) }

                Button(
                    onClick = {
                        scope.launch {
                            val ok = withContext(Dispatchers.IO) { CardExport.saveToGallery(context, bitmap) }
                            vm.persist(template.id, verseText, reference, activeInterpretation)
                            snackbar.showSnackbar(if (ok) "Saved to your gallery" else "Couldn't save to gallery")
                        }
                    },
                    modifier = Modifier.weight(1f).height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
                ) { Text("Save", color = SeekColors.Surface) }
            }
        }
    }
}

@Composable
private fun TemplateSwatch(template: CardTemplate, selected: Boolean, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(54.dp)
                .clip(CircleShape)
                .background(template.topColor)
                .then(if (selected) Modifier.border(3.dp, SeekColors.Sage, CircleShape) else Modifier)
                .clickable(onClick = onClick),
        )
        Text(template.name, fontSize = 11.sp, color = SeekColors.TextSecondary, modifier = Modifier.padding(top = 4.dp))
    }
}
