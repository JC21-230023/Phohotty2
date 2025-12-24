
# `lib/pages/auth_page.dart`

`auth_page.dart`は、ユーザーの認証状態を管理し、サインインしているかどうかによって`HomePage`または`LoginPage`のいずれかを表示します。

## 主な機能

- **認証状態の監視:**
  - `StreamBuilder`を使用して、`AuthService().authStateChanges`ストリームを監視し、ユーザーの認証状態の変更をリアルタイムでリッスンします。

- **UIの分岐:**
  - 認証ストリームのスナップショットに基づいて、UIを動的に切り替えます。
    - `snapshot.hasData`が`true`の場合（ユーザーがサインインしている場合）、`HomePage`を表示します。
    - `snapshot.hasData`が`false`の場合（ユーザーがサインアウトしている場合）、`LoginPage`を表示します。

- **ローディングインジケーター:**
  - 接続が確立されるまで、またはデータが利用可能になるまで、`CircularProgressIndicator`を表示して、ユーザーに読み込み中であることを示します。
