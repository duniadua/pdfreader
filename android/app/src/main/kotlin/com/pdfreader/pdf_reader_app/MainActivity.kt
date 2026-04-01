package com.pdfreader.pdf_reader_app

import android.content.Intent
import android.os.Bundle
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pdfreader.pdf_reader_app/pdf_intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialIntent") {
                val intent = intent
                val filePath = extractFilePathFromIntent(intent)
                if (filePath != null) {
                    result.success(filePath)
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Notify Flutter about the new intent
        val filePath = extractFilePathFromIntent(intent)
        if (filePath != null) {
            flutterEngine?.let { engine ->
                MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onNewPdfIntent", filePath)
            }
        }
    }

    private fun extractFilePathFromIntent(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) {
            return null
        }

        val data = intent.data ?: return null

        return when (data.scheme) {
            "content" -> {
                // Handle content:// URIs (from modern file managers)
                copyContentUriToCache(data)
            }
            "file" -> {
                // Handle file:// URIs (from older file managers)
                data.path
            }
            else -> null
        }
    }

    private fun copyContentUriToCache(uri: android.net.Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "temp_${System.currentTimeMillis()}.pdf")

            inputStream.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            tempFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to copy content URI to cache", e)
            null
        }
    }
}
