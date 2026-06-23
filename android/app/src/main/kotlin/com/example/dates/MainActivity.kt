package com.example.dates

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val uploadPickerChannel = "dates/upload_picker"
    private val pickAudioRequest = 7301
    private var pendingAudioResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, uploadPickerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAudio" -> pickAudio(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickAudio(result: MethodChannel.Result) {
        if (pendingAudioResult != null) {
            result.error("PICKER_ACTIVE", "Ya hay un selector de audio abierto.", null)
            return
        }

        pendingAudioResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
        }
        startActivityForResult(
            Intent.createChooser(intent, "Selecciona un audio"),
            pickAudioRequest
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickAudioRequest) return

        val result = pendingAudioResult ?: return
        pendingAudioResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val uri = data.data!!
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null) {
                result.error("READ_FAILED", "No se pudo leer el archivo de audio.", null)
                return
            }
            result.success(
                mapOf(
                    "name" to getDisplayName(uri),
                    "bytes" to bytes
                )
            )
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
        }
    }

    private fun getDisplayName(uri: Uri): String {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameIndex >= 0 && cursor.moveToFirst()) {
                return cursor.getString(nameIndex)
            }
        }
        return "audio.mp3"
    }
}
