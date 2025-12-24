
# `lib/services/fb_auth.dart`

`fb_auth.dart`は、Firebase Authenticationを使用したユーザー認証のロジックをカプセル化し、サインイン、サインアウト、および認証状態の監視の機能を提供します。

## 主な機能

- **Firebase Authenticationインスタンス:**
  - `FirebaseAuth.instance`への参照を保持し、認証操作を実行するために使用します。

- **認証状態のストリーム:**
  - `authStateChanges`ストリームを公開し、ユーザーの認証状態（サインインまたはサインアウト）の変更をリッスンできるようにします。

- **サインイン:**
  - `signInWithGoogle`メソッドを実装し、`google_sign_in`パッケージを使用してGoogleアカウントでのサインインフローを処理します。
  - 取得したGoogle認証情報を使用して`signInWithCredential`を呼び出し、Firebaseにサインインします。

- **サインアウト:**
  - `signOut`メソッドを提供し、`FirebaseAuth.instance.signOut()`を呼び出して、ユーザーをアプリケーションからサインアウトさせます。
