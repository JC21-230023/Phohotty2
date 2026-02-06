import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _aiTaggingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _aiTaggingEnabled = prefs.getBool('aiTaggingEnabled') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveAiTaggingEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('aiTaggingEnabled', value);
      if (mounted) {
        setState(() {
          _aiTaggingEnabled = value;
        });
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> _requestPhotoPermission(BuildContext context) async {
    try {
      final status = await Permission.photos.request();

      if (!mounted) return;

      if (status.isGranted) {
        _show(context, '写真フォルダへのアクセスを許可しました');
      } else if (status.isPermanentlyDenied) {
        _openSettings(context);
      } else {
        _show(context, '写真フォルダへのアクセスが拒否されました');
      }
    } catch (e) {
      debugPrint('Photo permission error: $e');
      if (mounted) {
        _show(context, '権限リクエストでエラーが発生しました');
      }
    }
  }

  Future<void> _requestLocationPermission(BuildContext context) async {
    try {
      final status = await Permission.locationWhenInUse.request();

      if (!mounted) return;

      if (status.isGranted) {
        _show(context, '位置情報へのアクセスを許可しました');
      } else if (status.isPermanentlyDenied) {
        _openSettings(context);
      } else {
        _show(context, '位置情報へのアクセスが拒否されました');
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
      if (mounted) {
        _show(context, '権限リクエストでエラーが発生しました');
      }
    }
  }

  void _openSettings(BuildContext context) {
    openAppSettings();
    _show(context, '設定画面から権限を有効にしてください');
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // Vision AI はデフォルトで有効。設定項目は削除しました。
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('写真フォルダへのアクセス許可'),
            onTap: () => _requestPhotoPermission(context),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('位置情報へのアクセス許可'),
            onTap: () => _requestLocationPermission(context),
          ),
        ],
      ),
    );
  }
}
