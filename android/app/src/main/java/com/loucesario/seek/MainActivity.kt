package com.loucesario.seek

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.loucesario.seek.ui.SeekApp
import com.loucesario.seek.ui.theme.SeekTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SeekTheme {
                SeekApp()
            }
        }
    }
}
