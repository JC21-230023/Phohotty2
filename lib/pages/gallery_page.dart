//import 'dart:io';//localの操作に移行するためコメントアウト
import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final local = LocalStorageService();
  late Future<List<Map<String, dynamic>>> _galleryFuture;

  @override
  void initState() {
    super.initState();
    _galleryFuture = _loadGalleryData();
  }

  Future<List<Map<String, dynamic>>> _loadGalleryData() async {
    await local.getImageFromUser(); // 先に画像を取得
    return await local.loadGallery(); // その後でギャラリーを読み込み
  }

  void _refreshGallery() {
    setState(() {
      _galleryFuture = local.loadGallery();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("ギャラリー")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: //Row(
                /*children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.label),
                      label: const Text("画像にタグ付け"),
                      onPressed: () async {
                        await Navigator.pushNamed(context, "/tag-lens");
                        _refreshGallery(); // 戻ってきたら更新
                      },
                    ),
                  ),
                  const SizedBox(width: 8),*/
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("更新"),
                    onPressed: _refreshGallery,
                  ),
               // ],
              ),
            ),
          //),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _galleryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("エラー: ${snapshot.error}"));
                }
                final items = snapshot.data;
                if (items == null || items.isEmpty) {
                  return const Center(child: Text("まだ画像がありません"));
                }
                return _buildGalleryGrid(items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        print("Building item $index");
        final item = items[index];
        final filePath = item["path"];
        final tags = (item["tags"] as List).join(", ");

         print("File path: $filePath, Tags: $tags");
        return GridTile(
          footer: GridTileBar(
            backgroundColor: Colors.black45,
            title: Text(
              tags,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
         // child: Image.file(File(filePath), fit: BoxFit.cover),
         //↑　ローカル移行のため保持
          child: Image.network(
            item["path"],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Image load error in gallery_page: $error');
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }
}
