# ── Flutter / Dart ────────────────────────────────────────────────────────────
# Flutter wraps native classes; keep them all.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── WebView / JavaScript Interface ────────────────────────────────────────────
# Protect any class that exposes @JavascriptInterface methods so R8 does not
# rename or strip them (calling JS → Java would silently break otherwise).
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebViewClient / WebChromeClient subclass overrides intact.
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# ── flutter_inappwebview ──────────────────────────────────────────────────────
-keep class com.phlutter.** { *; }

# ── OkHttp (used internally by some plugins) ──────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# ── Suppress warnings from library internals we don't control ─────────────────
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
