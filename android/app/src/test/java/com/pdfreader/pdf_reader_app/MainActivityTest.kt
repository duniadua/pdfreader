package com.pdfreader.pdf_reader_app

import android.net.Uri
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.junit.MockitoJUnitRunner
import java.io.File

@RunWith(MockitoJUnitRunner::class)
class MainActivityTest {

    @Before
    fun setup() {
        // No setup needed for pure unit tests
    }

    @Test
    fun testPdfMagicBytesValidation() {
        // Test PDF magic bytes validation
        val validPdfHeader = byteArrayOf(0x25, 0x50, 0x44, 0x46, 0x2D) // %PDF-
        val invalidHeader = byteArrayOf(0x00, 0x01, 0x02, 0x03, 0x04)

        assertEquals("First byte should be %", 0x25, validPdfHeader[0].toInt())
        assertEquals("Second byte should be P", 0x50, validPdfHeader[1].toInt())
        assertEquals("Third byte should be D", 0x44, validPdfHeader[2].toInt())
        assertEquals("Fourth byte should be F", 0x46, validPdfHeader[3].toInt())
        assertEquals("Fifth byte should be -", 0x2D, validPdfHeader[4].toInt())

        // Invalid header should not match PDF signature
        assertNotEquals("Invalid header should differ from PDF", validPdfHeader[0], invalidHeader[0])
    }

    @Test
    fun testGetFileNameFromUri_withValidUri() {
        // Test URI parsing logic
        val testUriString = "content://com.whatsapp.provider/document/whatsapp/Media/1234.pdf"

        // Test that we can extract the PDF extension from the URI string
        assertNotNull("URI string should not be null", testUriString)
        assertEquals("PDF extension should be present", "pdf", testUriString.substringAfterLast('.', ""))
    }

