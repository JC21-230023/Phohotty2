// lib/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 指定されたFirestoreパスから 'taglist' フィールドのデータを取得します。
///
/// [userId] はユーザーID。
/// [imageName] はギャラリー内の画像の名前。
/// 成功した場合は 'taglist' フィールドのデータを返します。
/// フィールドが存在しない場合やドキュメントが存在しない場合は null を返します。
/// エラーが発生した場合は例外をスローします。

Future<List<String>> getTagListAsField({
   required String userId,
  required String imageName,
}) async {
  try {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    DocumentSnapshot imageDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('gallery')
        .doc(imageName)
        .get();

    if (imageDoc.exists && imageDoc.data() != null) {
      Map<String, dynamic> data = imageDoc.data() as Map<String, dynamic>;
      if (data.containsKey('tagList')) {
        return List<String>.from(data['tagList']); //
      } else {
        print('画像ドキュメント "$imageName" に "tagList" フィールドが見つかりませんでした。');
        return  ["tagなし","tagListが不在"];
      }
    } else {
      print('画像ドキュメント "$imageName" が存在しません。');
      return ["tagなし","$imageNameが不在"];
    }
  } catch (e) {
    print('taglistの取得中にエラーが発生しました: $e');
    // エラー処理を呼び出し元に委ねるために、例外を再スローします
    rethrow;
  }
}
