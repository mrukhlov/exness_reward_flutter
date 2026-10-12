import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK BEFORE Flutter plugins
    // This is critical for Google Maps to work on iOS
    let apiKey = Secrets.googleMapsAPIKey
    GMSServices.provideAPIKey(apiKey)

    let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    print("✅ Google Maps API key initialized for iOS")
    print("📦 Bundle ID: \(bundleId)")
    print("🔑 API Key prefix: \(String(apiKey.prefix(10)))...")
    print("⚠️  IMPORTANT: Verify in Google Cloud Console:")
    print("   1. Maps SDK for iOS is ENABLED")
    print("   2. API key restrictions allow iOS apps")
    print("   3. Bundle ID matches: \(bundleId)")
    print("   4. API restrictions include: Maps SDK for iOS")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}