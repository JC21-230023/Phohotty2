
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'local_storage.dart';

class TagImageSaver {
  static final LocalStorageService _localStorage = LocalStorageService();

  /// FireStorageに画像を保存してタグを記録
  /// 
  /// [imageBytes] - 保存する画像データ
  /// [tags] - 画像に付与するタグリスト
  /// [uid] - Firebase認証ユーザーID
  /// 
  /// 戻り値: ダウンロードURL
  static Future<String> saveImageWithTags({
    required Uint8List imageBytes,
    required List<String> tags,
    required String uid,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'users/$uid/$fileName';

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    final uploadTask = storageRef.putData(imageBytes, metadata);
    await uploadTask;
    final downloadUrl = await storageRef.getDownloadURL();

    // SharedPreferences に保存
    await _localStorage.saveImageTags(downloadUrl, tags);

    return downloadUrl;
  }
}
