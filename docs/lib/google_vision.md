
# `lib/services/google_vision.dart`

`google_vision.dart`は、Google Cloud Vision APIとの対話を担当し、画像からラベル（タグ）を抽出する機能を提供します。

## 主な機能

- **API認証:**
  - `_getAuthClient`メソッドを実装し、サービスアカウントの認証情報（`.env`ファイルから読み込まれる）を使用して、Google Cloudへの認証済みHTTPクライアントを作成します。

- **画像ラベリング:**
  - `tagImage`メソッドは、画像ファイルを受け取り、Google Cloud Vision APIに送信してラベル検出をリクエストします。
  - `build`メソッドで、APIリクエストのJSONボディを構築し、画像のバイトをBase64でエンコードして含めます。

- **レスポンスの処理:**
  - APIからのレスポンスを解析し、`labelAnnotations`からラベルの説明を抽出して、`List<String>`として返します。
  - エラーが発生した場合は、コンソールに出力し、空のリストを返します。
