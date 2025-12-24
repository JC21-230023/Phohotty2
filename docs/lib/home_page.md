
# `lib/pages/home_page.dart`

`home_page.dart`は、デバイスのフォトギャラリーからアルバムを取得して表示する役割を担います。

## 主な機能

- **権限のリクエストとアルバムの読み込み:**
  - `initState`で`_requestPermissionAndLoad`を呼び出し、`photo_manager`パッケージを使用してストレージへのアクセス許可を要求します。
  - 許可が得られると、`PhotoManager.getAssetPathList`を使用して、デバイスから画像アルバムのリストを取得します。

- **UIの構築:**
  - `Scaffold`と`AppBar`を使用して、ページの基本的なレイアウトを構築します。
  - `_buildBody`メソッドで、読み込み中、エラー、またはアルバムが空の場合に応じて異なるUIを表示します。
  - アルバムのリストを`ListView.builder`で表示し、各アルバムを`_buildAlbumTile`で構築します。

- **アルバムタイル (`_buildAlbumTile`):**
  - 各アルバムのタイルには、サムネイル、アルバム名、およびアセット数が表示されます。
  - サムネイルは`_buildThumbnail`で非同期に読み込まれます。
  - タイルをタップすると、`AlbumPage`に遷移し、選択したアルバムの詳細が表示されます。
