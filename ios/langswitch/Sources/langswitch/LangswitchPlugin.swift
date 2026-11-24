import Flutter
import UIKit

/// Provides per-app language switching via the platform channel `dev.langswitch/native`.
public class LangswitchPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.langswitch/native",
            binaryMessenger: registrar.messenger()
        )
        let instance = LangswitchPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAppLocale":
            result(getAppLocale())
        case "setAppLocale":
            // iOS applies the per-app locale through CFBundleLocalizations + system Settings.
            // Programmatic override is not available; this is a no-op.
            result(nil)
        case "isSystemSettingSupported":
            result(true)
        case "openSystemLanguageSettings":
            openSystemLanguageSettings(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getAppLocale() -> String? {
        guard let preferred = Bundle.main.preferredLocalizations.first else {
            return nil
        }
        return preferred
    }

    private func openSystemLanguageSettings(result: @escaping FlutterResult) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            result(false)
            return
        }
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    result(success)
                }
            } else {
                result(false)
            }
        }
    }
}
