import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final local = LocalStorageService();

    return Scaffold(
      appBar: AppBar(title: const Text("ギャラリー")),
      body: FutureBuilder(
        future: local.loadGallery(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text("まだ画像がありません"));
          }

          return GridView.count(
            crossAxisCount: 2,
            children: items.map((item) {
              return Column(
                children: [
                  Expanded(
                    child: Image.file(
                      File(item["path"]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    (item["tags"] as List).join(", "),
                    style: const TextStyle(fontSize: 12),
                  )
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}