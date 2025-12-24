
# `lib/main.dart`

`main.dart`は、Flutterアプリケーションのエントリーポイントです。

## 主な機能

- **アプリケーションの初期化:**
  - `WidgetsFlutterBinding.ensureInitialized()`を呼び出して、Flutterエンジンとウィジェットバインディングを初期化します。
  - `dotenv.load(fileName: '.env')`を使用して、`.env`ファイルから環境変数を読み込みます。

- **アプリケーションの実行:**
  - `runApp(const MyApp())`を呼び出して、アプリケーションのルートウィジェットである`MyApp`を起動します。

- **ルートウィジェット (`MyApp`):**
  - `StatelessWidget`として定義されています。
  - `MaterialApp`を返し、アプリケーションの基本的な構造とテーマを設定します。
  - `home`プロパティに`MainTabPage`を指定して、アプリケーションの初期画面を設定します。
  - `debugShowCheckedModeBanner`を`false`に設定して、デバッグバナーを非表示にします。
