import Flutter
import UIKit
import Firebase
import GoogleSignIn
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebaseの設定
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Maps SDK for iOS（GoogleService-Info.plist の API_KEY を使用）
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
       let apiKey = dict["API_KEY"] as? String {
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Google Sign-InのURLスキーム処理を最新の書き方に修正
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // GIDSignInを使用してURLを処理
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}