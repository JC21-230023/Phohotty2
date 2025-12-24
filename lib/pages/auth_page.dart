import 'package:flutter/material.dart';
import '../services/fb_auth.dart';
import 'user_create_page.dart';

class AuthPage extends StatelessWidget {
	const AuthPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('認証')),
			body: SafeArea(
				child: Center(
					child: StreamBuilder<FbUser?>(
						stream: FbAuth.instance.authStateChanges,
						builder: (context, snapshot) {
							if (snapshot.connectionState == ConnectionState.waiting) {
								return const CircularProgressIndicator();
							}

							final user = snapshot.data;
							if (user != null) {
								return Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										CircleAvatar(
											radius: 40,
											backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
											child: user.photoUrl == null
													? Text((user.displayName ?? 'U').substring(0, 1))
													: null,
										),
										const SizedBox(height: 12),
										Text(user.displayName ?? '名無し', style: const TextStyle(fontSize: 18)),
										const SizedBox(height: 4),
										Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
										const SizedBox(height: 16),
										ElevatedButton.icon(
											onPressed: () async {
												await FbAuth.instance.signOut();
											},
											icon: const Icon(Icons.logout),
											label: const Text('サインアウト'),
										),
									],
								);
							}

							return Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									const Text('サインインしていません'),
									const SizedBox(height: 12),
									ElevatedButton.icon(
										onPressed: () async {
											try {
												final result = await FbAuth.instance.signInWithGoogle();
												if (result == null) {
													ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインインがキャンセルされました')));
												}
											} catch (e) {
												ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインインに失敗しました: $e')));
											}
										},
										icon: const Icon(Icons.login),
										label: const Text('Googleでサインイン'),
									),
									const SizedBox(height: 8),
									TextButton(
										onPressed: () {
											Navigator.of(context).push(
												MaterialPageRoute(builder: (_) => const UserCreatePage()),
											);
										},
										child: const Text('メールでユーザー作成'),
									),
								],
							);
						},
					),
				),
			),
		);
	}
}

