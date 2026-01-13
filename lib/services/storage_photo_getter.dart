import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StoragePhoto {
  final String name;
  final String fullPath;
  final String downloadUrl;

  StoragePhoto({
    required this.name,
    required this.fullPath,
    required this.downloadUrl,
  });
}

class StoragePhotoGetter {
  StoragePhotoGetter._();
  static final StoragePhotoGetter instance = StoragePhotoGetter._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 指定されたユーザーのFirebaseStorageフォルダから画像一覧を取得
  /// [userId]: ユーザーID（必須）
  /// Returns: StoragePhotoのリスト、またはエラー時はnull
  Future<List<StoragePhoto>?> getPhotosForUser(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/');
      final listResult = await ref.listAll();

      if (listResult.items.isEmpty) {
        debugPrint('保存済みの画像がありません（ユーザーID: $userId）');
        return [];
      }

      final photoList = <StoragePhoto>[];

      // 各画像のダウンロードURLを取得
      for (var item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          photoList.add(
            StoragePhoto(
              name: item.name,
              fullPath: item.fullPath,
              downloadUrl: url,
            ),
          );
        } catch (e) {
          debugPrint('画像URL取得失敗: ${item.name}, エラー: $e');
        }
      }

      return photoList;
    } catch (e) {
      debugPrint('FirebaseStorage読み込み失敗: $e');
      rethrow;
    }
  }

  /// 特定のパスから画像を取得（より詳細な制御が必要な場合）
  /// [path]: FirebaseStorageのパス（例: 'users/userId/'）
  Future<List<StoragePhoto>?> getPhotosFromPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final listResult = await ref.listAll();

      if (listResult.items.isEmpty) {
        debugPrint('指定されたパスに画像がありません: $path');
        return [];
      }

      final photoList = <StoragePhoto>[];

      for (var item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          photoList.add(
            StoragePhoto(
              name: item.name,
              fullPath: item.fullPath,
              downloadUrl: url,
            ),
          );
        } catch (e) {
          debugPrint('画像URL取得失敗: ${item.name}, エラー: $e');
        }
      }

      return photoList;
    } catch (e) {
      debugPrint('FirebaseStorage読み込み失敗（パス: $path）: $e');
      rethrow;
    }
  }

  /// 画像を削除（オプション機能）
  /// [userId]: ユーザーID
  /// [imageName]: 削除する画像のファイル名
  Future<bool> deletePhoto(String userId, String imageName) async {
    try {
      final ref = _storage.ref().child('users/$userId/$imageName');
      await ref.delete();
      debugPrint('画像削除成功: $imageName');
      return true;
    } catch (e) {
      debugPrint('画像削除失敗: $imageName, エラー: $e');
      return false;
    }
  }
}
