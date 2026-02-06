import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FbUser {
	final String uid;
	final String? displayName;
	final String? email;
	final String? photoUrl;
	final List<String> providers;

	FbUser({
		required this.uid,
		this.displayName,
		this.email,
		this.photoUrl,
		this.providers = const [],
	});

	factory FbUser.fromFirebaseUser(User user) {
		return FbUser(
			uid: user.uid,
			displayName: user.displayName,
			email: user.email,
			photoUrl: user.photoURL,
			providers: user.providerData.map((p) => p.providerId).toList(),
		);
	}
}

class FbAuth {
	FbAuth._();
	static final FbAuth instance = FbAuth._();

	final FirebaseAuth _auth = FirebaseAuth.instance;
	final GoogleSignIn _googleSignIn = GoogleSignIn();

	Stream<FbUser?> get authStateChanges =>
			_auth.authStateChanges().map((u) {
		try {
			if (u == null) return null;
			return FbUser.fromFirebaseUser(u);
		} catch (e) {
			debugPrint('Error converting Firebase User to FbUser: $e');
			rethrow;
		}
	});

	FbUser? get currentUser =>
			_auth.currentUser == null ? null : FbUser.fromFirebaseUser(_auth.currentUser!);

	Future<FbUser?> signInWithGoogle() async {
		try {
			final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
			if (googleUser == null) {
				debugPrint('Google Sign In was cancelled by user');
				return null; // ユーザーがサインインをキャンセル
			}

			try {
				final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
				
				if (googleAuth.accessToken == null || googleAuth.idToken == null) {
					debugPrint('Google authentication tokens are null');
					return null;
				}

				final credential = GoogleAuthProvider.credential(
					accessToken: googleAuth.accessToken,
					idToken: googleAuth.idToken,
				);

				final UserCredential userCredential = await _auth.signInWithCredential(credential);
				final user = userCredential.user;
				if (user == null) {
					debugPrint('Firebase user is null after sign in');
					return null;
				}
				return FbUser.fromFirebaseUser(user);
			} catch (authError) {
				debugPrint('Google authentication error: $authError');
				rethrow;
			}
		} catch (e) {
			debugPrint('Google Sign In error: $e');
			rethrow;
		}
	}

	Future<void> signOut() async {
		await _auth.signOut();
		try {
			await _googleSignIn.signOut();
		} catch (_) {}
	}
}

