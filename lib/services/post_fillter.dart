
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phototty/services/post_marker.dart' ;
import 'package:phototty/services/others.dart';


Future<Set<Marker>> string2markers(String query,InfoTapCallback view) async {
  final tags = query
      .trim()
      .split(RegExp(r'[\s\u3000]+'))
      .where((e) => e.isNotEmpty)
      .toList();
  final snap = await _post_filler(tags, limit: 2);
  final markers = await doc2Marksers(snap, onInfoWindowTap:view);

  debugPrint("str2mrk:");
  return markers;
}

Future<QuerySnapshot<Map<String, dynamic>>> _post_filler(
  List<String> tags, {
  int limit = 50,
}) async {
  final firestore = FirebaseFirestore.instance;

  // array-contains-any は最大 10 要素
  final trimmed = tags.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final effectiveTags = trimmed.length > 10 ? trimmed.sublist(0, 10) : trimmed;

  // createdAt を orderBy するなら全ドキュメントにフィールドを持たせる
  final query = firestore
      .collection('posts')
      .where('postTagList', arrayContainsAny: effectiveTags)
      //.orderBy('createdAt', descending: true)
      .limit(limit);

  debugPrint('query:$query');
  return query.get();
}

