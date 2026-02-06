import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';//ローカル移行のためコメントアウト
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phototty/services/fbstore_getter.dart';
import 'package:phototty/widgets/taglist_widget.dart';
import '../services/storage_photo_getter.dart';
import '../services/fb_auth.dart';

class SnsPage extends StatefulWidget {
  const SnsPage({super.key});

  @override
  State<SnsPage> createState() => _SnsPageState();
}

class _SnsPageState extends State<SnsPage> {
  File? _imageFile;
  String? _selectedImageUrl; // Firebase Storageから選択した画像URL
  String? _selectedImageName; // 選択した画像の識別用ファイル名
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  List<String> suggestedTags = [];//画像が持つタグ(初期値で
  Set<String> _selectedTags = {};//選択されたタグ


  // 端末からの画像選択（従来の機能）
  /*ローカル移行のためコメントアウト
  Future<void> _pickImageFromDevice() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _selectedImageUrl = null;
        _selectedImageName = null;
      });
    }
  }*/

  // FirebaseStorageから画像リストを取得して選択
  Future<void> _pickImageFromFirebaseStorage() async {
    try {
      final currentUser = FbAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーがログインしていません')),
        );
        return;
      }

      // StoragePhotoGetterサービスから画像リストを取得
      final imageList = await StoragePhotoGetter.instance.getPhotosForUser(currentUser.uid);

      if (imageList == null || imageList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存済みの画像がありません')),
          );
        }
        return;
      }

      // ボトムシートで画像選択UI表示
      if (mounted) {
        _showImageSelectionBottomSheet(imageList);
      }
      

    } catch (e) {
      debugPrint('FirebaseStorage読み込み失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  // 画像選択ボトムシート
  void _showImageSelectionBottomSheet(List<StoragePhoto> imageList) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('保存済み画像から選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageList.length,
                itemBuilder: (context, index) {
                  final image = imageList[index];
                  return GestureDetector(
                    onTap: () async{
                      // 画像を選択して状態を更新
                      List<String>newTags = await getTagListAsField(
                            userId: FbAuth.instance.currentUser!.uid,
                            imageName: image.name);

                      setState((){
                        _selectedImageUrl = image.downloadUrl;
                        _selectedImageName = image.name;
                        print("Bottomsheet_ImageName: $_selectedImageName");
                        suggestedTags = newTags;
                        _selectedTags = suggestedTags.toSet();

                        _imageFile = null;// 端末の画像をクリア
                      });
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('画像「${image.name}」を選択しました')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          image.downloadUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Image load error in sns_page: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null && _selectedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像を選択してください')),
      );
      return;
    }

    setState(() => _isUploading = true);

    // 1. 現在地取得
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('位置情報取得失敗: $e');
    }

    // 2. Firebase Storage に画像アップロード（端末から選択した場合のみ）
    String imageUrl = _selectedImageUrl!; // Firebase Storageから選択した場合

    if (_imageFile != null) {
      // 端末から選択した画像をアップロード
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('posts/$fileName.png');
      await storageRef.putFile(_imageFile!);
      imageUrl = await storageRef.getDownloadURL();
    }

    // 3. Firestore に投稿情報保存
    // 選択した画像を識別するため、selectedImageNameも保存
    await FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl,
      'selectedImageName': _selectedImageName, // 識別用ファイル名
      'description': _descriptionController.text,
      'location': GeoPoint(
        position?.latitude ?? 35.6762,
        position?.longitude ?? 139.6503,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      //以下自力作成(要注意)
      'postedBY': FbAuth.instance.currentUser?.uid,

      'postTagList':_selectedTags,
        //＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
        //＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
        //画像からタグを取得
      /*
        _selectedImageName != null && FbAuth.instance.currentUser != null
            ? await getTagListAsField(
                userId: FbAuth.instance.currentUser!.uid,
                imageName: _selectedImageName!,
              )
            : ["端末画像","タグなし"],*/
        //ここまで
    });

    setState(() {
      _isUploading = false;
      _imageFile = null;
      _selectedImageUrl = null;
      _selectedImageName = null;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
           InkWell(
            onTap: _pickImageFromFirebaseStorage,//(){},
            child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color.fromARGB(255, 114, 206, 137)),
                ),

                
                child: _imageFile != null ?
                Image.file(_imageFile!):
                _selectedImageUrl != null ?
                  Image.network(_selectedImageUrl!):
                const Center(child: Text('クリックして保存済み画像から選択'),)
             ),
          ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '説明文'),
            ),

            const SizedBox(height: 16),
            TagSelector(
              initialSuggestedTags:suggestedTags,
              onChanged: (tags) {
                setState(() {
                    _selectedTags = tags;
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadPost,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('投稿'),
            ),
          ],
        ),
      ),
    );
  }
}