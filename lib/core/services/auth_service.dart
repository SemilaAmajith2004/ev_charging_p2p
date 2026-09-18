import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream per l'orientamento dello stato di autenticazione dell'utente
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utente attuale
  User? get currentUser => _auth.currentUser;

  // 1. Sign In via Email e Password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Sign Up via Email e Password
  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Aggiorna il nome del profilo Firebase Auth
      await userCredential.user?.updateDisplayName(name);

      // Salva i dettagli dell'utente nel Firestore Database
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': name,
          'email': email,
          'role': role, // 'driver' o 'host'
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Annullato dall'utente

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      await _saveUserToFirestore(userCredential.user);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Facebook Sign-In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      await _saveUserToFirestore(userCredential.user);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 5. Sign Out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }

  // Helper: Salva i dati utente nel Firestore se non esistono
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'role': 'driver', // Ruolo predefinito per il Social Auth
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
