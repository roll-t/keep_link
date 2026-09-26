package com.phamtruong.keeplink.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.TextUtils
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicBoolean

class LinkCaptureAccessibilityService : AccessibilityService() {
    data class CaptureResult(
        val url: String? = null,
        val copiedToClipboard: Boolean = false,
        val error: String? = null,
    )

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        if (instance === this) instance = null
        super.onDestroy()
    }

    private fun capture(callback: (CaptureResult) -> Unit) {
        val root = rootInActiveWindow
        val packageName = root?.packageName?.toString().orEmpty()
        if (root == null || packageName.isBlank()) {
            callback(CaptureResult(error = "Không đọc được nội dung ứng dụng hiện tại"))
            return
        }

        val directUrl = findUrl(root, packageName)
        if (directUrl != null) {
            callback(CaptureResult(url = directUrl))
            return
        }

        if (packageName in tiktokPackages) {
            captureTikTokByShareMenu(root, callback)
            return
        }

        val appLabel = when {
            packageName in browserPackages -> "trình duyệt"
            else -> "ứng dụng này"
        }
        callback(CaptureResult(error = "Không tìm thấy URL trong $appLabel"))
    }

    private fun findUrl(root: AccessibilityNodeInfo, packageName: String): String? {
        val isBrowser = packageName in browserPackages
        val isTikTok = packageName in tiktokPackages
        if (!isBrowser && !isTikTok) return null

        var explicitUrl: String? = null
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var visited = 0

        while (queue.isNotEmpty() && visited < maxNodes) {
            val node = queue.removeFirst()
            visited++
            val viewId = node.viewIdResourceName.orEmpty().lowercase()
            val values = listOfNotNull(node.text?.toString(), node.contentDescription?.toString())

            for (value in values) {
                if (isBrowser && addressViewHints.any(viewId::contains)) {
                    normalizeUrl(value, allowBareDomain = true)?.let { return it }
                }
                extractExplicitUrl(value)?.let { candidate ->
                    if (!isTikTok || isTikTokUrl(candidate)) return candidate
                    if (explicitUrl == null) explicitUrl = candidate
                }
            }

            for (index in 0 until node.childCount) {
                node.getChild(index)?.let(queue::addLast)
            }
        }
        return if (isTikTok) null else explicitUrl
    }

    private fun captureTikTokByShareMenu(
        root: AccessibilityNodeInfo,
        callback: (CaptureResult) -> Unit,
    ) {
        val delivered = AtomicBoolean(false)
        fun finish(result: CaptureResult) {
            if (delivered.compareAndSet(false, true)) callback(result)
        }

        val shareNode = findNodeByLabels(root, shareLabels)
        if (shareNode == null || !performClick(shareNode)) {
            finish(CaptureResult(error = "Không tìm thấy nút Chia sẻ của TikTok"))
            return
        }

        handler.postDelayed({
            val shareSheet = rootInActiveWindow
            val copiedDirectly = shareSheet?.let { findUrl(it, it.packageName?.toString().orEmpty()) }
            if (copiedDirectly != null) {
                finish(CaptureResult(url = copiedDirectly))
                return@postDelayed
            }

            val copyNode = shareSheet?.let { findNodeByLabels(it, copyLinkLabels) }
            if (copyNode == null || !performClick(copyNode)) {
                finish(CaptureResult(error = "TikTok chưa hiển thị nút Sao chép liên kết"))
                return@postDelayed
            }

            handler.postDelayed({
                finish(CaptureResult(copiedToClipboard = true))
            }, clipboardDelayMs)
        }, shareSheetDelayMs)

        handler.postDelayed({
            finish(CaptureResult(error = "Quá thời gian lấy link từ TikTok"))
        }, captureTimeoutMs)
    }

    private fun findNodeByLabels(
        root: AccessibilityNodeInfo,
        labels: Set<String>,
    ): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var visited = 0
        while (queue.isNotEmpty() && visited < maxNodes) {
            val node = queue.removeFirst()
            visited++
            val values = listOfNotNull(node.text?.toString(), node.contentDescription?.toString())
            if (values.any { value ->
                    val normalized = value.trim().lowercase()
                    labels.any { label -> normalized == label || normalized.contains(label) }
                }
            ) {
                return node
            }
            for (index in 0 until node.childCount) {
                node.getChild(index)?.let(queue::addLast)
            }
        }
        return null
    }

    private fun performClick(node: AccessibilityNodeInfo): Boolean {
        var current: AccessibilityNodeInfo? = node
        repeat(5) {
            val candidate = current ?: return false
            if (candidate.isClickable && candidate.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                return true
            }
            current = candidate.parent
        }
        return false
    }

    companion object {
        private const val maxNodes = 700
        private const val shareSheetDelayMs = 850L
        private const val clipboardDelayMs = 650L
        private const val captureTimeoutMs = 4_500L

        @Volatile
        private var instance: LinkCaptureAccessibilityService? = null

        private val browserPackages = setOf(
            "com.android.chrome",
            "com.chrome.beta",
            "com.chrome.dev",
            "com.chrome.canary",
            "com.android.browser",
            "com.brave.browser",
            "com.duckduckgo.mobile.android",
            "com.kiwibrowser.browser",
            "com.mi.globalbrowser",
            "com.miui.browser",
            "com.microsoft.emmx",
            "com.opera.browser",
            "com.opera.mini.native",
            "com.sec.android.app.sbrowser",
            "com.vivaldi.browser",
            "org.mozilla.firefox",
            "org.mozilla.firefox_beta",
            "org.mozilla.fenix",
        )

        private val tiktokPackages = setOf(
            "com.zhiliaoapp.musically",
            "com.zhiliaoapp.musically.go",
            "com.ss.android.ugc.trill",
            "com.ss.android.ugc.aweme",
            "com.ss.android.ugc.tiktok.lite",
        )

        private val addressViewHints = setOf(
            "url_bar",
            "address_bar",
            "location_bar",
            "omnibox",
            "toolbar_url",
            "toolbar_url_view",
        )

        private val shareLabels = setOf("chia sẻ", "share")
        private val copyLinkLabels = setOf(
            "sao chép liên kết",
            "chép liên kết",
            "copy link",
            "copy url",
        )

        private val explicitUrlPattern = Regex(
            """https?://[^\s<>\"'“”]+""",
            RegexOption.IGNORE_CASE,
        )

        fun isServiceEnabled(context: Context): Boolean {
            val expected = "${context.packageName}/${LinkCaptureAccessibilityService::class.java.name}"
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            return enabledServices.split(':').any { TextUtils.equals(it, expected) }
        }

        fun captureCurrentUrl(callback: (CaptureResult) -> Unit) {
            val service = instance
            if (service == null) {
                callback(CaptureResult(error = "Hãy bật quyền Trợ năng cho Linkeep"))
                return
            }
            service.handler.post { service.capture(callback) }
        }

        private fun extractExplicitUrl(value: String): String? {
            val match = explicitUrlPattern.find(value.trim()) ?: return null
            return normalizeUrl(match.value, allowBareDomain = false)
        }

        private fun normalizeUrl(raw: String, allowBareDomain: Boolean): String? {
            var candidate = raw.trim().trimEnd('.', ',', ';', ':', '!', '?', ')', ']', '}')
            if (candidate.isBlank() || candidate.any { it.isWhitespace() }) return null
            if (!candidate.startsWith("http://", true) && !candidate.startsWith("https://", true)) {
                if (!allowBareDomain || !candidate.contains('.')) return null
                candidate = "https://$candidate"
            }
            val uri = Uri.parse(candidate)
            if (uri.scheme !in setOf("http", "https") || uri.host.isNullOrBlank()) return null
            return uri.toString()
        }

        private fun isTikTokUrl(url: String): Boolean {
            val host = Uri.parse(url).host.orEmpty().lowercase()
            return host == "tiktok.com" || host.endsWith(".tiktok.com")
        }
    }
}
