import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_vision.dart';
import '../services/tag_translator.dart';
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

  GoogleVisionService? vision;
  bool _visionInitialized = false;
  //final local = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
      
      if (mounted) {
        setState(() {
          aiEnabled = prefs.getBool('aiTaggingEnabled') ?? true;
          if (apiKey.isEmpty) {
            errorMessage = 'Google Vision API キーが設定されていません';
          } else {
            vision = GoogleVisionService(apiKey: apiKey);
            _visionInitialized = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() {
          errorMessage = '設定読み込みエラー: $e';
        });
      }
    }
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

    if (!mounted) return;
    setState(() {
      imageBytes = bytes;
      suggestedTags.clear();
      _selectedTags.clear();
      loading = true;
      errorMessage = null;
    });

    if (aiEnabled && _visionInitialized && vision != null) {
      try {
        // ① AIで英語タグ取得
        final labels = await vision!.analyzeLabels(bytes);
        
        if (labels.isEmpty) {
          debugPrint('Vision API returned null or empty labels');
          if (!mounted) return;
          setState(() {
            loading = false;
            suggestedTags = [];
            _selectedTags.clear();
          });
          return;
        }

        // 辞書登録込みで日本語化
        final jaTags = await TagTranslator.toJapaneseSmartList(labels);
        
        if (jaTags?.isEmpty ?? true) {
          debugPrint('TagTranslator returned null or empty list');
          if (!mounted) return;
          setState(() {
            loading = false;
            suggestedTags = labels; // フォールバック：英語タグを使用
            _selectedTags = labels.toSet();
          });
          return;
        }
        
        if (!mounted) return;
        setState(() {
          suggestedTags = jaTags ?? [];
          _selectedTags = (jaTags ?? []).toSet();
          loading = false;
        });
      } catch (e) {
        debugPrint('Tag analysis error: $e');
        if (!mounted) return;
        setState(() {
          loading = false;
          errorMessage = 'タグ解析エラー: $e';
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        loading = false;
        if (!aiEnabled) {
          errorMessage = 'AI タグ機能が無効です';
        } else if (!_visionInitialized) {
          errorMessage = 'Google Vision サービスが初期化されていません';
        }
      });
    }
  }

  // ===============================
  // 保存処理(fbStore:tag,fbStorage:image)
  // ===============================
  Future<void> saveImage() async {
    if (imageBytes == null || _selectedTags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像とタグを選択してください')),
        );
      }
      return;
    }
    
    try {
      if (!mounted) return;
      setState(() => loading = true);

      final user = FbAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインしてください')),
          );
        }
        return;
      }

      final uid = user.uid;
      final bytes = imageBytes;
      
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像データが失われました')),
          );
        }
        return;
      }
      
      // TagImageSaver で処理を統一
      await TagImageSaver.saveImageWithTags(
        imageBytes: bytes,
        tags: _selectedTags.toList(),
        uid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画像とタグを保存しました（クラウド）'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.pushNamed(context, '/gallery');
      }
    } catch (e) {
      debugPrint('Save image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
