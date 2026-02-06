
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'local_storage.dart';

class TagImageSaver {
  static final LocalStorageService _localStorage = LocalStorageService();

  /// Network call with retry logic
  static Future<T> _retryNetworkCall<T>(
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
      } on SocketException catch (e) {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(delay * attempt);
          debugPrint('Retry attempt $attempt for network call');
          continue;
        }
        rethrow;
      } on TimeoutException catch (e) {
        if (attempt < maxRetries - 1) {
          attempt++;
          await Future.delayed(delay * attempt);
          debugPrint('Retry attempt $attempt after timeout');
          continue;
        }
        rethrow;
      } catch (e) {
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

    // Upload with retry logic
    final uploadTask = await _retryNetworkCall(
      () => storageRef.putData(imageBytes, metadata),
    );
    
    final downloadUrl = await _retryNetworkCall(
      () => storageRef.getDownloadURL(),
    );
  

    await _localStorage.saveImageTags(downloadUrl, tags);

    // Save to Firestore with retry logic
    await _retryNetworkCall(
      () => FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('gallery')
          .doc(fileName)
          .set({
            'tagList': tags,
          }),
    );

    return downloadUrl;
  }
}
