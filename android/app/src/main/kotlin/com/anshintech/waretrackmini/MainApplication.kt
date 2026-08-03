package com.anshintech.waretrackmini

import androidx.camera.camera2.Camera2Config
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraXConfig
import androidx.camera.lifecycle.ProcessCameraProvider
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication(), CameraXConfig.Provider {
    override fun onCreate() {
        super.onCreate()

        try {
            ProcessCameraProvider.configureInstance(createCameraXConfig())
        } catch (_: IllegalStateException) {
            // CameraX was already configured in this process.
        }
    }

    override fun getCameraXConfig(): CameraXConfig {
        return createCameraXConfig()
    }

    private fun createCameraXConfig(): CameraXConfig {
        return CameraXConfig.Builder
            .fromConfig(Camera2Config.defaultConfig())
            .setAvailableCamerasLimiter(CameraSelector.DEFAULT_BACK_CAMERA)
            .build()
    }
}
