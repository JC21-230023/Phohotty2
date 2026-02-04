import Flutter
import UIKit
import Firebase
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase for native iOS usage
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Set Google Sign-In client ID from Firebase config (if available)
    if let clientID = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.clientID = clientID
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
