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
        android.util.Log.d("MainActivity", "🔧 configureFlutterEngine called")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "📨 Method call received: ${call.method}")
            if (call.method == "getInitialIntent") {
                val intent = intent
                android.util.Log.d("MainActivity", "🔍 Getting initial intent: $intent")
                val filePath = extractFilePathFromIntent(intent)
                android.util.Log.d("MainActivity", "📄 Extracted file path: $filePath")
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
        android.util.Log.d("MainActivity", "🎯 onNewIntent called with: $intent")
        setIntent(intent)

        // Notify Flutter about the new intent
        val filePath = extractFilePathFromIntent(intent)
        android.util.Log.d("MainActivity", "📁 Extracted file path from new intent: $filePath")
        if (filePath != null) {
            flutterEngine?.let { engine ->
                android.util.Log.d("MainActivity", "📲 Sending onNewPdfIntent to Flutter: $filePath")
                MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onNewPdfIntent", filePath)
            }
        }
    }

    private fun extractFilePathFromIntent(intent: Intent?): String? {
        android.util.Log.d("MainActivity", "🔍 extractFilePathFromIntent called")
        if (intent == null) {
            android.util.Log.w("MainActivity", "❌ Intent is null")
            return null
        }
        android.util.Log.d("MainActivity", "📋 Intent action: ${intent.action}")
        if (intent.action != Intent.ACTION_VIEW) {
            android.util.Log.w("MainActivity", "❌ Intent action is not ACTION_VIEW")
            return null
        }

        val data = intent.data
        android.util.Log.d("MainActivity", "📎 Intent data: $data")
        if (data == null) {
            android.util.Log.w("MainActivity", "❌ Intent data is null")
            return null
        }

        android.util.Log.d("MainActivity", "🔗 URI scheme: ${data.scheme}")
        return when (data.scheme) {
            "content" -> {
                // Handle content:// URIs (from modern file managers)
                android.util.Log.d("MainActivity", "✅ Handling content:// URI")
                copyContentUriToCache(data)
            }
            "file" -> {
                // Handle file:// URIs (from older file managers)
                android.util.Log.d("MainActivity", "✅ Handling file:// URI")
                data.path
            }
            else -> {
                android.util.Log.w("MainActivity", "❌ Unknown URI scheme: ${data.scheme}")
                null
            }
        }
    }

    private fun copyContentUriToCache(uri: android.net.Uri): String? {
        android.util.Log.d("MainActivity", "📥 copyContentUriToCache called with URI: $uri")
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream == null) {
                android.util.Log.e("MainActivity", "❌ Failed to open input stream")
                return null
            }
            android.util.Log.d("MainActivity", "✅ Input stream opened successfully")

            // Extract original filename from URI
            val originalFileName = getFileNameFromUri(uri)
            android.util.Log.d("MainActivity", "📄 Original filename: $originalFileName")

            // Create temp file with original name
            val tempFile = File(cacheDir, originalFileName)
            android.util.Log.d("MainActivity", "📝 Creating temp file: ${tempFile.absolutePath}")

            inputStream.use { input ->
                tempFile.outputStream().use { output ->
                    val bytesCopied = input.copyTo(output)
                    android.util.Log.d("MainActivity", "📊 Copied $bytesCopied bytes")
                }
            }

            android.util.Log.d("MainActivity", "✅ File copied successfully to: ${tempFile.absolutePath}")
            tempFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Failed to copy content URI to cache", e)
            null
        }
    }

    private fun getFileNameFromUri(uri: android.net.Uri): String {
        // Try to get display name from ContentResolver
        val fileName = try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        cursor.getString(nameIndex)
                    } else null
                } else null
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Failed to get display name from URI", e)
            null
        }

        // If display name not found, extract from URI path
        if (fileName != null) {
            android.util.Log.d("MainActivity", "✅ Got display name: $fileName")
            return fileName
        }

        // Extract filename from URI path as fallback
        val path = uri.path
        val fileNameFromPath = path?.substringAfterLast('/')
        android.util.Log.d("MainActivity", "📝 Extracted filename from path: $fileNameFromPath")
        return fileNameFromPath ?: "temp_${System.currentTimeMillis()}.pdf"
    }
}
