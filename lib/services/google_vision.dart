import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

Future<Uint8List> resizeImageBytes(Uint8List data) async {
  // 画像をデコード
  final original = img.decodeImage(data);
  if (original == null) return data;

  // 1/4 に縮小する（幅・高さどちらも 1/2 * 1/2 = 1/4）
  final resized = img.copyResize(
    original,
    width: original.width ~/ 2,
    height: original.height ~/ 2,
  );

  // JPEG として再エンコード
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

class GoogleVisionService {
  final String apiKey;

  GoogleVisionService({required this.apiKey});

  Future<List<String>> analyzeLabels(Uint8List bytes) async {
    // 追加：送信前に1/4サイズに縮小
    final resizedBytes = await resizeImageBytes(bytes);
    final base64Image = base64Encode(resizedBytes);

    final url = Uri.parse(
      "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyCQmFMGebUKwKal5xqLrPd86mGgcwjCTjc",
    );

    final body = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10}
          ]
        }
      ]
    };

    final response = await http
        .post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception("Vision API error: ${response.body}");
    }

    final result = jsonDecode(response.body);
    if (result["responses"] == null) {
      throw Exception("Invalid response: ${response.body}");
    }
    final labels = result["responses"][0]["labelAnnotations"];
    if (labels == null) return [];

    return labels.map<String>((e) => e["description"]).toList();
  }
}