import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  final uuid = const Uuid();

  /// 画像をアプリ内フォルダへ保存し、保存先パスを返す
  Future<String> saveImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();

    final id = uuid.v4();
    final imagePath = "${directory.path}/$id.jpg";

    final file = File(imagePath);
    await file.writeAsBytes(bytes);

    return imagePath;
  }

  /// 画像パスとタグ情報を SharedPreferences へ保存
  Future<void> saveImageTags(String imagePath, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList('gallery') ?? [];

    final item = {
      "id": uuid.v4(),
      "path": imagePath,
      "tags": tags,
      "created": DateTime.now().toIso8601String(),
    };

    list.add(jsonEncode(item));
    await prefs.setStringList('gallery', list);
  }

  /// ギャラリー一覧取得（画像パス＋タグ）
  Future<List<Map<String, dynamic>>> loadGallery() async {
    final prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList('gallery') ?? [];

    return list
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  /// ギャラリーからアイテム削除
  Future<void> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('gallery') ?? [];

    list.removeWhere((item) {
      final json = jsonDecode(item);
      return json["id"] == id;
    });

    await prefs.setStringList('gallery', list);
  }

  /// 全削除
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gallery');
  }
}