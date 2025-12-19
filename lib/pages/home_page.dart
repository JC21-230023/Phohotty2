import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("新しい画面")),
      body: const Center(
        child: Text("GooglePhotoの画像ギャラリーを参照予定"), //GooglePhoto API未対応のため保留
      ),
    );
  }
}