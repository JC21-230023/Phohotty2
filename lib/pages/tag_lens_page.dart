import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/tag_chip.dart';
import '../services/google_vision.dart';
import '../services/local_storage.dart';

class TagLensPage extends StatefulWidget {
  const TagLensPage({super.key});

  @override
  State<TagLensPage> createState() => _TagLensPageState();
}

class _TagLensPageState extends State<TagLensPage> {
  Uint8List? imageBytes;
  List<String> suggestedTags = [];
  Set<String> selectedTags = {};
  List<String> customTags = [];

  bool loading = false;
  String? errorMessage;

  final picker = ImagePicker();
  final customTagController = TextEditingController();

  late final GoogleVisionService vision;
  final local = LocalStorageService();

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('Warning: GOOGLE_VISION_API_KEY is not set in .env');
      setState(() {
        errorMessage = 'Google Vision API キーが設定されていません。.envファイルを確認してください。';
      });
    }
    vision = GoogleVisionService(apiKey: apiKey);
  }

  @override
  void dispose() {
    customTagController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      imageBytes = bytes;
      selectedTags.clear();
      suggestedTags.clear();
      customTags.clear();
      loading = true;
      errorMessage = null;
    });

    try {
      final labels = await vision.analyzeLabels(bytes);

      setState(() {
        suggestedTags = labels;
        selectedTags = labels.toSet();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'タグ分析エラー: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void addCustomTag() {
    final tag = customTagController.text.trim();
    if (tag.isEmpty) return;

    if (selectedTags.contains(tag) || customTags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このタグは既に存在します')),
      );
      return;
    }

    customTags.add(tag);
    selectedTags.add(tag);

    customTagController.clear();
    setState(() {});
  }

  Future<void> saveImage() async {
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像を選択してください')),
      );
      return;
    }

    if (selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最低1つ以上のタグを選択してください')),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final path = await local.saveImage(imageBytes!);
      await local.saveImageTags(path, selectedTags.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像が保存されました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ギャラリーページへ移動
        Navigator.pushNamed(context, "/gallery");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Save error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ふぉとってぃ"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, "/gallery"),
            child: const Text("ギャラリー"),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 20),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => setState(() => errorMessage = null),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      // 画像選択エリア
                      InkWell(
                        onTap: pickImage,
                        child: Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: imageBytes == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 60,
                                      color: Colors.blue.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "クリックして写真を選択",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "またはドラッグ＆ドロップ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Image.memory(imageBytes!, fit: BoxFit.cover),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade700,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // タグ候補セクション
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "タグ候補",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          if (suggestedTags.isNotEmpty)
                            Text(
                              "${selectedTags.length} 個選択",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: imageBytes == null
                            ? const Text(
                                "写真をアップロードするとAIがタグを提案します。",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : suggestedTags.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text("タグが検出されませんでした"),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...suggestedTags.map((tag) => TagChip(
                                            label: tag,
                                            selected: selectedTags.contains(tag),
                                            onTap: () {
                                              setState(() {
                                                if (selectedTags.contains(tag)) {
                                                  selectedTags.remove(tag);
                                                } else {
                                                  selectedTags.add(tag);
                                                }
                                              });
                                            },
                                          )),
                                      ...customTags.map((tag) => TagChip(
                                            label: tag,
                                            selected: selectedTags.contains(tag),
                                            custom: true,
                                            onTap: () {
                                              setState(() {
                                                if (selectedTags.contains(tag)) {
                                                  selectedTags.remove(tag);
                                                } else {
                                                  selectedTags.add(tag);
                                                }
                                              });
                                            },
                                          )),
                                    ],
                                  ),
                      ),

                      const SizedBox(height: 20),

                      // カスタムタグ追加エリア
                      if (imageBytes != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "カスタムタグを追加",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: customTagController,
                                    decoration: InputDecoration(
                                      hintText: "タグ名を入力...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: (_) => addCustomTag(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FloatingActionButton.small(
                                  onPressed: addCustomTag,
                                  tooltip: 'タグを追加',
                                  child: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // 保存ボタン
                      if (imageBytes != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("保存してタグ付け完了"),
                          onPressed: loading ? null : saveImage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}