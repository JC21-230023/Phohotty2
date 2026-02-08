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
      home: _AuthGate(isFirebaseReady: widget.isFirebaseReady),
    );
  }
}

/// 認証状態に応じて AuthPage / MainTabPage を表示。
/// initialData で即時表示し、ストリームが遅れてもタイムアウトでログイン画面を表示する。
class _AuthGate extends StatefulWidget {
  final bool isFirebaseReady;

  const _AuthGate({required this.isFirebaseReady});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showLoginAfterTimeout = false;

  @override
  void initState() {
    super.initState();
    // ストリームが emit されない場合に備え、一定時間でログイン画面を表示
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_showLoginAfterTimeout) {
        setState(() => _showLoginAfterTimeout = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFirebaseReady) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Firebaseの初期化に失敗しました。\n設定ファイルやネットワークを確認してください。',
          ),
        ),
      );
    }

    return StreamBuilder<FbUser?>(
      stream: FbAuth.instance.authStateChanges,
      initialData: FbAuth.instance.currentUser,
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
        // データがある、またはタイムアウト済みならログイン/メインを表示（読み込みで永久に止まらない）
        final hasData = snapshot.hasData;
        if (hasData || _showLoginAfterTimeout) {
          final user = hasData ? snapshot.data : null;
          if (user == null) {
            return const AuthPage();
          }
          return const MainTabPage();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}