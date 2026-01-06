// filepath: c:\Users\230484\StudioProjects\phototty\lib\pages\settings_page.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _photoPermissionGranted = false;
  bool _locationPermissionGranted = false;
  bool _aiTaggingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadSettings();
  }

  Future<void> _loadPermissions() async {
    final photoStatus = await Permission.photos.status;
    final locationStatus = await Permission.location.status;
    setState(() {
      _photoPermissionGranted = photoStatus.isGranted;
      _locationPermissionGranted = locationStatus.isGranted;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiTaggingEnabled = prefs.getBool('aiTaggingEnabled') ?? false;
    });
  }

  Future<void> _requestPhotoPermission() async {
    final status = await Permission.photos.request();
    setState(() {
      _photoPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });
  }

  Future<void> _toggleAiTagging(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiTaggingEnabled', value);
    setState(() {
      _aiTaggingEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('写真フォルダへのアクセス許可'),
            value: _photoPermissionGranted,
            onChanged: (value) {
              if (value && !_photoPermissionGranted) {
                _requestPhotoPermission();
              }
            },
          ),
          SwitchListTile(
            title: const Text('位置情報へのアクセス許可'),
            value: _locationPermissionGranted,
            onChanged: (value) {
              if (value && !_locationPermissionGranted) {
                _requestLocationPermission();
              }
            },
          ),
          SwitchListTile(
            title: const Text('AIによる画像へのタグ付け機能'),
            value: _aiTaggingEnabled,
            onChanged: _toggleAiTagging,
          ),
        ],
      ),
    );
  }
}