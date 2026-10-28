package com.bpetrov.yumsum

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Reopening the app from Recents re-delivers the intent that first
        // started this task. Strip the widget URI and the shortcut extra from
        // it, or the mic would start again every time the app is brought
        // back after Android killed it in the background.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) {
            intent.data = null
            intent.action = Intent.ACTION_MAIN
            intent.removeExtra("some unique action key") // quick_actions' key
        }
        super.onCreate(savedInstanceState)
    }
}
