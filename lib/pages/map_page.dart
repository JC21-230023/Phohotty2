
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phototty/services/post_fillter.dart';
import 'package:phototty/services/post_marker.dart';

import 'package:phototty/widgets/search_input_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  CameraPosition? _initialCameraPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // ログイン直後の画面遷移と重なると iOS でクラッシュすることがあるため、1フレーム遅延
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _setCurrentLocation();
        _loadPostMarkers();
      });
    });
  }
  void _showImageSelectionBottomSheet({
      required String docId, required String title,
       required String imageUrl, required String tagList}){
    showModalBottomSheet(context: context, builder:(BuildContext context) {
       return Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // 画像枠
              Container(
                height: 220, // ← 画像の高さ（好みで調整）
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black26, width: 1),
                  color: Colors.grey.shade100,
                ),
                clipBehavior: Clip.antiAlias, // 角丸を画像にも効かせる
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        // 読み込み中
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        // エラー時
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.black45),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.black45),
                      ),
              ),
              const SizedBox(height: 16),

              // tagList 枠
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black26, width: 1),
                  color: Colors.white,
                ),
                child: Text(
                  tagList,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _setCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setDefaultCamera();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
      });
    } catch (e) {
      debugPrint('MapPage _setCurrentLocation error: $e');
      _setDefaultCamera();
    }
  }

  void _setDefaultCamera() {
    if (!mounted) return;
    setState(() {
      _initialCameraPosition = const CameraPosition(
        target: LatLng(35.6762, 139.6503),
        zoom: 12,
      );
    });
  }

  Set<Marker> postMarker() => _markers;

  Future<void> _loadPostMarkers() async {
    try {
      final Set<Marker> tmp = await getPostMarkers(_showImageSelectionBottomSheet);
      if (!mounted) return;
      setState(() {
        _markers
          ..clear()
          ..addAll(tmp);
      });
    } catch (e) {
      debugPrint('MapPage _loadPostMarkers error: $e');
    }
  }

//====================
  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar:AppBar(title: const Text("画像MAP_SNS"),
        actions: [ 
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'reload',
              onPressed: _loadPostMarkers,
            ),
          ],
      ),
      body: Column(
        children: [ 
          SizedBox( height: 56, // 好みで 52〜64 あたり
            child: SearchInputBar(
              onSubmit:(query) {
                string2markers(query,_showImageSelectionBottomSheet).then((markers) {
                  setState(() {
                    _markers
                      ..clear()
                      ..addAll(markers);
                  });
                });
              },
            ),
          ),
         
          Expanded(
            child:GoogleMap(
              initialCameraPosition: _initialCameraPosition!,
              myLocationEnabled: true, // 青い現在地マーカー
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                mapController = controller;
              },
              markers: _markers,
            )
          ),
      ]
      )
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
