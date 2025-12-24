
# `lib/pages/settings_page.dart`

`settings_page.dart`は、ユーザーがアプリケーションからサインアウトできるようにするための設定ページです。

## 主な機能

- **サインアウト機能:**
  - `AuthService`インスタンスを作成し、`signOut`メソッドを呼び出してユーザーをサインアウトさせます。
  - サインアウト処理は、`ElevatedButton`が押されたときにトリガーされます。

- **UIの構築:**
  - `Scaffold`と`AppBar`を使用して、ページの基本的なレイアウトを構築します。
  - `Center`ウィジェット内に`ElevatedButton`を配置し、「Sign Out」というラベルを表示します。