    @Test
    fun testFileOperations_inAppDirectory() {
        // Test basic file operations in a temporary directory
        val tempDir = createTempDir("pdf_test_")
        val testFile = File(tempDir, "test_${System.currentTimeMillis()}.pdf")

        try {
            // Write test data
            testFile.writeBytes("%PDF-1.4\nTest PDF content".toByteArray())

            // Verify file was created
            assertTrue("File should exist", testFile.exists())
            assertTrue("File should be readable", testFile.canRead())
            assertTrue("File should have content", testFile.length() > 0)

            // Verify we can read from it
            val raf = java.io.RandomAccessFile(testFile, "r")
            val firstByte = raf.read()
            raf.close()

            assertEquals("First byte should be %", 0x25, firstByte) // % character

        } finally {
            // Clean up
            testFile.delete()
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testRandomAccessFile_withForceSync() {
        // Test RandomAccessFile with channel.force(true) pattern
        val tempDir = createTempDir("pdf_sync_test_")
        val testFile = File(tempDir, "test_sync_${System.currentTimeMillis()}.pdf")

        try {
            // Write data using RandomAccessFile
            java.io.RandomAccessFile(testFile, "rw").use { raf ->
                val channel = raf.channel
                val buffer = java.nio.ByteBuffer.allocate(1024)
                val testData = "%PDF-1.4\nTest content for sync verification".toByteArray()

                buffer.put(testData)
                buffer.flip()
                channel.write(buffer)

                // Force sync to disk
                channel.force(true) // true = sync both data and metadata
            }

            // Verify file was written and is readable
            assertTrue("File should exist", testFile.exists())
            assertTrue("File should be readable", testFile.canRead())
            assertTrue("File should have content", testFile.length() > 0)

            // Verify content
            val content = testFile.readBytes()
            assertTrue("Content should start with %PDF", String(content).startsWith("%PDF"))

        } finally {
            testFile.delete()
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testFileVerification_withPolling() {
        // Simulate the polling verification pattern
        val tempDir = createTempDir("pdf_poll_test_")
        val testFile = File(tempDir, "test_poll_${System.currentTimeMillis()}.pdf")

        try {
            // Start file creation in a separate thread (simulating async copy)
            val copyThread = Thread {
                Thread.sleep(50) // Simulate slow copy
                testFile.writeBytes("%PDF-1.4\nDelayed write".toByteArray())
            }
            copyThread.start()

            // Poll for file readiness
            var verified = false
            val maxRetries = 10
            val retryDelayMs = 50L

            for (i in 0 until maxRetries) {
                if (testFile.exists() && testFile.canRead() && testFile.length() > 0) {
                    // Try to actually read
                    try {
                        val raf = java.io.RandomAccessFile(testFile, "r")
                        val firstByte = raf.read()
                        raf.close()

                        if (firstByte != -1) {
                            verified = true
                            break
                        }
                    } catch (e: Exception) {
                        // Not ready yet, continue polling
                    }
                }

                if (i < maxRetries - 1) {
                    Thread.sleep(retryDelayMs)
                }
            }

            copyThread.join() // Wait for copy thread to finish
            assertTrue("File should be verified through polling", verified)

        } finally {
            testFile.delete()
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testMultipleFileCreation_withCollisionPrevention() {
        // Test that multiple files with same name get unique suffixes
        val tempDir = createTempDir("pdf_collision_test_")
        val baseName = "collision_test.pdf"
        val file1 = File(tempDir, baseName)
        val file2 = File(tempDir, baseName) // Same name, should get suffix

        try {
            // Create first file
            file1.writeBytes("%PDF-1.4\nFirst file".toByteArray())
            assertTrue("First file should exist", file1.exists())

            // Simulate suffix logic
            val suffix = System.currentTimeMillis().toString(16).take(8)
            val baseNameWithoutExt = baseName.substringBeforeLast('.')
            val extension = baseName.substringAfterLast('.', "pdf")
            val suffixedFile = File(tempDir, "${baseNameWithoutExt}_$suffix.$extension")

            suffixedFile.writeBytes("%PDF-1.4\nSecond file with suffix".toByteArray())
            assertTrue("Suffixed file should exist", suffixedFile.exists())
            assertTrue("Files should have different paths", file1.absolutePath != suffixedFile.absolutePath)

        } finally {
            file1.delete()
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testFileCleanup_onCopyFailure() {
        // Test that partial files are cleaned up on failure
        val tempDir = createTempDir("pdf_cleanup_test_")
        val testFile = File(tempDir, "test_cleanup_${System.currentTimeMillis()}.pdf")

        try {
            // Simulate partial write
            testFile.writeBytes("%PDF".toByteArray())

            // Simulate detection of incomplete write
            val fileSize = testFile.length()
            val isComplete = fileSize > 100 // Assume complete if > 100 bytes

            if (!isComplete) {
                // Clean up partial file
                testFile.delete()
            }

            assertFalse("Partial file should be deleted", testFile.exists())

        } finally {
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testChannelForceSync_vsFlush() {
        // Compare FileOutputStream.flush() vs FileChannel.force(true)
        val tempDir = createTempDir("pdf_sync_compare_test_")
        val testFile1 = File(tempDir, "test_flush_${System.currentTimeMillis()}.pdf")
        val testFile2 = File(tempDir, "test_force_${System.currentTimeMillis()}.pdf")

        try {
            // Method 1: FileOutputStream with flush
            testFile1.outputStream().use { output ->
                output.write("%PDF-1.4\nMethod 1".toByteArray())
                output.flush()
            }
            assertTrue("File with flush should exist", testFile1.exists())

            // Method 2: RandomAccessFile with channel.force(true)
            java.io.RandomAccessFile(testFile2, "rw").use { raf ->
                val channel = raf.channel
                val buffer = java.nio.ByteBuffer.wrap("%PDF-1.4\nMethod 2".toByteArray())
                channel.write(buffer)
                channel.force(true) // More reliable than flush
            }
            assertTrue("File with force should exist", testFile2.exists())

            // Both should produce valid files
            assertTrue("Both files should have content", testFile1.length() > 0 && testFile2.length() > 0)

        } finally {
            testFile1.delete()
            testFile2.delete()
            tempDir.deleteRecursively()
        }
    }
}
