import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let videoQualityChannelName = "com.roketota.demo_roketota_app/video_quality"
  private let videoFpsChannelName = "com.roketota.demo_roketota_app/video_fps"
  private let defaultMaxFps = 30

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    registerVideoQualityChannel(messenger: messenger)
    registerVideoFpsChannel(messenger: messenger)
  }

  private func registerVideoQualityChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: videoQualityChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getVideoQualityRange":
        result(self?.resolveVideoQualityRange())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerVideoFpsChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: videoFpsChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getMaxSupportedFps":
        result(self?.resolveMaxSupportedFps())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func resolveVideoQualityRange() -> [String: String] {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    else {
      return defaultRange()
    }

    var supported: [String] = []

    if device.supportsSessionPreset(.hd1280x720) {
      supported.append("hd")
    }
    if device.supportsSessionPreset(.hd1920x1080) {
      supported.append("fhd")
    }
    if device.supportsSessionPreset(.hd4K3840x2160) {
      supported.append("uhd")
    }

    if supported.isEmpty {
      return defaultRange()
    }

    return [
      "min": supported.first!,
      "max": supported.last!,
    ]
  }

  private func resolveMaxSupportedFps() -> Int {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    else {
      return defaultMaxFps
    }

    var maxFps = 0.0
    for format in device.formats {
      for range in format.videoSupportedFrameRateRanges {
        maxFps = max(maxFps, range.maxFrameRate)
      }
    }

    if maxFps <= 0 {
      return defaultMaxFps
    }

    return Int(maxFps.rounded(.down))
  }

  private func defaultRange() -> [String: String] {
    return [
      "min": "hd",
      "max": "uhd",
    ]
  }
}
