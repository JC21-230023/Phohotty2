import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AssetEntity> _assets = [];
  AssetPathEntity? _allPath;
  int _page = 0;
  final int _pageSize = 100;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _requestPermissionAndLoad();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndLoad() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _error = 'ストレージアクセス権限が必要です');
      return;
    }

    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      if (paths.isEmpty) {
        setState(() => _error = '画像が見つかりませんでした');
        return;
      }
      _allPath = paths.first;
      await _loadMore();
    } catch (e) {
      setState(() => _error = '画像読み込みエラー: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _allPath == null) return;
    setState(() => _isLoading = true);

    try {
      final List<AssetEntity> pageAssets = await _allPath!.getAssetListPaged(
        page: _page,
        size: _pageSize,
      );

      if (pageAssets.isEmpty) {
        _hasMore = false;
      } else {
        _assets.addAll(pageAssets);
        _page++;
        if (pageAssets.length < _pageSize) _hasMore = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '読み込みエラー: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _openFullImage(AssetEntity asset) async {
    final bytes = await asset.originBytes;
    if (bytes == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('画像')),
          body: Center(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ギャラリー')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(fontSize: 16)))
          : _assets.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _assets.length + (_hasMore && _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _assets.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final asset = _assets[index];
                    return GestureDetector(
                      onTap: () => _openFullImage(asset),
                      child: FutureBuilder<Uint8List?>(
                        future: asset.thumbnailDataWithSize(
                          const ThumbnailSize(200, 200),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(color: Colors.grey[300]);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}