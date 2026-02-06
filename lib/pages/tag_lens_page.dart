import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_vision.dart';
import '../services/tag_translator.dart';
import '../services/local_storage.dart';
import '../services/fb_auth.dart';
import '../services/tag_image_saver.dart';
import '../widgets/taglist_widget.dart';//タグを扱う
import '../pages/gallery_page.dart';

class TagLensPage extends StatefulWidget {
  const TagLensPage({super.key});

  @override
  State<TagLensPage> createState() => _TagLensPageState();
}

class _TagLensPageState extends State<TagLensPage> {
  Uint8List? imageBytes;

  List<String> suggestedTags = [];
  Set<String> _selectedTags = {};//widgetのTagListから取得


  bool loading = false;
  String? errorMessage;
  bool aiEnabled = false;

  final picker = ImagePicker();
  final customTagController = TextEditingController();

  late final GoogleVisionService vision;
  //final local = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
    setState(() {
      aiEnabled = prefs.getBool('aiTaggingEnabled') ?? true;
      if (apiKey.isEmpty) {
        errorMessage = 'Google Vision API キーが設定されていません';
      }
    });
    vision = GoogleVisionService(apiKey: apiKey);
  }

  @override
  void dispose() {
    customTagController.dispose();
    super.dispose();
  }

  // ===============================
  // 画像選択 → AI解析 → 日本語タグ化
  // ===============================
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      imageBytes = bytes;
      suggestedTags.clear();
      _selectedTags.clear();
      loading = true;
      errorMessage = null;
    });

    if (aiEnabled) {
      try {
        // ① AIで英語タグ取得
        final labels = await vision.analyzeLabels(bytes);

        // 辞書登録込みで日本語化
        final jaTags =
          await TagTranslator.toJapaneseSmartList(labels);
        setState(() {
          suggestedTags = jaTags;
          _selectedTags = jaTags.toSet();
          loading = false;
        });
      } catch (e) {
        setState(() {
          loading = false;
          errorMessage = 'タグ解析エラー: $e';
        });
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  // ===============================
  // 保存処理(fbStore:tag,fbStorage:image)
  // ===============================
  Future<void> saveImage() async {
    if (imageBytes == null || _selectedTags.isEmpty) return;
    try {
      setState(() => loading = true);

      final user = FbAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしてください')),
        );
        return;
      }

      final uid = user.uid;
      
      // TagImageSaver で処理を統一
      await TagImageSaver.saveImageWithTags(//
        imageBytes: imageBytes!,
        tags: _selectedTags.toList(),//(widgetの)tagList.selectedTagsに
        uid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画像とタグを保存しました（クラウド）'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamed(context, '/gallery');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存エラー: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ふぉとってぃ'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GalleryPage()),
              );
            },
            child: Text('ギャラリー'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(           // ← ここが親（children: を使える）
                 children: [
                    InkWell(
                      onTap: pickImage,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: imageBytes == null
                            ? const Center(
                                child: Text('クリックして画像を選択'),//v2：更新の確認
                              )
                            : Image.memory(imageBytes!, fit: BoxFit.cover),
                      ),
                    ),
                    TagSelector(
                      initialSuggestedTags:suggestedTags,//AIのタグ
                      onChanged: (tags) {
                        setState(() {
                          _selectedTags = tags;
                        });
                      },
                    ), 
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                      onPressed: saveImage,
                    )             
                 ]              
              ),
            ),
    );
  }
}
