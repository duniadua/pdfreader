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
            "content" -> copyContentUriToInternal(data)
            "file" -> data.path
            else -> null
        }
    }

    private fun copyContentUriToInternal(uri: android.net.Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null

            // Extract original filename from URI
            val originalFileName = getFileNameFromUri(uri)
            var targetFile = File(filesDir, originalFileName)

            // Prevent overwrite: append unique suffix if file already exists
            if (targetFile.exists()) {
                val suffix = System.currentTimeMillis().toString(16).take(8)
                val baseName = originalFileName.substringBeforeLast('.')
                val extension = originalFileName.substringAfterLast('.', "pdf")
                targetFile = File(filesDir, "${baseName}_$suffix.$extension")
            }

            android.util.Log.i("MainActivity", "Copying PDF to internal storage: ${targetFile.name}")

            inputStream.use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            android.util.Log.i("MainActivity", "PDF copied successfully: ${targetFile.absolutePath}")
            targetFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to copy PDF from URI", e)
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
            return fileName
        }

        // Extract filename from URI path as fallback
        val path = uri.path
        val fileNameFromPath = path?.substringAfterLast('/')
        return fileNameFromPath ?: "temp_${System.currentTimeMillis()}.pdf"
    }
}
