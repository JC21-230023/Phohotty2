
# `lib/pages/map_page.dart`

`map_page.dart`は、Googleマップを表示し、デバイスの現在位置にカメラを移動する機能を提供します。

## 主な機能

- **マップの表示:**
  - `GoogleMap`ウィジェットを使用して、インタラクティブなマップを表示します。
  - `_onMapCreated`で`GoogleMapController`を初期化し、`_determinePosition`を呼び出して現在位置を取得します。

- **現在位置の取得:**
  - `_determinePosition`メソッドは、`geolocator`パッケージを使用して、デバイスのGPS位置情報を取得します。
  - `Geolocator.checkPermission`と`Geolocator.requestPermission`を使用して、位置情報へのアクセス許可を確認および要求します。

- **カメラの移動:**
  - 現在位置が取得されると、`_controller.animateCamera`を使用して、マップのカメラをデバイスの現在位置にスムーズに移動させます。
  - カメラのズームレベルは`14.0`に設定されます。
