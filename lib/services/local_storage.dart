import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phototty/services/fb_auth.dart';
import 'package:phototty/services/storage_photo_getter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:phototty/services/fbstore_getter.dart';


class LocalStorageService {
  final uuid = const Uuid();
  final StoragePhotoGetter _photoGetter = StoragePhotoGetter.instance;

  /// 画像をアプリ内フォルダへ保存し、保存先パスを返す
  Future<String> saveImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();

    final id = uuid.v4();
    final imagePath = "${directory.path}/$id.jpg";
    print("Saving image to: $imagePath");
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
      "path": imagePath,//fbのダウンロードURL
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
/*
  /// ギャラリーからアイテム削除
  Future<void> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('gallery') ?? [];

    list.removeWhere((item) {
      final json = jsonDecode(item);
      return json["id"] == id;
    });

    await prefs.setStringList('gallery', list);
  }*/

  /// 全削除
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gallery');
    print("キャッシュクリア完了");
  }
  
  
  Future<void> getImageFromUser() async {
    await clearAll(); // 既存の重複を削除
     final String cUser=
      FbAuth.instance.currentUser?.uid ?? 'error_user';
    print("読み込み開始");
    final photos = await _photoGetter.getPhotosForCurrentUser();//StoragePhoto[]
    if (photos == null || photos.isEmpty) {
      print("写真がありません");
      return;
    }

    for (final element in photos) {
      final tags = await getTagListAsField(
        userId: cUser,
        imageName: element.name,
      );
      await saveImageURL(element, tags);
    }
    print("読み込み処理完了");
  }

                          //storage_photo_getterより
  Future<void> saveImageURL(StoragePhoto img, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('gallery') ?? [];
    final item = {
      "path": img.downloadUrl,//fbのダウンロードURL
      "tags": tags,
      "loaded": DateTime.now().toIso8601String(),

    };

    list.add(jsonEncode(item));
    await prefs.setStringList('gallery', list);
  }
}
/*
class PhotoAndTag{
  StoragePhoto photo;
  List<String> tags; 

  PhotoAndTag({required this.photo, required this.tags});
}*/
