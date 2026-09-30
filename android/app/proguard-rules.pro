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

# ── Google Play Core (deferred components / split installs) ───────────────────
# Flutter references these classes for Play Store dynamic delivery, but they are
# not present when building outside the Play Store pipeline. Suppress R8 errors.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ── ImageKit Android SDK & Dependencies ───────────────────────────────────────
# R8 / ProGuard in release builds strips models/reflection needed by ImageKit (Gson/Retrofit).
# Without these rules, the app crashes immediately when uploading an image on release builds.
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-dontwarn com.imagekit.android.**
-keep class com.imagekit.android.** { *; }
-keep interface com.imagekit.android.** { *; }
-keep class com.imagekit.android.entity.** { *; }
-keepclassmembers class com.imagekit.android.entity.** { *; }

# ── Keep Channel Managers & Native Callbacks ──────────────────────────────────
-keep class com.phamtruong.keeplink.channel.** { *; }
-keepclassmembers class com.phamtruong.keeplink.channel.** { *; }

# ── Gson / Retrofit (used by ImageKit SDK) ────────────────────────────────────
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# ── Suppress warnings from library internals we don't control ─────────────────
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
