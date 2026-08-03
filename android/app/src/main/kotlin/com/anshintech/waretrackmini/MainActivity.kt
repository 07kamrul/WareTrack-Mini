package com.anshintech.waretrackmini

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val downloadsChannelName = "com.anshintech.waretrackmini/downloads"
    private val packageInfoChannelName = "com.anshintech.waretrackmini/package_info"
    private val excelMimeType =
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, packageInfoChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstallTimes" -> {
                        try {
                            val info = packageManager.getPackageInfo(packageName, 0)
                            result.success(
                                mapOf(
                                    "firstInstallTime" to info.firstInstallTime,
                                    "lastUpdateTime" to info.lastUpdateTime,
                                ),
                            )
                        } catch (e: PackageManager.NameNotFoundException) {
                            result.error("unavailable", "Package info not found.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveExcelToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        val mimeType = call.argument<String>("mimeType") ?: excelMimeType

                        if (fileName.isNullOrBlank() || bytes == null) {
                            result.error("invalid_args", "Invalid Excel download data.", null)
                            return@setMethodCallHandler
                        }

                        try {
                            result.success(saveExcelToDownloads(fileName, bytes, mimeType))
                        } catch (exception: Exception) {
                            result.error(
                                "save_failed",
                                exception.message ?: "Unable to save Excel file.",
                                null,
                            )
                        }
                    }

                    "openExcelFile" -> {
                        val filePath = call.argument<String>("filePath")
                        val contentUri = call.argument<String>("contentUri")
                        val mimeType = call.argument<String>("mimeType") ?: excelMimeType

                        try {
                            openExcelFile(filePath, contentUri, mimeType)
                            result.success(null)
                        } catch (exception: ActivityNotFoundException) {
                            result.error(
                                "no_app_found",
                                "No spreadsheet app is installed.",
                                null,
                            )
                        } catch (exception: Exception) {
                            result.error(
                                "open_failed",
                                exception.message ?: "Unable to open Excel file.",
                                null,
                            )
                        }
                    }

                    "shareExcelFile" -> {
                        val filePath = call.argument<String>("filePath")
                        val contentUri = call.argument<String>("contentUri")
                        val fileName = call.argument<String>("fileName")
                        val emailAddress = call.argument<String>("emailAddress")
                        val mimeType = call.argument<String>("mimeType") ?: excelMimeType
                        val subject = call.argument<String>("subject").orEmpty()
                        val body = call.argument<String>("body").orEmpty()

                        try {
                            shareExcelFile(
                                filePath,
                                contentUri,
                                fileName,
                                emailAddress,
                                mimeType,
                                subject,
                                body,
                            )
                            result.success(null)
                        } catch (exception: ActivityNotFoundException) {
                            result.error(
                                "no_app_found",
                                "No app is available to share the Excel file.",
                                null,
                            )
                        } catch (exception: Exception) {
                            result.error(
                                "share_failed",
                                exception.message ?: "Unable to share Excel file.",
                                null,
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun saveExcelToDownloads(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
    ): Map<String, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: error("Unable to create Excel file in Downloads.")

            try {
                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: error("Unable to write Excel file in Downloads.")

                val completedValues = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                resolver.update(uri, completedValues, null, null)
                val uploadFile = File(cacheDir, fileName)
                uploadFile.writeBytes(bytes)

                return mapOf(
                    "filePath" to uploadFile.absolutePath,
                    "contentUri" to uri.toString(),
                )
            } catch (exception: Exception) {
                resolver.delete(uri, null, null)
                throw exception
            }
        }

        val downloadsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }

        val file = File(downloadsDir, fileName)
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(file.absolutePath),
            arrayOf(mimeType),
            null,
        )

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )

        return mapOf(
            "filePath" to file.absolutePath,
            "contentUri" to uri.toString(),
        )
    }

    private fun openExcelFile(
        filePath: String?,
        contentUri: String?,
        mimeType: String,
    ) {
        val uri = when {
            !contentUri.isNullOrBlank() -> Uri.parse(contentUri)
            !filePath.isNullOrBlank() -> FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                File(filePath),
            )
            else -> error("Excel file path is missing.")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, null))
    }

    private fun shareExcelFile(
        filePath: String?,
        contentUri: String?,
        fileName: String?,
        emailAddress: String?,
        mimeType: String,
        subject: String,
        body: String,
    ) {
        require(!emailAddress.isNullOrBlank()) { "Email address is missing." }
        val normalizedEmailAddress = emailAddress.trim()

        val uri = when {
            !contentUri.isNullOrBlank() -> Uri.parse(contentUri)
            !filePath.isNullOrBlank() -> FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                File(filePath),
            )
            else -> error("Excel file path is missing.")
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_EMAIL, arrayOf(normalizedEmailAddress))
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri(fileName ?: "attachment", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val emailIntents = packageManager.queryIntentActivities(
            Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")),
            PackageManager.MATCH_DEFAULT_ONLY,
        ).map { resolveInfo ->
            Intent(intent).apply {
                setPackage(resolveInfo.activityInfo.packageName)
            }
        }.distinctBy { emailIntent ->
            emailIntent.`package`
        }

        if (emailIntents.isEmpty()) {
            throw ActivityNotFoundException("No email app is installed.")
        }

        val chooser = Intent.createChooser(emailIntents.first(), null).apply {
            if (emailIntents.size > 1) {
                putExtra(Intent.EXTRA_INITIAL_INTENTS, emailIntents.drop(1).toTypedArray())
            }
        }
        startActivity(chooser)
    }
}
