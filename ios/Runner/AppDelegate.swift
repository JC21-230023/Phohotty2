import Flutter
import UIKit
import Firebase

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

    // // Google Sign-In configuration is handled by the plugin / SDK at sign-in time.
    // // No direct assignment to `GIDSignIn.sharedInstance.clientID` (removed because
    // // newer GoogleSignIn SDKs no longer expose that property).

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL schemes for Google Sign-In
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if let gidSignIn = NSClassFromString("GIDSignIn") {
      return (gidSignIn as! NSObjectProtocol).perform(Selector(("handleURL:")) with: url) != nil
    }
    return false
  }
}

```
