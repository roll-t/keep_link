package io.flutter.plugins.bubble

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.phamtruong.keeplink.R

object NotificationHelper {

    private const val CHANNEL_ID = "bubble_channel"

    fun createNotification(context: Context): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bubble Service",
                NotificationManager.IMPORTANCE_LOW
            )
            (context.getSystemService(NotificationManager::class.java))?.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Bubble running")
            .setContentText("Floating bubble is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }
}
