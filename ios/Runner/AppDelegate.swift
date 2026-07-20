import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let videoQualityChannelName = "com.roketota.demo_roketota_app/video_quality"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
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

  private func defaultRange() -> [String: String] {
    return [
      "min": "hd",
      "max": "uhd",
    ]
  }
}
