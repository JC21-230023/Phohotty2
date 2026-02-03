//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phototty/services/post_fillter.dart';
import 'package:phototty/services/post_marker.dart';
//import 'package:phototty/services/post_marker.dart';
import 'package:phototty/widgets/search_input_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  CameraPosition? _initialCameraPosition;
  //**追加****
    final Set<Marker> _markers = {};


  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
    _loadPostMarkers();
  }

  Future<void> _setCurrentLocation() async {
    // 権限チェック
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // 権限がない場合は東京を表示
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(35.6762, 139.6503),
          zoom: 12,
        );
      });
      return;
    }

    // 現在地取得
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
    });
  }
  //==========追加=======
    Set<Marker> postMarker() => _markers;
    //========
    
    Future<void> _loadPostMarkers() async {
      final Set<Marker> tmp = await getPostMarkers();
      setState(() {
        _markers
          ..clear()
          ..addAll(tmp);
      });
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
      appBar:AppBar(title: const Text("画像MAP_SNS!"),
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
                string2markers(query).then((markers) {
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
