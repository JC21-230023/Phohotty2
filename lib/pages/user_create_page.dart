import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/fb_auth.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _loading = false;
  bool _platformLoading = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(_displayNameCtrl.text.trim());
        await user.reload();
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String msg = 'ユーザー作成に失敗しました';
      if (e.code == 'email-already-in-use') msg = 'そのメールアドレスは既に使用されています。';
      if (e.code == 'weak-password') msg = 'パスワードが短すぎます（6文字以上）。';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createWithGoogle() async {
    setState(() => _platformLoading = true);
    try {
      final user = await FbAuth.instance.signInWithGoogle();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google サインインがキャンセルされました')));
        return;
      }
      // Google でサインインすると Firebase 側にユーザーが作成されます。
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google サインイン失敗: $e')));
    } finally {
      if (mounted) setState(() => _platformLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー作成')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- メール作成フォーム ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _displayNameCtrl,
                        decoration: const InputDecoration(labelText: '表示名'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '表示名を入力してください' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'メールアドレス'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? '正しいメールアドレスを入力してください' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(labelText: 'パスワード'),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6) ? '6文字以上のパスワードを入力してください' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordConfirmCtrl,
                        decoration: const InputDecoration(labelText: 'パスワード（確認）'),
                        obscureText: true,
                        validator: (v) => (v != _passwordCtrl.text) ? 'パスワードが一致しません' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _createAccount,
                          child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('メールで作成'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // --- プラットフォーム作成（Google） ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    icon: Image.asset('assets/images/google_logo.png', height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login)),
                    label: _platformLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Google で作成 / サインイン'),
                    onPressed: _platformLoading ? null : _createWithGoogle,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Google アカウントで作成すると Firebase にユーザーが作成されます。'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
