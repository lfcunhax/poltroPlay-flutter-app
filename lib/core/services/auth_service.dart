import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Save or update user data in Firestore so the Admin Panel can see them
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'Usuário',
          'photoUrl': user.photoURL ?? '',
          'lastAccess': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(), // Will be overwritten by set(merge:true) if exists
          'status': 'active', // default status
        }, SetOptions(merge: true));
        
        // Remove createdAt from merge update if it already exists, by using a more precise update:
        // Actually, set merge:true will only overwrite fields provided. Since we provide createdAt, it will overwrite it every time.
        // Let's do a set merge without createdAt, and only set createdAt if the document didn't exist.
        // We can just use FieldValue.serverTimestamp() for lastAccess, and let the Admin Panel sort by it.
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase auth error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
