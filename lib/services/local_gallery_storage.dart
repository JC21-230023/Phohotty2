import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  Future<String> saveImage(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final id = const Uuid().v4();
    final file = File("${dir.path}/$id.jpg");

    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> saveImageTags(String path, List<String> tags) async {
    final pref = await SharedPreferences.getInstance();

    final savedList = pref.getStringList("gallery") ?? [];

    final item = jsonEncode({
      "path": path,
      "tags": tags,
      "created": DateTime.now().toIso8601String(),
    });

    savedList.add(item);
    await pref.setStringList("gallery", savedList);
  }

  Future<List<Map<String, dynamic>>> loadGallery() async {
    final pref = await SharedPreferences.getInstance();
    final list = pref.getStringList("gallery") ?? [];

    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
