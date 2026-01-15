
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Colors, Paint などを使う場合
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Set<Marker>> getPostMarkers() async {
  final Set<Marker> markers = {};
  final snap = await FirebaseFirestore.instance.collection('posts').get();

    for (var doc in snap.docs) {
      final data = doc.data();
      final GeoPoint geoPoint = data['location'];
      final String title = data['description'] ?? 'No Title';
      final String imageUrl = data['imageUrl'] ;

    // 画像アイコン（imageUrl が空なら標準ピン）
    final BitmapDescriptor icon = imageUrl.isEmpty
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
        : await _iconFromImageUrl(imageUrl, size: 96, borderWidth: 4);


      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(title: title),
        icon: icon
      );
      markers.add(marker);
      
    }
  return markers; 
}

///gemiさん作

/// 画像アイコンのキャッシュ（imageUrl → BitmapDescriptor）
final Map<String, BitmapDescriptor> _iconCache = {};

/// imageUrl の画像を円形に切り抜いて Marker アイコンに変換
Future<BitmapDescriptor> _iconFromImageUrl(
  String imageUrl, {
  int size = 96,        // アイコンのピクセルサイズ（64〜96推奨）
  int borderWidth = 4,  // 白縁の太さ（0で無効）
}) async {
  if (imageUrl.isEmpty) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  if (_iconCache.containsKey(imageUrl)) {
    return _iconCache[imageUrl]!;
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
    _iconCache[imageUrl] = icon;
    return icon;
  } catch (e) {
    debugPrint('Icon generate error: $e');
    // 失敗したら標準ピン
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
}


/*


  // アイコン生成を並列化（大量だと重くなるので注意）
  await Future.wait(snap.docs.map((doc) async {
    final data = doc.data();

    final geo = data['location'];
    if (geo is! GeoPoint) return; // GeoPoint 以外はスキップ

    final geoPoint = geo as GeoPoint;
    final String title = (data['title'] ?? data['description'] ?? 'No Title').toString();
    final String imageUrl = (data['imageUrl'] ?? '').toString();

    // 画像アイコン（imageUrl が空なら標準ピン）
    final BitmapDescriptor icon = imageUrl.isEmpty
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
        : await _iconFromImageUrl(imageUrl, size: 96, borderWidth: 4);

    final marker = Marker(
      markerId: MarkerId(doc.id),
      position: LatLng(geoPoint.latitude, geoPoint.longitude),
      infoWindow: InfoWindow(title: title),
      icon: icon,
      // onTap: () { /* 詳細画面へ遷移など */ },
    );

    markers.add(marker);
  }));

  return markers;
}



*/ 