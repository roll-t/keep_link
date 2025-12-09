package io.flutter.plugins

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.core.content.edit

class LinkAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            val text = when {
                event.text.isNotEmpty() ->
                    event.text.joinToString(" ")
                event.source != null ->
                    extractText(event.source)
                else -> ""
            }
            Log.d("Accessibility", "###$text");
            if (text.contains("http")) {
                val url = extractUrl(text)
                if (url != null) {
                    val prefs = getSharedPreferences("link_data", Context.MODE_PRIVATE)
                    prefs.edit() { putString("current_url", url) }
                }
            }
        } catch (_: Exception) {}
    }

    private fun extractText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        val builder = StringBuilder()

        if (node.text != null) builder.append(node.text.toString()).append(" ")

        for (i in 0 until node.childCount) {
            builder.append(extractText(node.getChild(i)))
        }

        return builder.toString()
    }

    private fun extractUrl(text: String): String? {
        val regex = "(https?://\\S+)".toRegex()
        return regex.find(text)?.value
    }

    override fun onInterrupt() {}
}
