
# `lib/services/local_storage.dart`

`local_storage.dart`は、タグ付けされた画像をデバイスのローカルストレージに永続化および取得するロジックを管理します。

## 主な機能

- **画像の保存:**
  - `saveTaggedImage`メソッドは、画像ファイルとそれに関連するタグのリストを受け取ります。
  - `getDownloadsDirectory`（Androidの場合）または`getApplicationDocumentsDirectory`（他のプラットフォームの場合）を使用して、画像を保存するための適切なディレクトリパスを取得します。
  - `shared_preferences`を使用して、各画像に関連付けられたタグをキーと値のペアとして保存します。

- **画像の取得:**
  - `getTaggedImages`メソッドは、保存されたタグ付き画像のリストを非同期に読み込みます。
  - `shared_preferences`からすべてのキーを取得し、画像のパスをフィルタリングして、各画像に関連付けられたタグを取得します。

- **UIモデル:**
  - `TaggedImage`クラスは、画像ファイルとそのタグをカプセル化するシンプルなデータモデルを提供し、UIコンポーネントでの使用を容易にします。
