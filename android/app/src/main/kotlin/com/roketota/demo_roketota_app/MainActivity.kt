package com.roketota.demo_roketota_app

import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.CamcorderProfile
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIDEO_QUALITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                GET_VIDEO_QUALITY_RANGE -> {
                    result.success(resolveVideoQualityRange())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun resolveVideoQualityRange(): Map<String, String> {
        val cameraId = defaultBackCameraId() ?: return defaultRange()
        val supported = mutableListOf<String>()

        if (supportsQuality(cameraId, CamcorderProfile.QUALITY_720P)) {
            supported.add(QUALITY_HD)
        }
        if (supportsQuality(cameraId, CamcorderProfile.QUALITY_1080P)) {
            supported.add(QUALITY_FHD)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
            supportsQuality(cameraId, CamcorderProfile.QUALITY_2160P)
        ) {
            supported.add(QUALITY_UHD)
        }

        if (supported.isEmpty()) {
            return defaultRange()
        }

        return mapOf(
            "min" to supported.first(),
            "max" to supported.last(),
        )
    }

    private fun defaultBackCameraId(): String? {
        val cameraManager = getSystemService(CAMERA_SERVICE) as? CameraManager
            ?: return null

        return cameraManager.cameraIdList.firstOrNull { cameraId ->
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            characteristics.get(CameraCharacteristics.LENS_FACING) ==
                CameraCharacteristics.LENS_FACING_BACK
        }
    }

    private fun supportsQuality(cameraId: String, quality: Int): Boolean {
        val cameraIndex = cameraId.toIntOrNull()
        if (cameraIndex != null && CamcorderProfile.hasProfile(cameraIndex, quality)) {
            return true
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            CamcorderProfile.getAll(cameraId, quality) != null
        } else {
            false
        }
    }

    private fun defaultRange(): Map<String, String> {
        return mapOf(
            "min" to QUALITY_HD,
            "max" to QUALITY_UHD,
        )
    }

    companion object {
        private const val VIDEO_QUALITY_CHANNEL =
            "com.roketota.demo_roketota_app/video_quality"
        private const val GET_VIDEO_QUALITY_RANGE = "getVideoQualityRange"
        private const val QUALITY_HD = "hd"
        private const val QUALITY_FHD = "fhd"
        private const val QUALITY_UHD = "uhd"
    }
}
