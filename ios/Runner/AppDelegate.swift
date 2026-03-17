import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Holds a file path when the app is opened cold via a .yisj file.
  static var pendingSharedFilePath: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Capture cold-launch URL (app was not running when file was tapped).
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL,
       url.pathExtension == "yisj" {
      AppDelegate.pendingSharedFilePath = Self.copyToTemp(url: url)
    }

    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Register the MethodChannel after the Flutter engine is ready.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yesispend/file_handler",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "getPendingFile" {
          result(AppDelegate.pendingSharedFilePath)
          AppDelegate.pendingSharedFilePath = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }

  // Called when the app is already running and the user taps a .yisj file.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.pathExtension == "yisj" else {
      return super.application(app, open: url, options: options)
    }
    let path = Self.copyToTemp(url: url)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yesispend/file_handler",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("handleFile", arguments: path)
    } else {
      AppDelegate.pendingSharedFilePath = path
    }
    return true
  }

  private static func copyToTemp(url: URL) -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let destURL = tempDir.appendingPathComponent("yisj_\(url.lastPathComponent)")
    try? FileManager.default.removeItem(at: destURL)
    try? FileManager.default.copyItem(at: url, to: destURL)
    return destURL.path
  }
}
