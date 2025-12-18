import 'package:flutter/material.dart';
import 'home_page.dart';
import 'gallery_page.dart';
import 'map_page.dart';
import 'sns_page.dart';
import 'settings_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  static _MainTabPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainTabPageState>();
  }

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0; // Default to Home page

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TagLensPage is removed from this list. Navigation will be handled by Navigator.push
    final pages = [
      const HomePage(),
      GalleryPage(), // onGoToTagLens is removed
      const MapPage(),
      const SnsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: switchTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // TagLens tab is removed
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Gallery'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.smartphone), label: 'SNS'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
