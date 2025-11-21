import 'package:flutter/material.dart';
import 'pages/tag_lens_page.dart';
import 'pages/gallery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/": (_) => const TagLensPage(),
        "/gallery": (_) => const GalleryPage(),
      },
      initialRoute: "/",
    );
  }
}