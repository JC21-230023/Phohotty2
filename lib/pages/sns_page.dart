import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SnsPage extends StatefulWidget {
  const SnsPage({super.key});

  @override
  State<SnsPage> createState() => _SnsPageState();
}

class _SnsPageState extends State<SnsPage> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    // 1. 現在地取得
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('位置情報取得失敗: $e');
    }

    // 2. Firebase Storage に画像アップロード
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance.ref().child('posts/$fileName.png');
    await storageRef.putFile(_imageFile!);
    final imageUrl = await storageRef.getDownloadURL();

    // 3. Firestore に投稿情報保存
    await FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl,
      'description': _descriptionController.text,
      'latitude': position?.latitude ?? 35.6762, // 権限なければ東京
      'longitude': position?.longitude ?? 139.6503,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isUploading = false;
      _imageFile = null;
      _descriptionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投稿が完了しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SNS投稿')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 200)
                : Placeholder(fallbackHeight: 200),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '説明文'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: _pickImage, child: const Text('画像選択')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadPost,
                  child: _isUploading ? const CircularProgressIndicator() : const Text('投稿'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}