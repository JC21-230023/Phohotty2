import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初期化状態を管理するフラグ
  bool isFirebaseReady = false;

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found - $e');
  }

  try {
    // ネットワーク不調で無限待ちにならないようタイムアウトを設定
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('Firebase initialization timed out');
        throw TimeoutException('Firebase init', Duration(seconds: 15));
      },
    );
    
    // Crashlyticsのエラー転送設定
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    isFirebaseReady = true; // 成功時にフラグを立てる
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // 失敗時はフラグが false のままになる
  }

  // フラグをMyAppに渡す
  runApp(MyApp(isFirebaseReady: isFirebaseReady));
}

class MyApp extends StatefulWidget {
  final bool isFirebaseReady; // 追加
  const MyApp({super.key, required this.isFirebaseReady});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 起動直後はUI描画と権限ダイアログの競合でデッドロックすることがあるため、
    // 初回フレーム描画後に少し遅延してから権限リクエストを行う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), _requestPermissions);
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      debugPrint('Permission status: $ps');
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 解決策1: Firebaseが準備できていない場合は、Auth機能を呼ばずにエラー画面を表示
    if (!widget.isFirebaseReady) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Firebaseの初期化に失敗しました。\n設定ファイルやネットワークを確認してください。'),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FbUser?>(
        stream: FbAuth.instance.authStateChanges,
        // initialData を外し、ストリームの初回イベントのみで描画する（頻繁な再描画・ループを防ぐ）
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Auth stream error in main: ${snapshot.error}');
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('認証エラー'),
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }
          // 初回は waiting または hasData が false のときローディング表示
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final user = snapshot.data;
          if (user == null) {
            return const AuthPage();
          }
          return const MainTabPage();
        },
      ),
    );
  }
}