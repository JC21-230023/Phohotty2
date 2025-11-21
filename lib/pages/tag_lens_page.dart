import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  final picker = ImagePicker();
  final customTagController = TextEditingController();

  final vision = GoogleVisionService(apiKey: "YOUR_GOOGLE_VISION_API_KEY");
  final local = LocalStorageService();

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
    });

    final labels = await vision.analyzeLabels(bytes);

    setState(() {
      suggestedTags = labels;
      selectedTags = labels.toSet();
      loading = false;
    });
  }

  void addCustomTag() {
    final tag = customTagController.text.trim();
    if (tag.isEmpty) return;

    customTags.add(tag);
    selectedTags.add(tag);

    customTagController.clear();
    setState(() {});
  }

  Future<void> saveImage() async {
    if (imageBytes == null) return;

    final path = await local.saveImage(imageBytes!);
    await local.saveImageTags(path, selectedTags.toList());

    Navigator.pushNamed(context, "/gallery");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ふぉとってぃ"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, "/gallery"),
            child: const Text("ギャラリー"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            InkWell(
              onTap: pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imageBytes == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 50, color: Colors.blue.shade300),
                    const SizedBox(height: 10),
                    const Text("クリックして写真を選択"),
                    const Text("またはドラッグ＆ドロップ"),
                  ],
                )
                    : Image.memory(imageBytes!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),
            const Text("タグ候補",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (imageBytes == null)
                  ? const Text("写真をアップロードするとAIがタグを提案します。")
                  : Wrap(
                spacing: 8,
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

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customTagController,
                    decoration: const InputDecoration(hintText: "カスタムタグを追加..."),
                    onSubmitted: (_) => addCustomTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addCustomTag,
                )
              ],
            ),

            const SizedBox(height: 20),

            if (imageBytes != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("保存してタグ付け完了"),
                onPressed: saveImage,
              ),
          ],
        ),
      ),
    );
  }
}