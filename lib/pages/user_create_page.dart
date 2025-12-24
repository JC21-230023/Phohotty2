import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー作成')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
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
                    child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('作成'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
