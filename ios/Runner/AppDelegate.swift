import UIKit
import Flutter
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@available(iOS 15.0, *)
public class FocusEngine: NSObject {
    public static let shared = FocusEngine()
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    
    // Store selection for persistence during session
    private var selection = FamilyActivitySelection()
    
    private func requestPermissions(result: @escaping FlutterResult) {
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                result(true)
            } catch {
                print("Authorization failed: \(error)")
                result(false)
            }
        }
    }
    
    private func startShield(result: FlutterResult) {
        // Apply shield from current selection
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        result(nil)
    }
    
    private func stopShield(result: FlutterResult) {
        store.clearAllSettings()
        result(nil)
    }
    
    // We'll need a way to decode selection from JSON string
    private func applySelectionFrom(encoded: String?) {
        guard let data = encoded?.data(using: .utf8) else { return }
        do {
            let decoder = JSONDecoder()
            let decodedSelection = try decoder.decode(FamilyActivitySelection.self, from: data)
            self.selection = decodedSelection
            
            store.shield.applications = decodedSelection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(decodedSelection.categoryTokens)
            store.shield.webDomains = decodedSelection.webDomainTokens
        } catch {
            print("Failed to decode selection: \(error)")
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        
        switch call.method {
        case "requestPermissions":
            requestPermissions(result: result)
        case "isAuthorized":
            result(center.authorizationStatus == .approved)
        case "startShield":
            if let packages = args?["packages"] as? [String], !packages.isEmpty {
                // On iOS, the first 'package' contains the JSON encoded selection
                applySelectionFrom(encoded: packages.first)
            } else {
                startShield(result: result)
            }
            result(nil)
        case "stopShield":
            stopShield(result: result)
        case "isShieldActive":
            result(store.shield.applications != nil || store.shield.applicationCategories != nil)
        case "openFamilyActivityPicker":
            presentFamilyActivityPicker(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func presentFamilyActivityPicker(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
                result(FlutterError(code: "NO_ROOT_VC", message: "No root view controller", details: nil))
                return
            }

            let pickerWrapper = PickerWrapperView(selection: self.selection) { newSelection in
                self.selection = newSelection
                
                // Encode the selection to JSON so Flutter can persist it
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(newSelection)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        result([jsonString])
                    } else {
                        result(FlutterError(code: "ENCODE_ERROR", message: "Failed to stringify JSON", details: nil))
                    }
                } catch {
                    result(FlutterError(code: "ENCODE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
            
            let hostingController = UIHostingController(rootView: pickerWrapper)
            rootVC.present(hostingController, animated: true)
        }
    }
}

@available(iOS 15.0, *)
struct PickerWrapperView: View {
    @State var selection: FamilyActivitySelection
    var onComplete: (FamilyActivitySelection) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                FamilyActivityPicker(selection: $selection)
            }
            .navigationTitle("Select Distractions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(selection)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    print("CEO OS Native Launching...")
    GeneratedPluginRegistrant.register(with: self)
    
    // Robust registration using the plugin registrar
    let registrar = self.registrar(forPlugin: "FocusEngine")!
    let focusChannel = FlutterMethodChannel(name: "com.ceoos.app/focus",
                                              binaryMessenger: registrar.messenger())
    
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
