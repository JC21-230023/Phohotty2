
# `lib/pages/gallery_page.dart`

`gallery_page.dart`は、ローカルに保存されたタグ付け済みの画像ギャラリーを表示します。

## 主な機能

- **ギャラリーの表示:**
  - `FutureBuilder`を使用して、`LocalStorageService`からタグ付けされた画像のリストを非同期に読み込みます。
  - 読み込んだ画像を`_buildGalleryGrid`でグリッド状に表示します。

- **UIの構築:**
  - `Scaffold`と`AppBar`を使用して、ページの基本的なレイアウトを構築します。
  - 「画像にタグ付け」ボタンを配置し、タップすると`/tag-lens`ルートに遷移して`TagLensPage`を表示します。
  - `_buildGalleryGrid`では、各画像にサムネイルと関連するタグを表示します。

- **グリッドタイル:**
  - `GridTile`を使用して、各画像をグリッドに配置します。
  - `GridTileBar`を使用して、画像の下部にタグを表示します。
  - 画像は`Image.file`を使用してファイルパスから読み込まれます。
