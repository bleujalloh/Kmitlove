import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Toute la logique d'authentification Firebase en un seul endroit.
/// Les écrans n'appellent jamais FirebaseAuth directement (docs/lib/README.md).
class AuthRepository {
  AuthRepository(this._auth, this._functions);

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Rafraîchit l'utilisateur courant pour savoir si l'e-mail vient d'être
  /// vérifié (Firebase ne met pas `emailVerified` à jour en temps réel).
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    // Nonce de sécurité recommandé par Apple/Firebase : lie la réponse
    // reçue à cette tentative précise de connexion, pour empêcher qu'un
    // jeton intercepté soit rejoué ailleurs.
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: hashedNonce,
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    return _auth.signInWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> signOut() => _auth.signOut();

  /// La suppression réelle (données applicatives ET compte Auth) est
  /// entièrement faite par la Cloud Function avec les droits admin —
  /// jamais depuis l'app, voir docs/regles-du-projet.md section 2. On ne
  /// rappelle jamais `_auth.currentUser?.delete()` ici : ça échouerait
  /// sans connexion récente, alors que les données seraient déjà effacées.
  Future<void> deleteAccount() async {
    await _functions.httpsCallable('deleteAccount').call();
    await _auth.signOut();
  }
}
