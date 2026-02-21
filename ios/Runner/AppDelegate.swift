import UIKit
import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 15.0, *)
public class FocusEngine: NSObject {
    static let shared = FocusEngine()
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermissions":
            requestPermissions(result: result)
        case "startShield":
            if let args = call.arguments as? [String: Any],
               let packages = args["packages"] as? [String],
               let categories = args["categories"] as? [String] {
                startShield(packages: packages, categories: categories, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "stopShield":
            stopShield(result: result)
        case "isShieldActive":
            result(store.shield.applications != nil)
        case "openFamilyActivityPicker":
            result(FlutterError(code: "UNIMPLEMENTED", message: "Bridge implementation required in main UI", details: nil))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestPermissions(result: @escaping FlutterResult) {
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                result(true)
            } catch {
                result(false)
            }
        }
    }
    
    private func startShield(packages: [String], categories: [String], result: FlutterResult) {
        result(nil)
    }
    
    private func stopShield(result: FlutterResult) {
        store.clearAllSettings()
        result(nil)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
        let focusChannel = FlutterMethodChannel(name: "com.ceoos.app/focus",
                                                  binaryMessenger: controller.binaryMessenger)
        
        if #available(iOS 15.0, *) {
            focusChannel.setMethodCallHandler({
              (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                FocusEngine.shared.handle(call, result: result)
            })
        } else {
            focusChannel.setMethodCallHandler({
              (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required", details: nil))
            })
        }
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
