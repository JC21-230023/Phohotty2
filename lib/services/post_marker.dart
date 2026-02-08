
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:phototty/services/others.dart';
//infoTapCallBack取り込み

Future<Set<Marker>> getPostMarkers(InfoTapCallback view) async {
  //final Set<Marker> markers = {};
  final snap = await FirebaseFirestore.instance.collection('posts').get();
 final Set<Marker> markers=await doc2Marksers(snap, onInfoWindowTap: view);
  return markers; 
}

Future<Set<Marker>> doc2Marksers(
  QuerySnapshot<Map<String, dynamic>> snap, {
  required void Function({
    required String docId,
    required String title,
    required String imageUrl,
    required String tagList,
  }) onInfoWindowTap,
}) async {
  final Set<Marker> ans = {};

  for (var doc in snap.docs) {
    try {
      final data = doc.data();
      final loc = data['location'];
      if (loc == null || loc is! GeoPoint) continue;

      final String title = (data['description'] ?? 'No Title') as String;
      final String imageUrl = (data['imageUrl'] ?? '') as String;
      final postTagList = data['postTagList'];
      final String tagList = postTagList is List
          ? postTagList.map((e) => e?.toString() ?? '').join(', ')
          : 'No Tags';

      final BitmapDescriptor icon = imageUrl.isEmpty
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
          : await _iconFromImageUrl(imageUrl, size: 96, borderWidth: 4);

      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(loc.latitude, loc.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: title,
          snippet: tagList,
          onTap: () {
            onInfoWindowTap(
              docId: doc.id,
              title: title,
              imageUrl: imageUrl,
              tagList: tagList,
            );
          },
        ),
        onTap: () {
          debugPrint("マーカーがタップされた: ${doc.id}");
        },
      );

      ans.add(marker);
    } catch (e) {
      debugPrint('post_marker skip doc ${doc.id}: $e');
    }
  }

  return ans;
}

///gemiさん作

/// 画像アイコンのキャッシュ（imageUrl → BitmapDescriptor）
final Map<String, BitmapDescriptor> iconCache = {};

/// imageUrl の画像を円形に切り抜いて Marker アイコンに変換
Future<BitmapDescriptor> _iconFromImageUrl(
  String imageUrl, {
  int size = 96,        // アイコンのピクセルサイズ（64〜96推奨）
  int borderWidth = 4,  // 白縁の太さ（0で無効）
}) async {
  if (imageUrl.isEmpty) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  if (iconCache.containsKey(imageUrl)) {
    return iconCache[imageUrl]!;
  }

  try {
    final resp = await http.get(Uri.parse(imageUrl));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    // デコードしつつリサイズ
    final codec = await ui.instantiateImageCodec(
      resp.bodyBytes,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final ui.Image src = frame.image;

    // 円形に描画
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    final center = Offset(size / 2.0, size / 2.0);
    final radius = size / 2.0;

    // 円形クリップ
    final clip = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clip);

    // 画像をフィット
    final srcRect = Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.drawImageRect(src, srcRect, dstRect, Paint());
    canvas.restore();

    // 白縁
    if (borderWidth > 0) {
      final p = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth.toDouble()
        ..isAntiAlias = true;
      canvas.drawCircle(center, radius - borderWidth / 2.0, p);
    }

    // PNG バイト列へ
    final img = await recorder.endRecording().toImage(size, size);
    final pngBytes = (await img.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();

    final icon = BitmapDescriptor.fromBytes(pngBytes);
    iconCache[imageUrl] = icon;
    return icon;
  } catch (e) {
    debugPrint('Icon generate error: $e');
    // 失敗したら標準ピン
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
}

