import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:phototty/services/fb_auth.dart';
import 'dart:io';
import 'dart:async';

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

  /// Network call with retry logic for resilience
  Future<T> _retryNetworkCall<T>(
    Future<T> Function() networkCall, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await networkCall().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Network request timed out'),
        );
      } on SocketException {
        // Connection reset by peer (errno = 54) or other socket errors
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(delay * attempt); // Exponential backoff
          debugPrint('Retry attempt $attempt for network call');
          continue;
        }
        rethrow;
      } on TimeoutException {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(delay * attempt);
          debugPrint('Retry attempt $attempt after timeout');
          continue;
        }
        rethrow;
      } catch (e) {
        // For other exceptions, retry once more
        if (attempt < maxRetries - 1 && e.toString().contains('Connection')) {
          attempt++;
          await Future.delayed(delay * attempt);
          debugPrint('Retry attempt $attempt for connection error');
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Network call failed after $maxRetries retries');
  }



Future<List<StoragePhoto>?> getPhotosForCurrentUser() async {
  final String cUser=FbAuth.instance.currentUser?.uid ?? 'error_user';
    return getPhotosForUser(cUser);
}
  /// 指定されたユーザーのFirebaseStorageフォルダから画像一覧を取得
  /// [userId]: ユーザーID（必須）
  /// Returns: StoragePhotoのリスト、またはエラー時はnull
  Future<List<StoragePhoto>?> getPhotosForUser(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/');
      final listResult = await _retryNetworkCall(
        () => ref.listAll(),
      );

      if (listResult.items.isEmpty) {
        debugPrint('保存済みの画像がありません（ユーザーID: $userId）');
        return [];
      }

      final photoList = <StoragePhoto>[];

      // 各画像のダウンロードURLを取得
      for (var item in listResult.items) {
        if(item.name==".keep"){
          print(".keep除外");
          continue;
        }
        try {
          final url = await _retryNetworkCall(
            () => item.getDownloadURL(),
          );
          photoList.add(
            StoragePhoto(
              name: item.name,
              fullPath: item.fullPath,
              downloadUrl: url,
            ),
          );
        } catch (e) {
          debugPrint('画像URL取得失敗: ${item.name}, エラー: $e');
          // Continue with other images instead of failing completely
        }
      }

      return photoList;
    } catch (e) {
      debugPrint('FirebaseStorage読み込み失敗: $e');
      rethrow;
    }
  }
/*
  /// 特定のパスから画像を取得（より詳細な制御が必要な場合）
  /// [path]: FirebaseStorageのパス（例: 'users/userId/'）
  Future<List<StoragePhoto>?> getPhotosFromPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final listResult = await _retryNetworkCall(
        () => ref.listAll(),
      );

      if (listResult.items.isEmpty) {
        debugPrint('指定されたパスに画像がありません: $path');
        return [];
      }

      final photoList = <StoragePhoto>[];

      for (var item in listResult.items) {
        try {
          final url = await _retryNetworkCall(
            () => item.getDownloadURL(),
          );
          photoList.add(
            StoragePhoto(
              name: item.name,
              fullPath: item.fullPath,
              downloadUrl: url,
            ),
          );
        } catch (e) {
          debugPrint('画像URL取得失敗: ${item.name}, エラー: $e');
          // Continue with other images instead of failing completely
        }
      }

      return photoList;
    } catch (e) {
      debugPrint('FirebaseStorage読み込み失敗（パス: $path）: $e');
      rethrow;
    }
  }*/
/*
  /// 画像を削除（オプション機能）
  /// 
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
  }*/
}
