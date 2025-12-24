import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'pages/main_tab_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Request storage permission at startup
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  debugPrint('Permission status: $ps');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainTabPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
