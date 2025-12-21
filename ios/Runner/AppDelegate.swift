import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK
    // Priority order:
    // 1. Secrets.swift (most secure, gitignored)
    // 2. Info.plist (fallback)
    // 3. Environment variable (for CI/CD)
    
    let apiKey: String? = {
      // Try Secrets.swift first (most secure, gitignored)
      if Secrets.googleMapsAPIKey != "YOUR_GOOGLE_MAPS_API_KEY_HERE" {
        return Secrets.googleMapsAPIKey
      }
      // Fallback to Info.plist
      if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GMS_API_KEY") as? String,
         !plistKey.isEmpty, plistKey != "YOUR_GOOGLE_MAPS_API_KEY_HERE" {
        return plistKey
      }
      // Fallback to environment variable (for CI/CD)
      if let envKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"],
         !envKey.isEmpty {
        return envKey
      }
      return nil
    }()
    
    if let key = apiKey {
      // Initialize Google Maps SDK BEFORE Flutter plugins
      GMSServices.provideAPIKey(key)
      let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
      print("✅ Google Maps API key initialized: \(String(key.prefix(10)))...")
      print("📦 Bundle ID: \(bundleId)")
      print("⚠️  IMPORTANT: Verify API key restrictions in Google Cloud Console:")
      print("   - Application restrictions: iOS apps")
      print("   - Bundle ID must match exactly: \(bundleId)")
      print("   - API restrictions: Maps SDK for iOS")
    } else {
      print("⚠️ ERROR: Google Maps API key not found!")
      print("Please add your API key to ios/Runner/Secrets.swift")
      print("Or set GMS_API_KEY in Info.plist or GOOGLE_MAPS_API_KEY environment variable")
      print("Get your key from: https://console.cloud.google.com/google/maps-apis")
      // Don't crash, but maps won't work
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
