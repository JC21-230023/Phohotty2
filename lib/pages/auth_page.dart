import 'package:flutter/material.dart';
import '../services/fb_auth.dart';
import 'user_create_page.dart';
import 'user_signin_page.dart';
import '../services/local_storage.dart';


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
							// エラーハンドリング
							if (snapshot.hasError) {
								debugPrint('Auth stream error: ${snapshot.error}');
								return Center(
									child: Text('認証エラーが発生しました: ${snapshot.error}'),
								);
							}

							if (snapshot.connectionState == ConnectionState.waiting) {
								return const CircularProgressIndicator();
							}

							final user = snapshot.data;
							if (user != null) {
								// displayName が空文字列の場合のクラッシュを防ぐ
								final displayInitial = (user.displayName?.isNotEmpty ?? false)
									? user.displayName!.substring(0, 1)
									: 'U';
								
								return Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										CircleAvatar(
											radius: 40,
											backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
												? NetworkImage(user.photoUrl!)
												: null,
											child: user.photoUrl == null || user.photoUrl!.isEmpty
													? Text(displayInitial)
													: null,
										),
										const SizedBox(height: 12),
										Text(user.displayName ?? '名無し', style: const TextStyle(fontSize: 18)),
										const SizedBox(height: 4),
										Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
										const SizedBox(height: 16),
										ElevatedButton.icon(
											onPressed: () async {
												try {
													await FbAuth.instance.signOut();
													// ローカルストレージもクリア
													await LocalStorageService().clearAll();
													// Ensure widget is still mounted after async operation
													if (context.mounted) {
														ScaffoldMessenger.of(context).showSnackBar(
															const SnackBar(content: Text('サインアウトしました')),
														);
													}
												} catch (e) {
													debugPrint('Sign out error: $e');
													if (context.mounted) {
														ScaffoldMessenger.of(context).showSnackBar(
															SnackBar(content: Text('サインアウトに失敗しました: $e')),
														);
													}
												}
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
													if (context.mounted) {
														ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインインがキャンセルされました')));
													}
												}
											} catch (e) {
												debugPrint('Sign in error: $e');
												if (context.mounted) {
													ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインインに失敗しました: $e')));
												}
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
									TextButton(
										onPressed: () {
											Navigator.of(context).push(
												MaterialPageRoute(builder: (_) => const UserSignInPage()),
											);
										},
										child: const Text('既存アカウントでサインイン'),
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

