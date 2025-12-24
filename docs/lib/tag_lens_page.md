
# `lib/pages/tag_lens_page.dart`

`tag_lens_page.dart`は、ユーザーがカメラまたはギャラリーから画像を選択し、Google Cloud Vision APIを使用して画像に自動的にタグを付け、保存する機能を提供します。

## 主な機能

- **画像の選択:**
  - `_pickImage`メソッドを実装し、`image_picker`パッケージを使用して、ユーザーがカメラまたはギャラリーから画像を選択できるようにします。

- **画像のタグ付け:**
  - 選択した画像は`GoogleVisionService.tagImage`に送信され、Google Cloud Vision APIを介してラベル（タグ）のリストが返されます。

- **画像の保存:**
  - `LocalStorageService.saveTaggedImage`を呼び出して、タグ付けされた画像とそのタグをローカルストレージに永続化します。

- **UIの構築:**
  - `Scaffold`と`AppBar`を使用して、ページの基本的なレイアウトを構築します。
  - 選択した画像と、それに関連付けられたタグを`Wrap`ウィジェット内に表示します。
  - 画像が選択されていない場合は、画像を選択するためのボタン（`ElevatedButton`）と手順のテキストを表示します。
