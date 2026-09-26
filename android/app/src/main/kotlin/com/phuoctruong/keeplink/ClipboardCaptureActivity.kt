package com.phamtruong.keeplink

import android.app.Activity
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast

class ClipboardCaptureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Handler(Looper.getMainLooper()).postDelayed(::forwardClipboardLink, 180)
    }

    private fun forwardClipboardLink() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        val text = clipboard
            ?.primaryClip
            ?.takeIf { it.itemCount > 0 }
            ?.getItemAt(0)
            ?.coerceToText(this)
            ?.toString()
            .orEmpty()
        val url = urlPattern.find(text)?.value?.trimEnd('.', ',', ';', ':', '!', '?', ')', ']', '}')

        if (url.isNullOrBlank()) {
            Toast.makeText(this, "Không đọc được link TikTok đã sao chép", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        startActivity(Intent(this, ShareReceiverActivity::class.java).apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, url)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        })
        finish()
    }

    companion object {
        private val urlPattern = Regex(
            """https?://[^\s<>\"'“”]+""",
            RegexOption.IGNORE_CASE,
        )
    }
}
