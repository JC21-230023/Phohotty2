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
  List<AssetPathEntity>? _paths;
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

  void _onScroll() {
    // Home page doesn't paginate by scroll yet. Placeholder for future use.
  }

  Future<void> _requestPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await PhotoManager.requestPermissionExtend();
      if (!res.isAuth) {
        setState(() {
          _error = 'ストレージのアクセス許可が必要です';
          _paths = [];
        });
        return;
      }

      final paths = await PhotoManager.getAssetPathList(onlyAll: false, type: RequestType.image);
      final allList = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
      final allPath = allList.isNotEmpty ? allList.first : null;
      if (!mounted) return;
      setState(() {
        _paths = paths;
        _allPath = allPath;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFullImage(AssetEntity asset) async {
    final bytes = await asset.originBytes;
    if (bytes == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('画像')),
        body: Center(child: Image.memory(bytes)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ギャラリー')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(fontSize: 16)))
          : _paths == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _paths!.length,
                  itemBuilder: (context, index) {
                    final path = _paths![index];
                    return FutureBuilder<List<AssetEntity>>(
                      future: path.getAssetListPaged(page: 0, size: 1),
                      builder: (context, snap) {
                        Widget leading = Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey[300],
                        );
                        if (snap.connectionState == ConnectionState.done &&
                            snap.data != null &&
                            snap.data!.isNotEmpty) {
                          leading = FutureBuilder<Uint8List?>(
                            future: snap.data!.first.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                            builder: (c2, s2) {
                              if (s2.connectionState == ConnectionState.done && s2.data != null) {
                                return Image.memory(s2.data!, width: 72, height: 72, fit: BoxFit.cover);
                              }
                              return Container(width: 72, height: 72, color: Colors.grey[300]);
                            },
                          );
                        }

                        return ListTile(
                          leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: leading),
                          title: Text(path.name),
                          subtitle: FutureBuilder<int?>(
                            future: path.assetCountAsync,
                            builder: (c, s) {
                              if (s.connectionState == ConnectionState.done && s.data != null) {
                                return Text('${s.data} 枚');
                              }
                              return const Text('読み込み中...');
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumPage(path: path)));
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  final AssetPathEntity path;
  const AlbumPage({required this.path, super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final List<AssetEntity> _assets = [];
  int _page = 0;
  final int _pageSize = 100;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final pageAssets = await widget.path.getAssetListPaged(page: _page, size: _pageSize);
      if (pageAssets.isEmpty) {
        _hasMore = false;
      } else {
        _assets.addAll(pageAssets);
        _assets.sort((a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime));
        _page++;
        if (pageAssets.length < _pageSize) _hasMore = false;
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _openFullImage(AssetEntity asset) async {
    final bytes = await asset.originBytes;
    if (bytes == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(widget.path.name)),
          body: Center(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  List<MapEntry<String, List<AssetEntity>>> _grouped() {
    final map = <String, List<AssetEntity>>{};
    for (final a in _assets) {
      final d = a.modifiedDateTime;
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(a);
    }
    final entries = map.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  String _formatHeader(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    final weekdays = ['月','火','水','木','金','土','日'];
    final wd = DateTime(y, m, d).weekday; // 1-7
    final wdStr = weekdays[(wd - 1) % 7];
    final now = DateTime.now();
    if (y != now.year) return '${y}年${m}月${d}日($wdStr)';
    return '${m}月${d}日($wdStr)';
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();

    return Scaffold(
      appBar: AppBar(title: Text(widget.path.name)),
      body: _assets.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: groups.length + (_hasMore && _isLoading ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx >= groups.length) return const Center(child: Padding(
                  padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()));
                final entry = groups[idx];
                final header = _formatHeader(entry.key);
                final items = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Text(header, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: items.length,
                      itemBuilder: (c, i) {
                        final asset = items[i];
                        return GestureDetector(
                          onTap: () => _openFullImage(asset),
                          child: FutureBuilder<Uint8List?>(
                            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                return Image.memory(snapshot.data!, fit: BoxFit.cover);
                              }
                              return Container(color: Colors.grey[300]);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}