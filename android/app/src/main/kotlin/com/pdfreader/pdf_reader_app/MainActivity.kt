package com.pdfreader.pdf_reader_app

import android.content.Intent
import android.os.Bundle
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pdfreader.pdf_reader_app/pdf_intent"

    companion object {
        private const val TAG = "PdfIntentHandler"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.i(TAG, "[${System.currentTimeMillis()}] MethodCall: ${call.method}")
            when (call.method) {
                "getInitialIntent" -> {
                    android.util.Log.i(TAG, "[${System.currentTimeMillis()}] getInitialIntent called")
                    val filePath = extractFilePathFromIntent(intent)
                    android.util.Log.i(TAG, "[${System.currentTimeMillis()}] getInitialIntent returning: $filePath")
                    if (filePath != null) {
                        result.success(filePath)
                    } else {
                        result.success(null)
                    }
                }
                "verifyFileReady" -> {
                    val filePath = call.argument<String>("path")
                    android.util.Log.i(TAG, "[${System.currentTimeMillis()}] verifyFileReady called for: $filePath")
                    if (filePath == null) {
                        android.util.Log.e(TAG, "[${System.currentTimeMillis()}] No path provided")
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val isReady = verifyFileIsReady(filePath)
                    android.util.Log.i(TAG, "[${System.currentTimeMillis()}] File ready result: $isReady")
                    result.success(isReady)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val filePath = extractFilePathFromIntent(intent)
        if (filePath != null) {
            flutterEngine?.let { engine ->
                MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onNewPdfIntent", filePath)
                android.util.Log.i(TAG, "New intent sent: $filePath")
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
        var targetFile: File? = null
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: run {
                android.util.Log.e(TAG, "Failed to open input stream")
                return null
            }

            val originalFileName = getFileNameFromUri(uri)
            var file = File(filesDir, originalFileName)

            if (file.exists()) {
                val suffix = System.currentTimeMillis().toString(16).take(8)
                val baseName = originalFileName.substringBeforeLast('.')
                val extension = originalFileName.substringAfterLast('.', "pdf")
                file = File(filesDir, "${baseName}_$suffix.$extension")
            }

            targetFile = file
            inputStream.use { input ->
                java.io.FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                    output.fd.sync()
                }
            }

            if (!targetFile.exists() || targetFile.length() == 0L) {
                android.util.Log.e(TAG, "File is empty or doesn't exist: ${targetFile.absolutePath}")
                targetFile.delete()
                return null
            }

            try {
                java.io.RandomAccessFile(targetFile, "r").use { testRead ->
                    if (testRead.read() == -1) {
                        android.util.Log.e(TAG, "File exists but not readable: ${targetFile.absolutePath}")
                        targetFile.delete()
                        return null
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Failed read verification: ${e.message}")
                targetFile.delete()
                return null
            }

            val fileSize = targetFile.length()
            android.util.Log.i(TAG, "PDF copied: ${targetFile.name} ($fileSize bytes)")
            targetFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to copy PDF: ${e.message}")
            try {
                targetFile?.delete()
            } catch (cleanupException: Exception) {
                android.util.Log.w(TAG, "Failed to clean up partial file")
            }
            null
        }
    }

    private fun getFileNameFromUri(uri: android.net.Uri): String {
        android.util.Log.i(TAG, "[${System.currentTimeMillis()}] getFileNameFromUri: $uri")
        // Try to get display name from ContentResolver
        val fileName = try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) cursor.getString(nameIndex) else null
                } else null
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Failed to get display name: ${e.message}")
            null
        }

        // If display name not found, extract from URI path
        if (fileName != null) return fileName

        val path = uri.path
        val fileNameFromPath = path?.substringAfterLast('/')
        return fileNameFromPath ?: "temp_${System.currentTimeMillis()}.pdf"
    }

    /**
     * Verify that a file is ready to be read.
     * This is called from Flutter to ensure the file is actually accessible
     * before attempting to process it.
     */
    private fun verifyFileIsReady(filePath: String): Boolean {
        val file = File(filePath)

        if (!file.exists()) {
            android.util.Log.w(TAG, "verifyFileIsReady: File doesn't exist: $filePath")
            return false
        }

        if (file.length() == 0L) {
            android.util.Log.w(TAG, "verifyFileIsReady: File is empty: $filePath")
            return false
        }

        return try {
            java.io.RandomAccessFile(file, "r").use { raf ->
                raf.channel.force(true)
                val firstByte = raf.read()
                if (firstByte != -1) {
                    android.util.Log.i(TAG, "verifyFileIsReady: OK - $filePath")
                } else {
                    android.util.Log.w(TAG, "verifyFileIsReady: EOF - $filePath")
                }
                firstByte != -1
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "verifyFileIsReady: Error - ${e.message}")
            false
        }
    }
}
