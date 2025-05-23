import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user needs to set username
  bool needsUsername() {
    final user = currentUser;
    return user != null && (user.displayName == null || user.displayName!.isEmpty);
  }

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      // Create user document in Firestore
      await _createUserDocument(
        credential.user!.uid,
        email: credential.user!.email,
        displayName: credential.user!.displayName,
        photoURL: credential.user!.photoURL,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create user document if it doesn't exist
      await _createUserDocument(
        credential.user!.uid,
        email: credential.user!.email,
        displayName: credential.user!.displayName,
        photoURL: credential.user!.photoURL,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create user document
      await _createUserDocument(
        credential.user!.uid,
        email: credential.user!.email,
        displayName: credential.user!.displayName,
        photoURL: credential.user!.photoURL,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid, {
    String? email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final doc = await userDoc.get();
      
      if (!doc.exists) {
        await userDoc.set({
          'created_at': FieldValue.serverTimestamp(),
          'email': email,
          'username': displayName,
          'profile_picture_url': photoURL,
        });
      }
    } catch (e) {
      // If there's an error, try to create the document anyway
      await _firestore.collection('users').doc(uid).set({
        'created_at': FieldValue.serverTimestamp(),
        'email': email,
        'username': displayName,
        'profile_picture_url': photoURL,
      });
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'username': displayName,
        if (photoURL != null) 'profile_picture_url': photoURL,
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-credential':
        return 'The supplied credentials are invalid or expired.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
} 