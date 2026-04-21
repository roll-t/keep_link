package com.phamtruong.keeplink.channel

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import com.imagekit.android.ImageKit
import com.imagekit.android.ImageKitCallback
import com.imagekit.android.entity.TransformationPosition
import com.imagekit.android.entity.UploadError
import com.imagekit.android.entity.UploadResponse
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

object ImageKitChannel {
    const val CHANNEL_NAME = "keep_link/imagekit"
    private const val PUBLIC_KEY = "public_TAtkny+86bT3iq13No+qnnm3Cl8="
    private const val PRIVATE_KEY = "private_3wRsKZEHcqUvAcniExFlKTHRMHc="
    private const val URL_ENDPOINT = "https://ik.imagekit.io/lcr78qp6g"

    fun setup(context: Context, messenger: BinaryMessenger) {
        try {
            ImageKit.getInstance()
        } catch (e: Exception) {
            ImageKit.init(
                context = context.applicationContext,
                publicKey = PUBLIC_KEY,
                urlEndpoint = URL_ENDPOINT,
                transformationPosition = TransformationPosition.PATH
            )
        }

        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "uploadFile" -> handleUpload(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleUpload(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
            ?: return result.error("INVALID_ARGS", "filePath is required", null)
        val fileName = call.argument<String>("fileName")
            ?: "${System.currentTimeMillis()}.jpg"
        val folder = call.argument<String>("folder") ?: "/avatars"

        val file = File(filePath)
        if (!file.exists()) {
            return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
        }

        val token = generateJWT(fileName, folder)
        val mainHandler = Handler(Looper.getMainLooper())

        ImageKit.getInstance().uploader().upload(
            file = file,
            token = token,
            fileName = fileName,
            useUniqueFileName = true,
            folder = folder,
            imageKitCallback = object : ImageKitCallback {
                override fun onSuccess(uploadResponse: UploadResponse) {
                    mainHandler.post { result.success(uploadResponse.url) }
                }
                override fun onError(uploadError: UploadError) {
                    mainHandler.post {
                        result.error("UPLOAD_ERROR", uploadError.message, null)
                    }
                }
            }
        )
    }

    private fun generateJWT(fileName: String, folder: String): String {
        val now = System.currentTimeMillis() / 1000
        val exp = now + 60

        val headerJson = """{"alg":"HS256","typ":"JWT","kid":"$PUBLIC_KEY"}"""
        val payloadJson = """{"fileName":"$fileName","useUniqueFileName":"true","folder":"$folder","iat":$now,"exp":$exp}"""

        val headerEncoded = Base64.encodeToString(
            headerJson.toByteArray(Charsets.UTF_8),
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
        val payloadEncoded = Base64.encodeToString(
            payloadJson.toByteArray(Charsets.UTF_8),
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )

        val signingInput = "$headerEncoded.$payloadEncoded"
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(PRIVATE_KEY.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        val signature = Base64.encodeToString(
            mac.doFinal(signingInput.toByteArray(Charsets.UTF_8)),
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )

        return "$signingInput.$signature"
    }
}
